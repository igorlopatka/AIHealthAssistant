//
//  AIHealthAssistantManager.swift
//  AIHealthAssistant
//
//  Created by Igor Łopatka on 24/05/2024.
//

import Combine
import Foundation
import HealthKit

class AIHealthAssistantVM: ObservableObject {
    
    // MARK: - OpenAI API
    
    @Published var streamedText: String = ""
    @Published var conversationHistory: [[String: String]] = []
    
    private var openAIService: OpenAIService
    
    init(openAIService: OpenAIService) {
        self.openAIService = openAIService
    }
    
    func sendUserMessage(_ message: String) {
        // Add the user's message to the conversation history
        conversationHistory.append(["role": "user", "content": message])
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
            conversationHistory.append(["role": "assistant", "content": streamedText])
            streamedText = ""
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
