import Foundation

@MainActor
class ContentViewModel: ObservableObject {
    @Published var analysisResult: AnalysisResult?
    @Published var errorMessage: String?
    @Published var isLoading = false
    @Published var isShowingPicker = false
    
    // IMPORTANT: Replace with your computer's local IP address
    // Find it in System Settings -> Wi-Fi -> Details -> IP Address
    // Your iPhone must be on the SAME Wi-Fi network as your computer.
    private let backendURL = "http://192.168.1.101:5001/analyze"

    private let networkManager = NetworkManager()

    func analyzeVideo(at videoURL: URL) {
        isLoading = true
        errorMessage = nil
        analysisResult = nil

        Task {
            do {
                let result: AnalysisResult = try await networkManager.uploadVideo(
                    url: videoURL,
                    to: URL(string: backendURL)!
                )
                self.analysisResult = result
            } catch {
                self.errorMessage = "Analysis Failed: \(error.localizedDescription)"
            }
            self.isLoading = false
        }
    }
}