import Array "mo:base/Array";
import Principal "mo:base/Principal";
import Nat "mo:base/Nat";
import Blob "mo:base/Blob";
import Text "mo:base/Text";
import Error "mo:base/Error";
import Result "mo:base/Result";
import Time "mo:base/Time";
import ICRC "mo:icrc1:aaaaa-aa";
import AccountIdentifier "mo:icrc1:aaaaa-aa/icrc/account_identifier";
import RewardToken "RewardToken";
import AuditSystem "AuditSystem";

actor RewardSystem {
    type AuditRecord = {
        auditor : Principal;
        transactionId : Nat;
        timestamp : Nat;
        isValid : Bool;
        claimed : Bool;
    };

    var auditRecords : [AuditRecord] = [];
    var auditLimits : [(Principal, Nat)] = []; // (Principal, count)

    // Fungsi untuk menambahkan pengguna baru
    public func addUser(principal : Principal) : async () {
        let userOpt = Array.find(RewardToken.balances, func(b) { b._1 == principal });
        switch (userOpt) {
            case (null) {
                await RewardToken.addToBalance(principal, 0);
                auditLimits := Array.append(auditLimits, [(principal, 0)]);
            };
            case (?) {};
        };
    };

    // Fungsi untuk memberikan reward token virtual
    public func giveReward(principal : Principal, amount : Nat) : async () {
        await RewardToken.mintTokens(principal, amount);
    };

    // Fungsi untuk mendapatkan saldo pengguna
    public query func getBalance(principal : Principal) : async Nat {
        return await RewardToken.getBalance(principal);
    };

    // Fungsi untuk mentransfer token dari sistem ke pengguna
    public func transferTokens(principal : Principal, amount : Nat) : async Result.Result<Nat, Text> {
        return await RewardToken.transfer(
            Principal.fromText("SYSTEM_PRINCIPAL_HERE").unwrap(),
            principal,
            amount,
            ?0, // Fee
            null // Memo
        );
    };

    // Fungsi untuk melakukan audit anonim
    public func anonymousAudit(transactionId : Nat) : async () {
        let auditStatus = await AuditSystem.getAuditStatus(transactionId);
        if (auditStatus != "not audited") {
            throw ("Transaction has already been audited");
        };

        let auditor = msg.caller();
        let auditCountOpt = Array.find(auditLimits, func(al) { al._1 == auditor });
        let auditCount = switch (auditCountOpt) {
            case (?count) { count._2 };
            case (null) { 0 };
        };

        if (auditCount >= 2) {
            throw ("You have reached the maximum number of audits per month (2)");
        };

        // Simulasi logika audit sederhana
        let isCompliant = true; // Ganti dengan logika audit sebenarnya

        let newAuditRecord = {
            auditor = auditor;
            transactionId = transactionId;
            timestamp = Time.now();
            isValid = isCompliant;
            claimed = false;
        };
        auditRecords := Array.append(auditRecords, [newAuditRecord]);

        // Update audit count
        if (auditCountOpt.isSome()) {
            auditLimits := Array.map(auditLimits, func(al) {
                if (al._1 == auditor) {
                    return (auditor, al._2 + 1);
                } else {
                    return al;
                }
            });
        } else {
            auditLimits := Array.append(auditLimits, [(auditor, 1)]);
        };
    };

    // Fungsi untuk mendapatkan semua rekaman audit
    public query func getAuditRecords() : async [AuditRecord] {
        return auditRecords;
    };

    // Fungsi untuk mengklaim imbalan token untuk audit yang valid
    public func claimAuditReward(transactionId : Nat) : async () {
        let auditRecordOpt = Array.find(auditRecords, func(ar) { ar.transactionId == transactionId && ar.isValid && !ar.claimed });
        switch (auditRecordOpt) {
            case (?auditRecord) {
                let auditor = auditRecord.auditor;
                let rewardAmount : Nat = 100; // Imbalan token untuk audit valid (misalnya, 100 ECT)
                await RewardToken.mintTokens(auditor, rewardAmount);

                // Update status claimed
                auditRecords := Array.map(auditRecords, func(ar) {
                    if (ar.transactionId == transactionId) {
                        return { auditor = ar.auditor; transactionId = ar.transactionId; timestamp = ar.timestamp; isValid = ar.isValid; claimed = true };
                    } else {
                        return ar;
                    }
                });
            };
            case (null) {
                throw ("Audit record not found or already claimed");
            };
        };
    };

    // Fungsi untuk reset limit audit bulanan (untuk keperluan administrasi)
    public func resetMonthlyAuditLimit() : async () {
        await RewardToken.onlyOwner(async () => {
            auditLimits := Array.map(auditLimits, func(al) {
                return (al._1, 0);
            });
        });
    };

    // Fungsi untuk pertukaran token ke uang rupiah melalui Transfer Fund (TF)
    public func swapTokensForIDR(principal : Principal, tokenAmount : Nat, bankAccount : Text) : async Result.Result<Nat, Text> {
        let balanceOpt = await RewardToken.getBalance(principal);
        switch (balanceOpt) {
            case (?balance) {
                if (balance < tokenAmount) {
                    return Result.Err("Insufficient balance");
                };
                await RewardToken.subtractFromBalance(principal, tokenAmount);

                // Konversi token ke IDR
                let idrAmount = tokenAmount * 1_200_000; // Misalnya, 1 ECT = 1.200.000 IDR

                // Simulasi transfer ke rekening bank lokal
                // Di sini kita hanya mencatat transfer, namun dalam implementasi nyata, Anda perlu mengintegrasikan dengan sistem transfer ke bank
                let transferResult = await transferToBank(principal, idrAmount, bankAccount);
                switch (transferResult) {
                    case (#Ok(txId)) {
                        return Result.Ok(txId);
                    };
                    case (#Err(err)) {
                        return Result.Err(err);
                    };
                };
            };
            case (null) {
                return Result.Err("User not found");
            };
        };
    };

    // Fungsi simulasi untuk transfer ke bank lokal
    func transferToBank(principal : Principal, amount : Nat, bankAccount : Text) : async Result.Result<Nat, Text> {
        // Simulasi transfer ke bank lokal
        // Dalam implementasi nyata, Anda perlu mengintegrasikan dengan sistem transfer ke bank
        // Misalnya, menggunakan API dari bank atau layanan transfer seperti Xfers, TransferWise, dll.

        // Contoh: Simulasi sukses transfer
        let txId : Nat = Array.size(auditRecords); // Simulasi ID transaksi
        Debug.print(debug_show("Transfer successful: " # debug_show(amount) # " IDR to " # bankAccount));
        return Result.Ok(txId);
    };
};