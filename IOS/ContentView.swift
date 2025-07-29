import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = ContentViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                if viewModel.isLoading {
                    VStack {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                            .scaleEffect(1.5)
                        Text("Analyzing your video, this may take a moment...")
                            .font(.headline)
                            .foregroundColor(.gray)
                            .padding(.top, 10)
                    }
                } else if let result = viewModel.analysisResult {
                    AnalysisResultView(result: result)
                } else {
                    InitialView(onSelectVideo: {
                        viewModel.isShowingPicker = true
                    })
                }
                
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                }
            }
            .navigationTitle("Tennis AI Coach")
            .sheet(isPresented: $viewModel.isShowingPicker) {
                VideoPicker(didFinishPicking: { videoURL in
                    viewModel.isShowingPicker = false
                    viewModel.analyzeVideo(at: videoURL)
                })
            }
        }
    }
}

// A simple initial view
struct InitialView: View {
    var onSelectVideo: () -> Void
    
    var body: some View {
        VStack {
            Image(systemName: "tennis.racket")
                .font(.system(size: 80))
                .foregroundColor(.blue)
            Text("Get Your NTRP Rating")
                .font(.title)
                .bold()
            Text("Select a video of you playing to get a professional analysis from AI.")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding()
            Button(action: onSelectVideo) {
                Label("Select Video", systemImage: "video.fill")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 40)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}