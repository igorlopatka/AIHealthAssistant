//
//  OpenAIService.swift
//  AIHealthAssistant
//
//  Created by Igor Łopatka on 24/05/2024.
//

import Foundation

class OpenAIService: NSObject, URLSessionDataDelegate {
    private let apiKey: String
    private var completionHandler: ((String) -> Void)?

    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    func streamCompletion(prompt: String, completion: @escaping (String) -> Void) {
        self.completionHandler = completion
        let endpoint = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let parameters: [String: Any] = [
            "model": "gpt-3.5-turbo",
            "messages": [
                ["role": "system", "content": "You are a helpful assistant."],
                ["role": "user", "content": prompt]
            ],
            "stream": true
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: parameters)
        
        let session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
        let task = session.dataTask(with: request)
        task.resume()
    }
    
    // Delegate method to handle streaming response
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        if let responseString = String(data: data, encoding: .utf8) {
            DispatchQueue.main.async {
                self.completionHandler?(responseString)
            }
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            print("Error: \(error)")
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
            completionHandler(.allow)
        } else {
            print("Invalid response from server")
            completionHandler(.cancel)
        }
    }
}
