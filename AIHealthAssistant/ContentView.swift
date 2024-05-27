//
//  ContentView.swift
//  AIHealthAssistant
//
//  Created by Igor Łopatka on 22/05/2024.
//

import HealthKit
import SwiftUI

struct ContentView: View {
    
    @StateObject private var vm: AIHealthAssistantVM
    
    init(vm: AIHealthAssistantVM) {
        _vm = StateObject(wrappedValue: vm)
    }
    
    @State private var prompt: String = ""
    
    var body: some View {
        VStack {
            TextField("Enter your prompt", text: $prompt)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            Button(action: {
                vm.streamCompletion(prompt: prompt)
            }) {
                Text("Get Completion")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            
            ScrollView {
                Text(vm.streamedText)
                    .textSelection(.enabled)
                    .padding()
                    
            }
        }
        .padding()
        Button("Access HealthKit data") {
            vm.initiateHealthKitDataRequest()
        }
        .disabled(!vm.authenticated)
        .onChange(of: vm.trigger) { _ in
            vm.requestHealthKitDataAccess()
        }
    }
}

#Preview {
    ContentView(vm: AIHealthAssistantVM(openAIService: OpenAIService(apiKey: OpenAIAPI.key)))
}
