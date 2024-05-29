//
//  ContentView.swift
//  AIHealthAssistant
//
//  Created by Igor Łopatka on 22/05/2024.
//

import HealthKit
import SwiftUI

struct ContentView: View {
    
    @StateObject private var viewModel: AIHealthAssistantVM
    
    init(vm: AIHealthAssistantVM) {
        _viewModel = StateObject(wrappedValue: vm)
    }
    
    @State private var userMessage: String = ""
    
    var body: some View {
        VStack {
            ScrollView {
                VStack(alignment: .leading) {
                    ForEach(viewModel.conversationHistory) { message in
                        HStack {
                            if message.role == .user {
                                Spacer()
                                Text(message.content)
                                    .padding()
                                    .background(Color.blue)
                                    .cornerRadius(10)
                                    .foregroundColor(.white)
                                    .padding(.horizontal)
                            } else {
                                Text(message.content)
                                    .padding()
                                    .background(Color.gray.opacity(0.2))
                                    .cornerRadius(10)
                                    .foregroundColor(.black)
                                    .padding(.horizontal)
                                Spacer()
                            }
                        }
                    }
                    if !viewModel.streamedText.isEmpty {
                        HStack {
                            Text(viewModel.streamedText)
                                .padding()
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(10)
                                .foregroundColor(.black)
                                .padding(.horizontal)
                            Spacer()
                        }
                    }
                }
            }
            
            HStack {
                TextField("Enter your message", text: $userMessage)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                Button(action: {
                    viewModel.sendUserMessage(userMessage)
                    userMessage = ""
                    
                    // Simulate a delay for the assistant to respond
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        viewModel.addAssistantMessage()
                    }
                }) {
                    Text("Send")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding()
            }
        }
    }
}

#Preview {
    ContentView(vm: AIHealthAssistantVM(openAIService: OpenAIService(apiKey: OpenAIAPI.key)))
}
