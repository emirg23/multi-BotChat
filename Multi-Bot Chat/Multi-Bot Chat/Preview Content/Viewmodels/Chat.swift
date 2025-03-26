

import Foundation

struct Chat: Identifiable, Hashable, Codable {
    var id = UUID().uuidString
    var messages: [ChatMessage] = []
    var botName: String
    var promptName: String
    var name: String
    var lastMessageDate: Date {
        self.messages.last?.date ?? Date()
    }
    
    init(id: String = UUID().uuidString, messages: [ChatMessage] = [], botName: String, promptName: String, name: String) {
        self.id = id
        self.messages = messages
        self.botName = botName
        self.promptName = promptName
        self.name = name
    }
}


struct ChatMessage: Identifiable, Hashable, Codable {
    let id = UUID().uuidString
    let sender: String
    let text: String
    let date: Date
    
    init(sender: String, text: String, date: Date = Date()) {
        self.sender = sender
        self.text = text
        self.date = date
    }
}


