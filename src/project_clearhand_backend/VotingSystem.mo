import Array "mo:base/Array";
import Principal "mo:base/Principal";
import Nat "mo:base/Nat";
import Time "mo:base/Time";
import RewardToken "RewardToken";

actor VotingSystem {
    type Vote = {
        voter : Principal;
        proposalId : Nat;
        vote : Bool; // true = yes, false = no
    };

    type Proposal = {
        id : Nat;
        title : Text;
        description : Text;
        yesVotes : Nat;
        noVotes : Nat;
        deadline : Nat;
        executed : Bool;
    };

    var proposals : [Proposal] = [];
    var votes : [Vote] = [];

    // Fungsi untuk menambahkan pengguna baru
    public func addUser(principal : Principal) : async () {
        let userOpt = Array.find(votes, func(v) { v.voter == principal });
        switch (userOpt) {
            case (null) {};
            case (?) {};
        };
    };

    // Fungsi untuk menambahkan proposal baru
    public func addProposal(title : Text, description : Text, duration : Nat) : async Result.Result<Nat, Text> {
        if (duration < 604800) { // Minimal 1 minggu (604800 detik)
            return Result.Err("Voting duration must be at least 1 week (604800 seconds)");
        };

        let newProposal = {
            id = Array.size(proposals);
            title = title;
            description = description;
            yesVotes = 0;
            noVotes = 0;
            deadline = Time.now() + duration;
            executed = false;
        };
        proposals := Array.append(proposals, [newProposal]);
        return Result.Ok(newProposal.id);
    };

    // Fungsi untuk memberikan suara pada proposal
    public func castVote(voter : Principal, proposalId : Nat, vote : Bool) : async Result.Result<Nat, Text> {
        let proposalOpt = Array.find(proposals, func(p) { p.id == proposalId });
        switch (proposalOpt) {
            case (?proposal) {
                if (proposal.deadline < Time.now()) {
                    return Result.Err("Voting period has ended");
                };
                if (proposal.executed) {
                    return Result.Err("Proposal has already been executed");
                };

                let voteOpt = Array.find(votes, func(v) { v.voter == voter && v.proposalId == proposalId });
                switch (voteOpt) {
                    case (?vote) {
                        return Result.Err("You have already voted on this proposal");
                    };
                    case (null) {
                        let newVote = {
                            voter = voter;
                            proposalId = proposalId;
                            vote = vote;
                        };
                        votes := Array.append(votes, [newVote]);

                        if (vote) {
                            proposals := Array.map(proposals, func(p) {
                                if (p.id == proposalId) {
                                    return { id = p.id; title = p.title; description = p.description; yesVotes = p.yesVotes + 1; noVotes = p.noVotes; deadline = p.deadline; executed = p.executed };
                                } else {
                                    return p;
                                }
                            });
                        } else {
                            proposals := Array.map(proposals, func(p) {
                                if (p.id == proposalId) {
                                    return { id = p.id; title = p.title; description = p.description; yesVotes = p.yesVotes; noVotes = p.noVotes + 1; deadline = p.deadline; executed = p.executed };
                                } else {
                                    return p;
                                }
                            });
                        };
                        return Result.Ok(proposalId);
                    };
                };
            };
            case (null) {
                return Result.Err("Proposal not found");
            };
        };
    };

    // Fungsi untuk mendapatkan detail proposal
    public query func getProposalDetails(proposalId : Nat) : async Result.Result<Proposal, Text> {
        if (proposalId >= Array.size(proposals)) {
            return Result.Err("Proposal not found");
        };
        return Result.Ok(proposals[proposalId]);
    };

    // Fungsi untuk mendapatkan semua proposal
    public query func getAllProposals() : async [Proposal] {
        return proposals;
    };

    // Fungsi untuk mengeksekusi proposal
    public func executeProposal(proposalId : Nat) : async Result.Result<Nat, Text> {
        await RewardToken.onlyOwner(async () => {
            let proposalOpt = Array.find(proposals, func(p) { p.id == proposalId });
            switch (proposalOpt) {
                case (?proposal) {
                    if (proposal.deadline > Time.now()) {
                        return Result.Err("Voting period has not ended yet");
                    };
                    if (proposal.executed) {
                        return Result.Err("Proposal has already been executed");
                    };

                    if (proposal.yesVotes > proposal.noVotes) {
                        // Eksekusi proposal
                        proposals := Array.map(proposals, func(p) {
                            if (p.id == proposalId) {
                                return { id = p.id; title = p.title; description = p.description; yesVotes = p.yesVotes; noVotes = p.noVotes; deadline = p.deadline; executed = true };
                            } else {
                                return p;
                            }
                        });
                        return Result.Ok(proposalId);
                    } else {
                        return Result.Err("Proposal rejected");
                    };
                };
                case (null) {
                    return Result.Err("Proposal not found");
                };
            };
        });
    };

    // Fungsi untuk mendapatkan hasil voting
    public query func getVotingResults(proposalId : Nat) : async Result.Result<(Nat, Nat, Nat), Text> {
        let proposalOpt = Array.find(proposals, func(p) { p.id == proposalId });
        switch (proposalOpt) {
            case (?proposal) {
                return Result.Ok((proposal.yesVotes, proposal.noVotes, proposal.yesVotes + proposal.noVotes));
            };
            case (null) {
                return Result.Err("Proposal not found");
            };
        };
    };
};