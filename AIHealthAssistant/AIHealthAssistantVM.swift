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
        @Published var conversationHistory: [Message] = []
        
        private var openAIService: OpenAIService
        private var coreDataStack: CoreDataStack
        
        init(openAIService: OpenAIService, coreDataStack: CoreDataStack = CoreDataStack.shared) {
            self.openAIService = openAIService
            self.coreDataStack = coreDataStack
            loadMessages()
        }
        
        func sendUserMessage(_ message: String) {
            // Add the user's message to the conversation history
            let userMessage = Message(role: .user, content: message)
            addMessage(userMessage)
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
                let assistantMessage = Message(role: .assistant, content: streamedText)
                addMessage(assistantMessage)
                streamedText = ""
            }
        }
        
        private func addMessage(_ message: Message) {
            conversationHistory.append(message)
            let messageEntity = MessageEntity(context: coreDataStack.context)
            messageEntity.role = message.role.rawValue
            messageEntity.content = message.content
            coreDataStack.saveContext()
        }
        
        private func loadMessages() {
            let fetchRequest: NSFetchRequest<MessageEntity> = MessageEntity.fetchRequest()
            
            do {
                let messages = try coreDataStack.context.fetch(fetchRequest)
                conversationHistory = messages.map { Message(role: MessageRole(rawValue: $0.role ?? "") ?? .user, content: $0.content ?? "") }
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
