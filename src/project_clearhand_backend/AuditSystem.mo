import Array "mo:base/Array";
import Nat "mo:base/Nat";
import Time "mo:base/Time";
import TransactionLedger "TransactionLedger";
import Result "mo:base/Result";

actor AuditSystem {
    type AuditLog = {
        id : Nat;
        transactionId : Nat;
        status : Text; // "compliant", "non-compliant"
        timestamp : Nat;
    };

    var auditLogs : [AuditLog] = [];

    // Fungsi untuk audit transaksi
    public func auditTransaction(transactionId : Nat) : async () {
        let transactionOpt = Array.find(TransactionLedger.transactions, func(t) { t.id == transactionId });
        switch (transactionOpt) {
            case (?transaction) {
                // Logika audit sederhana (misalnya, memeriksa apakah jumlah dana sesuai dengan milestone)
                let isCompliant = true; // Ganti dengan logika audit sebenarnya
                let newAuditLog = {
                    id = Array.size(auditLogs);
                    transactionId = transactionId;
                    status = if (isCompliant) "compliant" else "non-compliant";
                    timestamp = Time.now();
                };
                auditLogs := Array.append(auditLogs, [newAuditLog]);
            };
            case (null) {
                throw ("Transaction not found");
            };
        };
    };

    // Fungsi untuk mendapatkan log audit
    public query func getAuditLogs() : async [AuditLog] {
        return auditLogs;
    };

    // Fungsi untuk mendapatkan status audit transaksi
    public query func getAuditStatus(transactionId : Nat) : async Text {
        let auditLogOpt = Array.find(auditLogs, func(a) { a.transactionId == transactionId });
        switch (auditLogOpt) {
            case (?auditLog) {
                return auditLog.status;
            };
            case (null) {
                return "not audited";
            };
        };
    };
};