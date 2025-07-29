import Foundation

// These structs must match the JSON structure from your Python backend
struct AnalysisResult: Codable, Identifiable {
    let id = UUID()
    let ntrpLevel: String
    let justification: String
    let trainingAdvice: TrainingAdvice
    
    enum CodingKeys: String, CodingKey {
        case ntrpLevel = "ntrp_level"
        case justification
        case trainingAdvice = "training_advice"
    }
}

struct TrainingAdvice: Codable {
    let forehand: String
    let backhand: String
    let serve: String
    let footwork: String
}