//
//  OpenAIService.swift
//  AIHealthAssistant
//
//  Created by Igor Łopatka on 24/05/2024.
//

import Foundation

class OpenAIService {
    private let apiKey: String
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    func streamCompletion(prompt: String, completion: @escaping (String) -> Void) {
        let endpoint = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.addValue("Bearer \(OpenAIAPI.key)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let parameters: [String: Any] = [
            "model": "gpt-4-turbo",
            "messages": [
                ["role": "system", "content": "You are a helpful assistant."],
                ["role": "user", "content": prompt]
            ],
            "stream": true
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: parameters)
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data else {
                if let error = error {
                    print("Error: \(error)")
                }
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                self.parseStreamedResponse(data: data, completion: completion)
            } else {
                print("Invalid response from server")
            }
        }
        
        task.resume()
    }
    
    private func parseStreamedResponse(data: Data, completion: @escaping (String) -> Void) {
        var buffer = Data()
        
        data.enumerateBytes { (bytePointer, range, stop) in
            buffer.append(contentsOf: bytePointer)
            
            if let responseString = String(data: buffer, encoding: .utf8) {
                DispatchQueue.main.async {
                    completion(responseString)
                }
                buffer.removeAll()
            }
        }
    }
}
