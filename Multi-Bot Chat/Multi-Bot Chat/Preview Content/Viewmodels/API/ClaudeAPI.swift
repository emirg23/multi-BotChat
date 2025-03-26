import Foundation

enum ClaudeAPIError: Error {
    case invalidURL
    case noDataReceived
    case invalidResponseFormat
    case apiError(type: String, message: String)
    case decodingError(Error)
    case networkError(Error)
}

class ClaudeAPI {
    private let apiKey: String
    private let apiUrl = "https://api.anthropic.com/v1/messages"
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    func sendMessage(systemPrompt: String, userMessage: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let url = URL(string: apiUrl) else {
            completion(.failure(ClaudeAPIError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("anthropic-swift/1.0", forHTTPHeaderField: "x-stainless-lang")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        
        let requestBody: [String: Any] = [
            "model": "claude-3-7-sonnet-20250219",
            "system": systemPrompt,
            "messages": [
                ["role": "user", "content": userMessage]
            ],
            "max_tokens": 4096
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody, options: [])
        } catch {
            completion(.failure(ClaudeAPIError.decodingError(error)))
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(ClaudeAPIError.networkError(error)))
                return
            }
            
            guard let data = data else {
                completion(.failure(ClaudeAPIError.noDataReceived))
                return
            }
            
            let responseString = String(data: data, encoding: .utf8) ?? "Unable to convert data to string"
            print("API Response: \(responseString)")
            
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                
                if let errorType = json?["type"] as? String, errorType == "error",
                   let errorDetails = json?["error"] as? [String: Any],
                   let errorTypeString = errorDetails["type"] as? String,
                   let errorMessage = errorDetails["message"] as? String {
                    
                    completion(.failure(ClaudeAPIError.apiError(type: errorTypeString, message: errorMessage)))
                    return
                }
                
                if let content = json?["content"] as? [[String: Any]],
                   let firstContent = content.first,
                   let text = firstContent["text"] as? String {
                    completion(.success(text))
                } else {
                    completion(.failure(ClaudeAPIError.invalidResponseFormat))
                }
            } catch {
                completion(.failure(ClaudeAPIError.decodingError(error)))
            }
        }
        
        task.resume()
    }
}
