//
//  HealthKitManager.swift
//  AIHealthAssistant
//
//  Created by Igor Łopatka on 21/05/2024.
//

import Foundation
import HealthKit

class HealthKitManager: ObservableObject {
    
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
    
    
    
    
    
    
}
