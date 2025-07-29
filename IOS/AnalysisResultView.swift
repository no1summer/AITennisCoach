import SwiftUI

// This is the main view that displays the complete analysis results.
// It takes an `AnalysisResult` object and arranges the data in a readable format.
struct AnalysisResultView: View {
    let result: AnalysisResult

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 25) {
                
                // MARK: - NTRP Rating Section
                // A prominent display of the final NTRP rating.
                VStack {
                    Text(result.ntrpLevel)
                        .font(.system(size: 70, weight: .heavy, design: .rounded))
                        .foregroundColor(.accentColor)
                    
                    Text("Estimated NTRP Level")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                
                // MARK: - Justification Section
                // A distinct section explaining why the model assigned the rating.
                VStack(alignment: .leading, spacing: 8) {
                    Label("Rating Justification", systemImage: "text.magnifyingglass")
                        .font(.title2.bold())
                    
                    Text(result.justification)
                        .font(.body)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // MARK: - Training Advice Section
                // A list of actionable tips for different aspects of the game.
                VStack(alignment: .leading, spacing: 15) {
                    Text("Your Personalized Training Plan")
                        .font(.title2.bold())
                        .padding(.bottom, 5)
                    
                    // Each piece of advice is presented in its own 'AdviceCard'.
                    AdviceCard(
                        title: "Forehand",
                        advice: result.trainingAdvice.forehand,
                        icon: "tennis.racket",
                        color: .green
                    )
                    
                    AdviceCard(
                        title: "Backhand",
                        advice: result.trainingAdvice.backhand,
                        icon: "tennis.racket",
                        color: .orange
                    )
                    
                    AdviceCard(
                        title: "Serve",
                        advice: result.trainingAdvice.serve,
                        icon: "figure.tennis",
                        color: .blue
                    )
                    
                    AdviceCard(
                        title: "Footwork",
                        advice: result.trainingAdvice.footwork,
                        icon: "figure.run",
                        color: .purple
                    )
                }
                .padding()
            }
            .padding(.horizontal) // Add horizontal padding to the entire VStack
        }
    }
}

// MARK: - AdviceCard Subview
// A reusable component for displaying a single piece of training advice.
struct AdviceCard: View {
    let title: String
    let advice: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(color)
                .frame(width: 40) // Give the icon a consistent width

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.bold)
                
                Text(advice)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.bottom, 10)
        // Add a divider for better separation, except for the last item.
        Divider()
    }
}


// MARK: - Preview Provider
// This allows you to see and design your view in Xcode without running the whole app.
// It uses sample data to populate the view.
struct AnalysisResultView_Previews: PreviewProvider {
    static var previews: some View {
        // Create a sample result to display in the preview.
        let sampleResult = AnalysisResult(
            ntrpLevel: "4.0",
            justification: "The player demonstrates dependable strokes and can control the direction of the ball on moderate-paced shots. However, they occasionally struggle with depth and shot variety under pressure.",
            trainingAdvice: TrainingAdvice(
                forehand: "Focus on hitting through the ball more to generate consistent depth. Practice cross-court and down-the-line drills.",
                backhand: "Your two-handed backhand is solid. Incorporate a one-handed slice for defensive situations and to change the pace of the rally.",
                serve: "Work on your toss consistency to improve first serve percentage. Aim for specific targets in the service box during practice.",
                footwork: "Practice split-stepping consistently as your opponent makes contact with the ball to improve your reaction time and positioning."
            )
        )
        
        // Embed in a NavigationView for realistic presentation.
        NavigationView {
            AnalysisResultView(result: sampleResult)
                .navigationTitle("Analysis Result")
                .navigationBarTitleDisplayMode(.inline)
        }
    }
}