//
//  ContentView.swift
//  AIHealthAssistant
//
//  Created by Igor Łopatka on 22/05/2024.
//

import HealthKit
import HealthKitUI
import SwiftUI

struct ContentView: View {
    
    @StateObject var health = HealthKitManager()
    
    var body: some View {
        Button("Access HealthKit data") {
        }
        .disabled(!health.authenticated)
        .onAppear {
        
            health.initiateHealthKitDataRequest()
        }
        .onChange(of: health.trigger) { _ in
            health.requestHealthKitDataAccess()
        }
    }
}

#Preview {
    ContentView()
}
