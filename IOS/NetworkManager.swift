import Foundation

enum NetworkError: Error {
    case badURL, requestFailed, decodingError, unknown
}

class NetworkManager {
    func uploadVideo<T: Decodable>(url: URL, to endpointURL: URL) async throws -> T {
        var request = URLRequest(url: endpointURL)
        request.httpMethod = "POST"
        
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var httpBody = Data()
        
        // Append video data
        let filename = url.lastPathComponent
        let mimeType = "video/mp4" // Or use a library to determine this dynamically
        
        guard let videoData = try? Data(contentsOf: url) else {
            throw NetworkError.requestFailed
        }
        
        httpBody.append("--\(boundary)\r\n".data(using: .utf8)!)
        httpBody.append("Content-Disposition: form-data; name=\"video\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        httpBody.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        httpBody.append(videoData)
        httpBody.append("\r\n".data(using: .utf8)!)
        
        // Final boundary
        httpBody.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = httpBody
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NetworkError.requestFailed
        }
        
        do {
            // The backend returns the JSON directly in the body
            let decodedData = try JSONDecoder().decode(T.self, from: data)
            return decodedData
        } catch {
            throw NetworkError.decodingError
        }
    }
}