import Foundation

enum ReportSubmissionState: Equatable {
    case idle
    case loading
    case success
    case failure(String)
}

@MainActor
final class ReportViewModel: ObservableObject {
    @Published var category: ReportCategory = .behavior
    @Published var description: String = ""
    @Published var state: ReportSubmissionState = .idle

    private let pendingReportKey = "uniride_pending_report"

    func submit(reportedUserId: String, reportedUserName: String) {
        let trimmed = description.trimmingCharacters(in: .whitespaces)
        guard trimmed.count >= 10 else {
            state = .failure("Description must be at least 10 characters.")
            return
        }

        state = .loading
        let report = IncidentReport(
            reportedUserId: reportedUserId,
            reportedUserName: reportedUserName,
            category: category,
            description: trimmed
        )

        Task {
            let success = await sendReport(report)
            if success {
                clearPendingReport()
                state = .success
            } else {
                savePendingReport(report)
                state = .failure("No connection. Your report was saved and will be sent when you reconnect.")
            }
        }
    }

    func retryPendingReportIfNeeded() {
        guard let report = loadPendingReport() else { return }
        Task {
            let success = await sendReport(report)
            if success { clearPendingReport() }
        }
    }

    // MARK: - Private

    private func sendReport(_ report: IncidentReport) async -> Bool {
        await withCheckedContinuation { continuation in
            CloudFunctionsService.shared.reportUser(report: report) { result in
                continuation.resume(returning: result)
            }
        }
    }

    private func savePendingReport(_ report: IncidentReport) {
        let data: [String: String] = [
            "reportedUserId": report.reportedUserId,
            "reportedUserName": report.reportedUserName,
            "category": report.category.rawValue,
            "description": report.description
        ]
        UserDefaults.standard.set(data, forKey: pendingReportKey)
    }

    private func loadPendingReport() -> IncidentReport? {
        guard
            let data = UserDefaults.standard.dictionary(forKey: pendingReportKey) as? [String: String],
            let userId = data["reportedUserId"],
            let userName = data["reportedUserName"],
            let categoryRaw = data["category"],
            let category = ReportCategory(rawValue: categoryRaw),
            let desc = data["description"]
        else { return nil }

        return IncidentReport(
            reportedUserId: userId,
            reportedUserName: userName,
            category: category,
            description: desc
        )
    }

    private func clearPendingReport() {
        UserDefaults.standard.removeObject(forKey: pendingReportKey)
    }
}
