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

actor RewardToken {
    type Token = {
        name : Text;
        symbol : Text;
        decimals : Nat;
        totalSupply : Nat;
        balances : [(Principal, Nat)];
        allowances : [(Principal, [(Principal, Nat)])];
        stakedBalances : [(Principal, Nat)];
        reserve : Nat; // Reserve asset (misalnya, ICP dalam e8s)
        lastStakeTimestamp : Nat;
        stakeRewardsPerSecond : Nat; // Imbalan staking per detik
        targetPrice : Nat; // Harga target dalam e8s (misalnya, 1 ECT = 120.000 IDR)
        owner : Principal; // Hak kepemilikan smart contract
        paused : Bool; // Status pause smart contract
    };

    var token : Token = {
        name = "Anti-Corruption Token";
        symbol = "ECT";
        decimals = 8;
        totalSupply = 100_000_000; // Total supply awal 100 juta token
        balances = [];
        allowances = [];
        stakedBalances = [];
        reserve = 0; // Reserve asset awal 0 e8s
        lastStakeTimestamp = Time.now();
        stakeRewardsPerSecond = 100; // Imbalan staking per detik (misalnya, 100 e8s)
        targetPrice = 120_000_000; // Harga target dalam e8s (misalnya, 1 ECT = 120.000 IDR)
        owner = Principal.fromText("OWNER_PRINCIPAL_HERE").unwrap(); // Ganti dengan principal owner
        paused = false;
    };

    // Modifier untuk memastikan hanya pemilik yang dapat melakukan fungsi tertentu
    func onlyOwner(funcToCall : func () : async ()) : async () {
        if (msg.caller() != token.owner) {
            throw ("Only owner can call this function");
        };
        await funcToCall();
    };

    // Modifier untuk memastikan smart contract tidak di-pause
    func whenNotPaused(funcToCall : func () : async ()) : async () {
        if (token.paused) {
            throw ("Smart contract is paused");
        };
        await funcToCall();
    };

    // Modifier untuk memastikan smart contract di-pause
    func whenPaused(funcToCall : func () : async ()) : async () {
        if (!token.paused) {
            throw ("Smart contract is not paused");
        };
        await funcToCall();
    };

    // Fungsi untuk menambahkan saldo ke alamat tertentu
    func addToBalance(principal : Principal, amount : Nat) : async () {
        let balanceOpt = Array.find(token.balances, func(b) { b._1 == principal });
        switch (balanceOpt) {
            case (?balance) {
                token.balances := Array.map(token.balances, func(b) {
                    if (b._1 == principal) {
                        return (principal, balance._2 + amount);
                    } else {
                        return b;
                    }
                });
            };
            case (null) {
                token.balances := Array.append(token.balances, [(principal, amount)]);
            };
        };
    };

    // Fungsi untuk mengurangi saldo dari alamat tertentu
    func subtractFromBalance(principal : Principal, amount : Nat) : async () {
        let balanceOpt = Array.find(token.balances, func(b) { b._1 == principal });
        switch (balanceOpt) {
            case (?balance) {
                if (balance._2 < amount) {
                    throw ("Insufficient balance");
                };
                token.balances := Array.map(token.balances, func(b) {
                    if (b._1 == principal) {
                        return (principal, balance._2 - amount);
                    } else {
                        return b;
                    }
                });
            };
            case (null) {
                throw ("User not found");
            };
        };
    };

    // Fungsi untuk menambahkan pengguna baru
    public func addUser(principal : Principal) : async () {
        let userOpt = Array.find(token.balances, func(b) { b._1 == principal });
        switch (userOpt) {
            case (null) {
                token.balances := Array.append(token.balances, [(principal, 0)]);
            };
            case (?) {};
        };
    };

    // Fungsi untuk memberikan reward token virtual
    public func mintTokens(principal : Principal, amount : Nat) : async () {
        await onlyOwner(async () => {
            await addToBalance(principal, amount);
            token.totalSupply += amount;
        });
    };

    // Fungsi untuk mendapatkan saldo pengguna
    public query func getBalance(principal : Principal) : async Nat {
        let balanceOpt = Array.find(token.balances, func(b) { b._1 == principal });
        switch (balanceOpt) {
            case (?balance) {
                return balance._2;
            };
            case (null) {
                return 0;
            };
        };
    };

    // Fungsi untuk mendapatkan total supply token
    public query func getTotalSupply() : async Nat {
        return token.totalSupply;
    };

    // Fungsi untuk mentransfer token
    public func transfer(from : Principal, to : Principal, amount : Nat, fee : ?Nat, memo : ?Blob) : async Result.Result<Nat, Text> {
        await whenNotPaused(async () => {
            if (amount <= 0) {
                return Result.Err("Amount must be greater than zero");
            };

            let fromBalance = await getBalance(from);
            if (fromBalance < amount) {
                return Result.Err("Insufficient balance");
            };

            await subtractFromBalance(from, amount);
            await addToBalance(to, amount);

            // Biaya transfer jika ada
            if (fee.isSome()) {
                await addToBalance(token.owner, fee.unwrap());
            };

            return Result.Ok(0); // Transaction index (placeholder)
        });
    };

    // Fungsi untuk mendapatkan nama token
    public query func name() : async Text {
        return token.name;
    };

    // Fungsi untuk mendapatkan simbol token
    public query func symbol() : async Text {
        return token.symbol;
    };

    // Fungsi untuk mendapatkan jumlah desimal token
    public query func decimals() : async Nat {
        return token.decimals;
    };

    // Fungsi untuk mendapatkan jumlah token yang diizinkan untuk alamat tertentu
    public query func allowance(owner : Principal, spender : Principal) : async Nat {
        let allowanceOpt = Array.find(token.allowances, func(a) { a._1 == owner });
        switch (allowanceOpt) {
            case (?allowance) {
                let spenderAllowanceOpt = Array.find(allowance._2, func(a) { a._1 == spender });
                switch (spenderAllowanceOpt) {
                    case (?spenderAllowance) {
                        return spenderAllowance._2;
                    };
                    case (null) {
                        return 0;
                    };
                };
            };
            case (null) {
                return 0;
            };
        };
    };

    // Fungsi untuk memberikan izin untuk alamat tertentu
    public func approve(owner : Principal, spender : Principal, value : Nat) : async Result.Result<Nat, Text> {
        await whenNotPaused(async () => {
            let allowanceOpt = Array.find(token.allowances, func(a) { a._1 == owner });
            switch (allowanceOpt) {
                case (?allowance) {
                    let updatedAllowance = Array.map(allowance._2, func(a) {
                        if (a._1 == spender) {
                            return (spender, value);
                        } else {
                            return a;
                        }
                    });
                    token.allowances := Array.map(token.allowances, func(a) {
                        if (a._1 == owner) {
                            return (owner, updatedAllowance);
                        } else {
                            return a;
                        }
                    });
                };
                case (null) {
                    token.allowances := Array.append(token.allowances, [(owner, [(spender, value)])]);
                };
            };
            return Result.Ok(0); // Transaction index (placeholder)
        });
    };

    // Fungsi untuk mentransfer token dari alamat yang diizinkan
    public func transferFrom(owner : Principal, from : Principal, to : Principal, amount : Nat, fee : ?Nat, memo : ?Blob) : async Result.Result<Nat, Text> {
        await whenNotPaused(async () => {
            if (amount <= 0) {
                return Result.Err("Amount must be greater than zero");
            };

            let ownerAllowance = await allowance(owner, from);
            if (ownerAllowance < amount) {
                return Result.Err("Insufficient allowance");
            };

            let fromBalance = await getBalance(from);
            if (fromBalance < amount) {
                return Result.Err("Insufficient balance");
            };

            await subtractFromBalance(from, amount);
            await addToBalance(to, amount);

            // Kurangi izin yang diberikan
            await approve(owner, from, ownerAllowance - amount);

            // Biaya transfer jika ada
            if (fee.isSome()) {
                await addToBalance(token.owner, fee.unwrap());
            };

            return Result.Ok(0); // Transaction index (placeholder)
        });
    };

    // Fungsi untuk staking token
    public func stakeTokens(principal : Principal, amount : Nat) : async () {
        await whenNotPaused(async () => {
            let balanceOpt = Array.find(token.balances, func(b) { b._1 == principal });
            switch (balanceOpt) {
                case (?balance) {
                    if (balance._2 < amount) {
                        throw ("Insufficient balance");
                    };
                    await subtractFromBalance(principal, amount);
                    let stakedOpt = Array.find(token.stakedBalances, func(s) { s._1 == principal });
                    switch (stakedOpt) {
                        case (?staked) {
                            token.stakedBalances := Array.map(token.stakedBalances, func(s) {
                                if (s._1 == principal) {
                                    return (principal, staked._2 + amount);
                                } else {
                                    return s;
                                }
                            });
                        };
                        case (null) {
                            token.stakedBalances := Array.append(token.stakedBalances, [(principal, amount)]);
                        };
                    };
                };
                case (null) {
                    throw ("User not found");
                };
            };
        });
    };

    // Fungsi untuk unstaking token
    public func unstakeTokens(principal : Principal, amount : Nat) : async () {
        await whenNotPaused(async () => {
            let stakedOpt = Array.find(token.stakedBalances, func(s) { s._1 == principal });
            switch (stakedOpt) {
                case (?staked) {
                    if (staked._2 < amount) {
                        throw ("Insufficient staked tokens");
                    };
                    await addToBalance(principal, amount);
                    token.stakedBalances := Array.map(token.stakedBalances, func(s) {
                        if (s._1 == principal) {
                            return (principal, staked._2 - amount);
                        } else {
                            return s;
                        }
                    });
                };
                case (null) {
                    throw ("No staked tokens");
                };
            };
        });
    };

    // Fungsi untuk mendapatkan saldo staked pengguna
    public query func getStakedBalance(principal : Principal) : async Nat {
        let stakedOpt = Array.find(token.stakedBalances, func(s) { s._1 == principal });
        switch (stakedOpt) {
            case (?staked) {
                return staked._2;
            };
            case (null) {
                return 0;
            };
        };
    };

    // Fungsi untuk menghitung imbalan staking
    public query func calculateStakeRewards(principal : Principal) : async Nat {
        let stakedOpt = Array.find(token.stakedBalances, func(s) { s._1 == principal });
        switch (stakedOpt) {
            case (?staked) {
                let currentTime = Time.now();
                let timeElapsed = currentTime - token.lastStakeTimestamp;
                let rewards = staked._2 * timeElapsed * token.stakeRewardsPerSecond;
                return rewards;
            };
            case (null) {
                return 0;
            };
        };
    };

    // Fungsi untuk mengklaim imbalan staking
    public func claimStakeRewards(principal : Principal) : async () {
        await whenNotPaused(async () => {
            let rewards = await calculateStakeRewards(principal);
            if (rewards > 0) {
                await addToBalance(principal, rewards);
                token.lastStakeTimestamp = Time.now();
            };
        });
    };

    // Fungsi untuk menambahkan reserve asset (misalnya, ICP dalam e8s)
    public func addToReserve(amount : Nat) : async () {
        await onlyOwner(async () => {
            token.reserve += amount;
        });
    };

    // Fungsi untuk mendapatkan jumlah reserve asset
    public query func getReserve() : async Nat {
        return token.reserve;
    };

    // Fungsi untuk pertukaran token dengan reserve asset
    public func swapTokensForReserve(principal : Principal, amount : Nat) : async () {
        await whenNotPaused(async () => {
            let balanceOpt = Array.find(token.balances, func(b) { b._1 == principal });
            switch (balanceOpt) {
                case (?balance) {
                    if (balance._2 < amount) {
                        throw ("Insufficient balance");
                    };
                    await subtractFromBalance(principal, amount);
                    let reserveAmount = amount * 1_200_000; // Konversi dari satuan ke e8s (1 ECT = 1.200.000 e8s)
                    if (token.reserve < reserveAmount) {
                        throw ("Insufficient reserve");
                    };
                    token.reserve -= reserveAmount;
                    // Transfer reserve asset ke alamat pengguna (misalnya, ICP)
                    let accountIdentifier = AccountIdentifier.fromPrincipal(principal);
                    let transferResult = await ICRC.transfer({
                        to = accountIdentifier;
                        fee = ?{ e8s = 10_000 }; // Biaya transfer ICP (10_000 e8s = 0.00001 ICP)
                        memo = ?0;
                        amount = { e8s = reserveAmount };
                        from_subaccount = null;
                        created_at_time = null;
                    });
                    switch (transferResult) {
                        case (#Ok) {
                            // Transfer berhasil
                        };
                        case (#Err(err)) {
                            // Handle error transfer
                            throw ("Transfer failed: " # err);
                        };
                    };
                };
                case (null) {
                    throw ("User not found");
                };
            };
        });
    };

    // Fungsi untuk pertukaran reserve asset dengan token
    public func swapReserveForTokens(principal : Principal, reserveAmount : Nat) : async () {
        await whenNotPaused(async () => {
            if (token.reserve < reserveAmount) {
                throw ("Insufficient reserve");
            };
            token.reserve -= reserveAmount;
            let tokenAmount = reserveAmount / 1_200_000; // Konversi dari e8s ke satuan
            await addToBalance(principal, tokenAmount);
        });
    };

    // Fungsi untuk stabilisasi harga
    public func stabilizePrice() : async () {
        await onlyOwner(async () => {
            let totalSupply = await getTotalSupply();
            let reserve = await getReserve();

            // Algoritma stabilisasi harga sederhana
            let currentPrice = reserve / totalSupply;

            if (currentPrice < token.targetPrice) {
                // Harga terlalu rendah, tambahkan reserve
                let additionalReserve = (token.targetPrice - currentPrice) * totalSupply;
                await addToReserve(additionalReserve);
            } else if (currentPrice > token.targetPrice) {
                // Harga terlalu tinggi, kurangi reserve
                let excessReserve = (currentPrice - token.targetPrice) * totalSupply;
                await swapReserveForTokens(Principal.fromText("SYSTEM_PRINCIPAL_HERE").unwrap(), excessReserve);
            };
        });
    };

    // Fungsi untuk menjeda smart contract
    public func pause() : async () {
        await onlyOwner(async () => {
            token.paused = true;
        });
    };

    // Fungsi untuk melanjutkan smart contract
    public func unpause() : async () {
        await onlyOwner(async () => {
            token.paused = false;
        });
    };

    // Fungsi untuk mengubah pemilik smart contract
    public func transferOwnership(newOwner : Principal) : async () {
        await onlyOwner(async () => {
            token.owner = newOwner;
        });
    };

    // Fungsi untuk mendapatkan seluruh saldo pengguna
    public query func getBalances() : async [(Principal, Nat)] {
        return token.balances;
    };

    // Fungsi untuk mendapatkan seluruh izin pengguna
    public query func getAllowances() : async [(Principal, [(Principal, Nat)])] {
        return token.allowances;
    };

    // Fungsi untuk mendapatkan seluruh saldo staked pengguna
    public query func getStakedBalances() : async [(Principal, Nat)] {
        return token.stakedBalances;
    };
};