//
//  AIHealthAssistantManager.swift
//  AIHealthAssistant
//
//  Created by Igor Łopatka on 24/05/2024.
//

import Combine
import CoreData
import Foundation
import HealthKit

class AIHealthAssistantVM: ObservableObject {
    
    // MARK: - OpenAI API
    
    @Published var streamedText: String = ""
        @Published var conversationHistory: [[String: String]] = []
        
        private var openAIService: OpenAIService
        private var coreDataStack: CoreDataStack
        
        init(openAIService: OpenAIService, coreDataStack: CoreDataStack = CoreDataStack.shared) {
            self.openAIService = openAIService
            self.coreDataStack = coreDataStack
            loadMessages()
        }
        
        func sendUserMessage(_ message: String) {
            // Add the user's message to the conversation history
            addMessage(role: "user", content: message)
            streamedText = ""  // Clear streamedText for the new message
            
            // Start streaming the completion
            openAIService.streamCompletion(messages: conversationHistory) { [weak self] response in
                DispatchQueue.main.async {
                    // Update the streamed text as the response comes in
                    self?.streamedText = response
                }
            }
        }
        
        func addAssistantMessage() {
            // Add the assistant's message to the conversation history when streaming is complete
            if !streamedText.isEmpty {
                addMessage(role: "assistant", content: streamedText)
                streamedText = ""
            }
        }
        
        private func addMessage(role: String, content: String) {
            conversationHistory.append(["role": role, "content": content])
            let message = Message(context: coreDataStack.context)
            message.role = role
            message.content = content
            coreDataStack.saveContext()
        }
        
        private func loadMessages() {
            let fetchRequest: NSFetchRequest<Message> = Message.fetchRequest()
            
            do {
                let messages = try coreDataStack.context.fetch(fetchRequest)
                conversationHistory = messages.map { ["role": $0.role ?? "", "content": $0.content ?? ""] }
            } catch {
                print("Failed to fetch messages: \(error)")
            }
        }
    
    //MARK: - HealthKit
    
    @Published var authenticated = false
    @Published var trigger = false
    
    var healthStore = HKHealthStore()
    
    let allTypes: Set<HKSampleType> = {
        let readTypes: Set<HKSampleType> = [
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.quantityType(forIdentifier: .heartRate)!
        ]
        
        let shareTypes: Set<HKSampleType> = [
            HKObjectType.workoutType()
        ]
        
        return readTypes.union(shareTypes)
    }()
    
    func initiateHealthKitDataRequest() {
        if HKHealthStore.isHealthDataAvailable() {
            trigger.toggle()
        }
    }
    
    func requestHealthKitDataAccess() {
        healthStore.requestAuthorization(toShare: allTypes, read: allTypes) { success, error in
            if success {
                self.authenticated = true
            } else {
                fatalError("*** An error occurred while requesting authorization: \(String(describing: error)) ***")
            }
        }
    }
}
