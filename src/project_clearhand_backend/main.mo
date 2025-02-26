import TransactionLedger "TransactionLedger";
import CitizenReporting "CitizenReporting";
import RewardToken "RewardToken";
import StakingContract "StakingContract";
import ReserveContract "ReserveContract";
import StabilizationContract "StabilizationContract";
import RewardSystem "RewardSystem";
import MilestoneFunding "MilestoneFunding";
import AuditSystem "AuditSystem";
import VotingSystem "VotingSystem";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Debug "mo:base/Debug";
import ICRC "mo:icrc1:aaaaa-aa";
import AccountIdentifier "mo:icrc1:aaaaa-aa/icrc/account_identifier";

actor Main {
    public func exampleUsage() : async () {
        let userPrincipal1 = Principal.fromText("user1_principal_here").unwrap();
        let userPrincipal2 = Principal.fromText("user2_principal_here").unwrap();
        let systemPrincipal = Principal.fromText("SYSTEM_PRINCIPAL_HERE").unwrap();
        let projectPrincipal = Principal.fromText("PROJECT_PRINCIPAL_HERE").unwrap();

        // Menambahkan proyek baru
        let addProjectResult = await MilestoneFunding.addProject(
            "Proyek Jalan Tol",
            12_000_000_000_000, // 12T dalam IDR
            [
                (30, "Verifikasi Dokumen"),
                (30, "Progres Fisik 50%"),
                (40, "Penyelesaian dan Audit")
            ]
        );
        switch (addProjectResult) {
            case (#Ok(projectId)) {
                Debug.print(debug_show("Project added with ID: " # debug_show(projectId)));
            };
            case (#Err(err)) {
                Debug.print("Failed to add project: " # err);
            };
        };

        // Menyetujui proyek setelah seleksi awal
        let approveProjectResult = await MilestoneFunding.approveProject(0);
        switch (approveProjectResult) {
            case (#Ok(projectId)) {
                Debug.print(debug_show("Project approved with ID: " # debug_show(projectId)));
            };
            case (#Err(err)) {
                Debug.print("Failed to approve project: " # err);
            };
        };

        // Menambahkan transaksi keuangan untuk milestone 1
        await TransactionLedger.addTransaction(systemPrincipal, projectPrincipal, 3_600_000_000_000, "Milestone 1 Proyek Jalan Tol");

        // Mendapatkan total volume transaksi
        let totalVolume = await TransactionLedger.getTotalVolume();
        Debug.print(debug_show(totalVolume)); // Output: 3_600_000_000_000

        // Melepaskan dana untuk Milestone 1 Proyek Jalan Tol
        let releaseFundsResult1 = await MilestoneFunding.releaseFunds(0, 0, "https://example.com/evidence1.pdf");
        switch (releaseFundsResult1) {
            case (#Ok(tokenAmount)) {
                Debug.print(debug_show("Milestone 1 Proyek Jalan Tol released: " # debug_show(tokenAmount) # " tokens"));
            };
            case (#Err(err)) {
                Debug.print("Milestone 1 Proyek Jalan Tol failed: " # err);
            };
        };

        // Menambahkan laporan warga
        let addReportResult1 = await MilestoneFunding.addReport(0, userPrincipal1, "Potensi penyalahgunaan dana pada Proyek Jalan Tol");
        switch (addReportResult1) {
            case (#Ok(reportId)) {
                Debug.print(debug_show("Report added with ID: " # debug_show(reportId)));
            };
            case (#Err(err)) {
                Debug.print("Failed to add report: " # err);
            };
        };

        // Mendapatkan semua laporan proyek
        let projectReports1 = await MilestoneFunding.getProjectReports(0);
        switch (projectReports1) {
            case (#Ok(reports)) {
                Debug.print(debug_show("Project Reports: " # debug_show(reports)));
            };
            case (#Err(err)) {
                Debug.print("Failed to get project reports: " # err);
            };
        };

        // Verifikasi laporan
        let verifyReportResult1 = await MilestoneFunding.verifyReport(0);
        switch (verifyReportResult1) {
            case (#Ok(reportId)) {
                Debug.print(debug_show("Report verified with ID: " # debug_show(reportId)));
            };
            case (#Err(err)) {
                Debug.print("Failed to verify report: " # err);
            };
        };

        // Menambahkan transaksi keuangan untuk milestone 2
        await TransactionLedger.addTransaction(systemPrincipal, projectPrincipal, 3_600_000_000_000, "Milestone 2 Proyek Jalan Tol");

        // Melepaskan dana untuk Milestone 2 Proyek Jalan Tol
        let releaseFundsResult2 = await MilestoneFunding.releaseFunds(0, 1, "https://example.com/evidence2.pdf");
        switch (releaseFundsResult2) {
            case (#Ok(tokenAmount)) {
                Debug.print(debug_show("Milestone 2 Proyek Jalan Tol released: " # debug_show(tokenAmount) # " tokens"));
            };
            case (#Err(err)) {
                Debug.print("Milestone 2 Proyek Jalan Tol failed: " # err);
            };
        };

        // Menambahkan transaksi keuangan untuk milestone 3
        await TransactionLedger.addTransaction(systemPrincipal, projectPrincipal, 4_800_000_000_000, "Milestone 3 Proyek Jalan Tol");

        // Melepaskan dana untuk Milestone 3 Proyek Jalan Tol (gagal karena ada laporan valid)
        let releaseFundsResult3 = await MilestoneFunding.releaseFunds(0, 2, "https://example.com/evidence3.pdf");
        switch (releaseFundsResult3) {
            case (#Ok(tokenAmount)) {
                Debug.print(debug_show("Milestone 3 Proyek Jalan Tol released: " # debug_show(tokenAmount) # " tokens"));
            };
            case (#Err(err)) {
                Debug.print("Milestone 3 Proyek Jalan Tol failed: " # err);
            };
        };

        // Menambahkan laporan warga lagi
        let addReportResult2 = await MilestoneFunding.addReport(0, userPrincipal2, "Potensi penyalahgunaan dana pada Proyek Jalan Tol");
        switch (addReportResult2) {
            case (#Ok(reportId)) {
                Debug.print(debug_show("Report added with ID: " # debug_show(reportId)));
            };
            case (#Err(err)) {
                Debug.print("Failed to add report: " # err);
            };
        };

        // Verifikasi laporan lagi
        let verifyReportResult2 = await MilestoneFunding.verifyReport(1);
        switch (verifyReportResult2) {
            case (#Ok(reportId)) {
                Debug.print(debug_show("Report verified with ID: " # debug_show(reportId)));
            };
            case (#Err(err)) {
                Debug.print("Failed to verify report: " # err);
            };
        };

        // Menambahkan laporan warga lagi
        let addReportResult3 = await MilestoneFunding.addReport(0, userPrincipal1, "Potensi penyalahgunaan dana pada Proyek Jalan Tol");
        switch (addReportResult3) {
            case (#Ok(reportId)) {
                Debug.print(debug_show("Report added with ID: " # debug_show(reportId)));
            };
            case (#Err(err)) {
                Debug.print("Failed to add report: " # err);
            };
        };

        // Verifikasi laporan lagi
        let verifyReportResult3 = await MilestoneFunding.verifyReport(2);
        switch (verifyReportResult3) {
            case (#Ok(reportId)) {
                Debug.print(debug_show("Report verified with ID: " # debug_show(reportId)));
            };
            case (#Err(err)) {
                Debug.print("Failed to verify report: " # err);
            };
        };

        // Menambahkan laporan warga lagi
        let addReportResult4 = await MilestoneFunding.addReport(0, userPrincipal2, "Potensi penyalahgunaan dana pada Proyek Jalan Tol");
        switch (addReportResult4) {
            case (#Ok(reportId)) {
                Debug.print(debug_show("Report added with ID: " # debug_show(reportId)));
            };
            case (#Err(err)) {
                Debug.print("Failed to add report: " # err);
            };
        };

        // Verifikasi laporan lagi
        let verifyReportResult4 = await MilestoneFunding.verifyReport(3);
        switch (verifyReportResult4) {
            case (#Ok(reportId)) {
                Debug.print(debug_show("Report verified with ID: " # debug_show(reportId)));
            };
            case (#Err(err)) {
                Debug.print("Failed to verify report: " # err);
            };
        };

        // Mendapatkan semua laporan proyek
        let projectReports2 = await MilestoneFunding.getProjectReports(0);
        switch (projectReports2) {
            case (#Ok(reports)) {
                Debug.print(debug_show("Project Reports: " # debug_show(reports)));
            };
            case (#Err(err)) {
                Debug.print("Failed to get project reports: " # err);
            };
        };

        // Melepaskan dana untuk Milestone 3 Proyek Jalan Tol (gagal karena ada laporan valid)
        let releaseFundsResult3Final = await MilestoneFunding.releaseFunds(0, 2, "https://example.com/evidence3_final.pdf");
        switch (releaseFundsResult3Final) {
            case (#Ok(tokenAmount)) {
                Debug.print(debug_show("Milestone 3 Proyek Jalan Tol released: " # debug_show(tokenAmount) # " tokens"));
            };
            case (#Err(err)) {
                Debug.print("Milestone 3 Proyek Jalan Tol failed: " # err);
            };
        };

        // Simulasi gagal 4 kali
        let simulateFailedAttempts : async () = {
            for (i in 0..3) {
                let releaseFundsResultFailed = await MilestoneFunding.releaseFunds(0, 2, "https://example.com/evidence3_failed_" # debug_show(i) # ".pdf");
                switch (releaseFundsResultFailed) {
                    case (#Ok(tokenAmount)) {
                        Debug.print(debug_show("Milestone 3 Proyek Jalan Tol released: " # debug_show(tokenAmount) # " tokens"));
                    };
                    case (#Err(err)) {
                        Debug.print("Milestone 3 Proyek Jalan Tol failed: " # err);
                    };
                };
            };
        };

        await simulateFailedAttempts();

        // Melepaskan dana untuk Milestone 3 Proyek Jalan Tol (gagal karena sudah gagal 4 kali)
        let releaseFundsResult3Final2 = await MilestoneFunding.releaseFunds(0, 2, "https://example.com/evidence3_final2.pdf");
        switch (releaseFundsResult3Final2) {
            case (#Ok(tokenAmount)) {
                Debug.print(debug_show("Milestone 3 Proyek Jalan Tol released: " # debug_show(tokenAmount) # " tokens"));
            };
            case (#Err(err)) {
                Debug.print("Milestone 3 Proyek Jalan Tol failed: " # err);
            };
        };

        // Mendapatkan detail proyek setelah semua milestone dicairkan
        let projectDetails1Final = await MilestoneFunding.getProjectDetails(0);
        switch (projectDetails1Final) {
            case (#Ok(project)) {
                Debug.print(debug_show("Project Details Final: " # debug_show(project)));
            };
            case (#Err(err)) {
                Debug.print("Failed to get project details: " # err);
            };
        };
    };
};