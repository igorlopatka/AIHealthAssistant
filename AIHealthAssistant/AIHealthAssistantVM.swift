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
    
    lazy var allHealthDataTypes: (sampleTypes: Set<HKSampleType>, characteristicTypes: Set<HKObjectType>) = {
        return getAllHealthDataTypes()
    }()
    
    func getAllHealthDataTypes() -> (Set<HKSampleType>, Set<HKObjectType>) {
        var allSampleTypes = Set<HKSampleType>()
        var allCharacteristicTypes = Set<HKObjectType>()
        
        // Add all quantity types
        let quantityTypes: [HKQuantityTypeIdentifier] = [
            .bodyMass, .height, .bodyMassIndex, .stepCount, .distanceWalkingRunning, .distanceCycling,
            .heartRate, .activeEnergyBurned, .basalEnergyBurned, .flightsClimbed, .nikeFuel, .appleExerciseTime,
            .respiratoryRate, .bloodPressureSystolic, .bloodPressureDiastolic, .bloodGlucose, .electrodermalActivity,
            .heartRateVariabilitySDNN, .vo2Max, .waistCircumference, .restingHeartRate, .walkingHeartRateAverage,
            .environmentalAudioExposure, .headphoneAudioExposure, .bodyFatPercentage, .leanBodyMass, .walkingDoubleSupportPercentage,
            .sixMinuteWalkTestDistance, .walkingSpeed, .walkingStepLength, .stairAscentSpeed, .stairDescentSpeed
        ]
        
        for quantityType in quantityTypes {
            if let type = HKObjectType.quantityType(forIdentifier: quantityType) {
                allSampleTypes.insert(type)
            }
        }
        
        // Add all category types
        let categoryTypes: [HKCategoryTypeIdentifier] = [
            .sleepAnalysis, .appleStandHour, .cervicalMucusQuality, .ovulationTestResult, .menstrualFlow, .intermenstrualBleeding,
            .sexualActivity, .mindfulSession, .highHeartRateEvent, .lowHeartRateEvent, .irregularHeartRhythmEvent,
            .pregnancy, .lactation, .contraceptive, .toothbrushingEvent, .audioExposureEvent, .environmentalAudioExposureEvent
        ]
        
        for categoryType in categoryTypes {
            if let type = HKObjectType.categoryType(forIdentifier: categoryType) {
                allSampleTypes.insert(type)
            }
        }
        
        // Add workout type
        allSampleTypes.insert(HKObjectType.workoutType())
        
        // Add characteristic types
        let characteristicTypes: [HKCharacteristicTypeIdentifier] = [
            .biologicalSex, .bloodType, .dateOfBirth, .fitzpatrickSkinType, .wheelchairUse
        ]
        
        for characteristicType in characteristicTypes {
            if let type = HKObjectType.characteristicType(forIdentifier: characteristicType) {
                allCharacteristicTypes.insert(type)
            }
        }
        
        // Add correlation types
        let correlationTypes: [HKCorrelationTypeIdentifier] = [
            .bloodPressure, .food
        ]
        
        for correlationType in correlationTypes {
            if let type = HKObjectType.correlationType(forIdentifier: correlationType) {
                allSampleTypes.insert(type)
            }
        }
        
        // Add document types
        if let allergyRecordType = HKObjectType.clinicalType(forIdentifier: .allergyRecord) {
            allSampleTypes.insert(allergyRecordType)
        }
        if let conditionRecordType = HKObjectType.clinicalType(forIdentifier: .conditionRecord) {
            allSampleTypes.insert(conditionRecordType)
        }
        if let immunizationRecordType = HKObjectType.clinicalType(forIdentifier: .immunizationRecord) {
            allSampleTypes.insert(immunizationRecordType)
        }
        if let labResultRecordType = HKObjectType.clinicalType(forIdentifier: .labResultRecord) {
            allSampleTypes.insert(labResultRecordType)
        }
        if let medicationRecordType = HKObjectType.clinicalType(forIdentifier: .medicationRecord) {
            allSampleTypes.insert(medicationRecordType)
        }
        if let procedureRecordType = HKObjectType.clinicalType(forIdentifier: .procedureRecord) {
            allSampleTypes.insert(procedureRecordType)
        }
        if let vitalSignRecordType = HKObjectType.clinicalType(forIdentifier: .vitalSignRecord) {
            allSampleTypes.insert(vitalSignRecordType)
        }
        
        return (allSampleTypes, allCharacteristicTypes)
    }
    
    
    func initiateHealthKitDataRequest() {
        if HKHealthStore.isHealthDataAvailable() {
            trigger.toggle()
        }
    }
    
    func requestHealthKitDataAccess() {
        let allSampleTypes = allHealthDataTypes.sampleTypes
        let allCharacteristicTypes = allHealthDataTypes.characteristicTypes

        // Prepare the read types set correctly by including all sample types (which are also object types)
        // and all characteristic types. Both are subsets of HKObjectType, so union them correctly.
        var readTypes = Set<HKObjectType>(allSampleTypes)
        readTypes.formUnion(allCharacteristicTypes)

        healthStore.requestAuthorization(toShare: allSampleTypes, read: readTypes) { success, error in
            if success {
                self.authenticated = true
            } else {
                fatalError("*** An error occurred while requesting authorization: \(String(describing: error)) ***")
            }
        }
    }
}
