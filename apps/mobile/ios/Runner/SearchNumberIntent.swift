import AppIntents
import Foundation

@available(iOS 16.0, *)
struct SearchNumberIntent: AppIntent {
    static var title: LocalizedStringResource = "Search Number in OpenCaller"
    static var description = IntentDescription("Looks up caller identification and spam reputation for a phone number.")

    @Parameter(title: "Phone Number", description: "The incoming or unknown phone number")
    var phoneNumber: String

    static var parameterSummary: some ParameterSummary {
        Summary("Lookup \(\.$phoneNumber) in OpenCaller")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let clean = phoneNumber.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
        guard let e164 = Int64(clean), e164 > 0 else {
            return .result(dialog: "Please provide a valid phone number with country code.")
        }

        let url = URL(string: "https://opencaller.blackmatter.cc/v1/lookup/\(e164)")!
        var request = URLRequest(url: url)
        request.timeoutInterval = 3.0

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                return .result(dialog: "Number +\(e164) is clean or unlisted.")
            }

            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                let name = json["caller_name"] as? String ?? "Unidentified Caller"
                let spamScore = (json["spam_score"] as? Double) ?? 0.0
                let isSpam = (json["is_spam"] as? Bool) ?? false

                if isSpam {
                    return .result(dialog: "⚠️ High Risk Spam / Scam: \(name) (Score: \(Int(spamScore * 100))%)")
                } else {
                    return .result(dialog: "✅ Caller ID: \(name)")
                }
            }
        } catch {
            return .result(dialog: "Unable to reach OpenCaller server. Check internet connection.")
        }

        return .result(dialog: "Number lookup completed.")
    }
}
