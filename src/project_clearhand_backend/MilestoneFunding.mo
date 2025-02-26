import Array "mo:base/Array";
import Nat "mo:base/Nat";
import Time "mo:base/Time";
import Result "mo:base/Result";
import RewardToken "RewardToken";
import Principal "mo:base/Principal";
import CitizenReporting "CitizenReporting";
import AuditSystem "AuditSystem";
import ICRC "mo:icrc1:aaaaa-aa";
import AccountIdentifier "mo:icrc1:aaaaa-aa/icrc/account_identifier";

actor MilestoneFunding {
    type Project = {
        id : Nat;
        name : Text;
        totalFunds : Nat;
        milestones : [(Nat, Text)]; // (percentage, description)
        fundsReleased : Nat;
        status : Text; // "pending", "approved", "milestone1", "milestone2", "completed", "cancelled"
        evidence : [(Nat, Text)]; // (milestoneIndex, evidenceUrl)
        reports : [(Nat, Bool)]; // (reportId, isValid)
        failedAttempts : Nat; // Jumlah percobaan gagal untuk milestone terakhir
    };

    type Report = {
        id : Nat;
        reporter : Principal;
        projectId : Nat;
        description : Text;
        timestamp : Nat;
        status : Text; // "pending", "verified", "rejected"
    };

    var projects : [Project] = [];
    var reports : [Report] = [];

    // Fungsi untuk menambahkan proyek baru
    public func addProject(name : Text, totalFunds : Nat, milestones : [(Nat, Text)]) : async Result.Result<Nat, Text> {
        let newProject = {
            id = Array.size(projects);
            name = name;
            totalFunds = totalFunds;
            milestones = milestones;
            fundsReleased = 0;
            status = "pending";
            evidence = [];
            reports = [];
            failedAttempts = 0;
        };
        projects := Array.append(projects, [newProject]);
        return Result.Ok(newProject.id);
    };

    // Fungsi untuk menyetujui proyek setelah seleksi awal
    public func approveProject(projectId : Nat) : async Result.Result<Nat, Text> {
        if (projectId >= Array.size(projects)) {
            return Result.Err("Project not found");
        };
        let project = projects[projectId];
        if (project.status != "pending") {
            return Result.Err("Project is not pending approval");
        };

        // Memberikan token sebesar 30% dari total dana yang diajukan
        let tokenAmount = (project.totalFunds / 1_200_000) * 30; // Konversi dari IDR ke token (1 ECT = 1.200.000 IDR)
        await RewardToken.mintTokens(Principal.fromText("PROJECT_PRINCIPAL_HERE").unwrap(), tokenAmount);

        // Update status proyek
        projects := Array.map(projects, func(p) {
            if (p.id == projectId) {
                return { id = p.id; name = p.name; totalFunds = p.totalFunds; milestones = p.milestones; fundsReleased = p.fundsReleased; status = "approved"; evidence = p.evidence; reports = p.reports; failedAttempts = p.failedAttempts };
            } else {
                return p;
            }
        });

        return Result.Ok(projectId);
    };

    // Fungsi untuk melepaskan dana berdasarkan milestone
    public func releaseFunds(projectId : Nat, milestoneIndex : Nat, evidenceUrl : Text) : async Result.Result<Nat, Text> {
        if (projectId >= Array.size(projects)) {
            return Result.Err("Project not found");
        };
        let project = projects[projectId];
        if (milestoneIndex >= Array.size(project.milestones)) {
            return Result.Err("Milestone not found");
        };
        let milestone = project.milestones[milestoneIndex];

        // Verifikasi status proyek
        if (milestoneIndex == 0 && project.status != "approved") {
            return Result.Err("Project is not approved for milestone 1");
        } else if (milestoneIndex == 1 && project.status != "milestone1") {
            return Result.Err("Project is not approved for milestone 2");
        } else if (milestoneIndex == 2 && project.status != "milestone2") {
            return Result.Err("Project is not approved for milestone 3");
        };

        // Verifikasi bukti
        let evidenceOpt = Array.find(project.evidence, func(e) { e._1 == milestoneIndex });
        if (evidenceOpt.isSome()) {
            return Result.Err("Evidence for this milestone has already been submitted");
        };

        // Simpan bukti
        let updatedEvidence = Array.append(project.evidence, [(milestoneIndex, evidenceUrl)]);
        projects := Array.map(projects, func(p) {
            if (p.id == projectId) {
                return { id = p.id; name = p.name; totalFunds = p.totalFunds; milestones = p.milestones; fundsReleased = p.fundsReleased; status = p.status; evidence = updatedEvidence; reports = p.reports; failedAttempts = p.failedAttempts };
            } else {
                return p;
            }
        });

        // Verifikasi laporan valid dari masyarakat
        let validReports = Array.filter(project.reports, func(r) { r._2 });
        if (milestoneIndex == 2 && Array.size(validReports) > 0) {
            return Result.Err("Project has valid reports from citizens, resubmit valid evidence for milestone 3");
        };

        // Hitung jumlah dana yang akan dicairkan
        let fundsToRelease = (milestone.0 * project.totalFunds) / 100;

        // Verifikasi pencapaian milestone (misalnya, melalui dokumen)
        // Implementasi verifikasi otomatis di sini
        let isVerified = true; // Ganti dengan logika verifikasi sebenarnya

        if (!isVerified) {
            // Update jumlah percobaan gagal
            let updatedFailedAttempts = if (milestoneIndex == 2) { project.failedAttempts + 1 } else { project.failedAttempts };
            if (updatedFailedAttempts >= 4) {
                // Jika gagal 4 kali, hentikan proyek dan kembalikan sisa dana
                let remainingFunds = project.totalFunds - project.fundsReleased;
                await refundFunds(projectId, remainingFunds);
                return Result.Err("Project cancelled due to too many failed attempts");
            };

            // Update status proyek
            projects := Array.map(projects, func(p) {
                if (p.id == projectId) {
                    return { id = p.id; name = p.name; totalFunds = p.totalFunds; milestones = p.milestones; fundsReleased = p.fundsReleased; status = p.status; evidence = updatedEvidence; reports = p.reports; failedAttempts = updatedFailedAttempts };
                } else {
                    return p;
                }
            });

            return Result.Err("Milestone not verified");
        };

        // Update status proyek
        let newStatus = switch (milestoneIndex) {
            case (0) { "milestone1" };
            case (1) { "milestone2" };
            case (2) { "completed" };
            case (_) { "completed" };
        };
        projects := Array.map(projects, func(p) {
            if (p.id == projectId) {
                return { id = p.id; name = p.name; totalFunds = p.totalFunds; milestones = p.milestones; fundsReleased = p.fundsReleased + fundsToRelease; status = newStatus; evidence = updatedEvidence; reports = p.reports; failedAttempts = 0 };
            } else {
                return p;
            }
        });

        // Mint token sesuai dengan jumlah dana yang dicairkan
        let tokenAmount = fundsToRelease / 1_200_000; // Konversi dari rupiah ke token (1 ECT = 1.200.000 IDR)
        await RewardToken.mintTokens(Principal.fromText("PROJECT_PRINCIPAL_HERE").unwrap(), tokenAmount);

        return Result.Ok(tokenAmount);
    };

    // Fungsi untuk menambahkan laporan warga
    public func addReport(projectId : Nat, reporter : Principal, description : Text) : async Result.Result<Nat, Text> {
        if (projectId >= Array.size(projects)) {
            return Result.Err("Project not found");
        };

        let newReport = {
            id = Array.size(reports);
            reporter = reporter;
            projectId = projectId;
            description = description;
            timestamp = Time.now();
            status = "pending";
        };
        reports := Array.append(reports, [newReport]);

        // Tambahkan laporan ke proyek
        let updatedReports = Array.append(projects[projectId].reports, [(newReport.id, false)]);
        projects := Array.map(projects, func(p) {
            if (p.id == projectId) {
                return { id = p.id; name = p.name; totalFunds = p.totalFunds; milestones = p.milestones; fundsReleased = p.fundsReleased; status = p.status; evidence = p.evidence; reports = updatedReports; failedAttempts = p.failedAttempts };
            } else {
                return p;
            }
        });

        return Result.Ok(newReport.id);
    };

    // Fungsi untuk memverifikasi laporan
    public func verifyReport(reportId : Nat) : async Result.Result<Nat, Text> {
        let reportOpt = Array.find(reports, func(r) { r.id == reportId });
        switch (reportOpt) {
            case (?report) {
                let projectId = report.projectId;

                // Verifikasi laporan
                let isVerified = true; // Ganti dengan logika verifikasi sebenarnya
                if (!isVerified) {
                    return Result.Err("Report not verified");
                };

                // Update status laporan
                reports := Array.map(reports, func(r) {
                    if (r.id == reportId) {
                        return { id = r.id; reporter = r.reporter; projectId = r.projectId; description = r.description; timestamp = r.timestamp; status = "verified" };
                    } else {
                        return r;
                    }
                });

                // Tambahkan status verifikasi ke proyek
                let updatedReports = Array.map(projects[projectId].reports, func(rep) {
                    if (rep._1 == reportId) {
                        return (rep._1, true);
                    } else {
                        return rep;
                    }
                });
                projects := Array.map(projects, func(p) {
                    if (p.id == projectId) {
                        return { id = p.id; name = p.name; totalFunds = p.totalFunds; milestones = p.milestones; fundsReleased = p.fundsReleased; status = p.status; evidence = p.evidence; reports = updatedReports; failedAttempts = p.failedAttempts };
                    } else {
                        return p;
                    }
                });

                return Result.Ok(reportId);
            };
            case (null) {
                return Result.Err("Report not found");
            };
        };
    };

    // Fungsi untuk mendapatkan detail proyek
    public query func getProjectDetails(projectId : Nat) : async Result.Result<Project, Text> {
        if (projectId >= Array.size(projects)) {
            return Result.Err("Project not found");
        };
        return Result.Ok(projects[projectId]);
    };

    // Fungsi untuk mendapatkan semua proyek
    public query func getAllProjects() : async [Project] {
        return projects;
    };

    // Fungsi untuk mendapatkan semua laporan proyek
    public query func getProjectReports(projectId : Nat) : async Result.Result<[Report], Text> {
        if (projectId >= Array.size(projects)) {
            return Result.Err("Project not found");
        };
        let projectReports = Array.filter(reports, func(r) { r.projectId == projectId });
        return Result.Ok(projectReports);
    };

    // Fungsi untuk mengembalikan dana kesumbernya jika proyek dibatalkan
    private func refundFunds(projectId : Nat, amount : Nat) : async () {
        let project = projects[projectId];
        let systemPrincipal = Principal.fromText("SYSTEM_PRINCIPAL_HERE").unwrap();

        // Transfer dana kembali ke sistem
        let transferResult = await ICRC.transfer({
            to = AccountIdentifier.fromPrincipal(systemPrincipal);
            fee = ?{ e8s = 10_000 }; // Biaya transfer ICP (10_000 e8s = 0.00001 ICP)
            memo = ?0;
            amount = { e8s = amount };
            from_subaccount = null;
            created_at_time = null;
        });
        switch (transferResult) {
            case (#Ok) {
                // Transfer berhasil
                Debug.print(debug_show("Refund successful: " # debug_show(amount) # " IDR to " # debug_show(systemPrincipal)));
            };
            case (#Err(err)) {
                // Handle error transfer
                throw ("Refund failed: " # err);
            };
        };

        // Update status proyek menjadi cancelled
        projects := Array.map(projects, func(p) {
            if (p.id == projectId) {
                return { id = p.id; name = p.name; totalFunds = p.totalFunds; milestones = p.milestones; fundsReleased = p.fundsReleased; status = "cancelled"; evidence = p.evidence; reports = p.reports; failedAttempts = p.failedAttempts };
            } else {
                return p;
            }
        });
    };
};