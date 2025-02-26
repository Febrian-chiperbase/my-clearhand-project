actor CitizenReporting {
    type Report = {
        id : Nat;
        reporter : Text;
        description : Text;
        timestamp : Nat;
        status : Text; // "pending", "verified", "rejected"
    };

    var reports : [Report] = [];

    public func submitReport(reporter : Text, description : Text) : async () {
        let newReport = {
            id = Array.size(reports);
            reporter = reporter;
            description = description;
            timestamp = Time.now();
            status = "pending";
        };
        reports := Array.append(reports, [newReport]);
    };

    public func verifyReport(id : Nat) : async () {
        for (report in reports.vals()) {
            if (report.id == id) {
                reports[id].status := "verified";
                return;
            };
        };
        throw ("Report not found");
    };

    public query func getAllReports() : async [Report] {
        return reports;
    };
};