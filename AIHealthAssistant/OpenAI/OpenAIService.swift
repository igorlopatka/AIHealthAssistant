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
    private var accumulatedResponse: String = ""

    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    func streamCompletion(messages: [Message], completion: @escaping (String) -> Void) {
        let endpoint = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let messageDictionaries = messages.map { ["role": $0.role.rawValue, "content": $0.content] }
        let parameters: [String: Any] = [
            "model": "gpt-3.5-turbo", // Ensure you use the correct model
            "messages": messageDictionaries,
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
            print("Raw response: \(responseString)") // Log the raw response for debugging
            
            responseString
                .components(separatedBy: "\n")
                .forEach { part in
                    guard !part.isEmpty, part != "data: [DONE]" else { return }
                    
                    let cleanedPart = part.replacingOccurrences(of: "data: ", with: "")
                    guard let jsonData = cleanedPart.data(using: .utf8) else { return }
                    
                    do {
                        if let json = try JSONSerialization.jsonObject(with: jsonData, options: .allowFragments) as? [String: Any],
                           let choices = json["choices"] as? [[String: Any]],
                           let delta = choices.first?["delta"] as? [String: Any],
                           let content = delta["content"] as? String {
                            DispatchQueue.main.async {
                                self.accumulatedResponse += content
                                self.completionHandler?(self.accumulatedResponse)
                            }
                        }
                    } catch {
                        print("Error parsing JSON: \(error)")
                        print("Part causing error: \(cleanedPart)")
                    }
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
