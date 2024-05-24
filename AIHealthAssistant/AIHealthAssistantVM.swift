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
            // Modifying the trigger initiates the health data access request.
            trigger.toggle()
        }
    }
    
    func requestHealthKitDataAccess() {
        healthStore.requestAuthorization(toShare: allTypes, read: allTypes) { success, error in
            if success {
                self.authenticated = true
            } else {
                // Handle the error here.
                fatalError("*** An error occurred while requesting authorization: \(String(describing: error)) ***")
            }
        }
    }
    
    //MARK: - OpenAI API
    
    @Published var streamedText: String = ""
    
        private var openAIService: OpenAIService
        
        init(openAIService: OpenAIService) {
            self.openAIService = openAIService
        }
        
        func streamCompletion(prompt: String) {
            openAIService.streamCompletion(prompt: prompt) { [weak self] response in
                DispatchQueue.main.async {
                    self?.streamedText.append(response)
                }
            }
        }
    
}
