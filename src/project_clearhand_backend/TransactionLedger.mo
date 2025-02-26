actor TransactionLedger {
    type Transaction = {
        id : Nat;
        sender : Text;
        receiver : Text;
        amount : Nat;
        timestamp : Nat;
    };

    var transactions : [Transaction] = [];

    public func addTransaction(sender : Text, receiver : Text, amount : Nat) : async () {
        let newTransaction = {
            id = Array.size(transactions);
            sender = sender;
            receiver = receiver;
            amount = amount;
            timestamp = Time.now();
        };
        transactions := Array.append(transactions, [newTransaction]);
    };

    public query func getAllTransactions() : async [Transaction] {
        return transactions;
    };
};