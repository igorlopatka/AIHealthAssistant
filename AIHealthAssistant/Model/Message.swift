//
//  Message.swift
//  AIHealthAssistant
//
//  Created by Igor Łopatka on 29/05/2024.
//

import Foundation

enum MessageRole: String, Codable {
    case user
    case assistant
}

struct Message: Codable, Identifiable {
    var id = UUID()
    var role: MessageRole
    var content: String
    
    enum CodingKeys: String, CodingKey {
        case role
        case content
    }
}
