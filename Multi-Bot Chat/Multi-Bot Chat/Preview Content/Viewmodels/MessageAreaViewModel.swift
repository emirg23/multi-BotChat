import Foundation
import SwiftUI

class MessageAreaViewModel: ObservableObject {
    @ObservedObject var dataStore: UserDataStore
    @Published var animatingLastBotMessage = false
    @Published var botGenerating = false
    @Published var botAnswering = false
    @Published var selectedChatId: String?
    @Published var textWidth: Double
    @Published var botMessage: String?

    private let claudeAPI = ClaudeAPI(apiKey: "your-claude-api-key")

    init(dataStore: UserDataStore, animatingLastBotMessage: Bool = false, botAnswering: Bool = false, selectedChatId: String? = nil, textWidth: Double = 0.0) {
        self.dataStore = dataStore
        self.animatingLastBotMessage = animatingLastBotMessage
        self.botAnswering = botAnswering
        self.selectedChatId = selectedChatId
        self.textWidth = textWidth
    }
    
    func botAnswer(systemPrompt: String, userText: String) { // PLACE TO PUT THE API AND GET THE AI ASSISTED ANSWERS
        self.botGenerating = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.botGenerating = false
            self.botMessage = "AI API needs to be clarified for sense responds." 
            self.botAnswering = true
        }
        /*

        // for now, I just put claude API assist here but you can add every one you want
        claudeAPI.sendMessage(systemPrompt: systemPrompt, userMessage: userText) { result in
            DispatchQueue.main.async {
                self.botGenerating = false
                switch result {
                case .success(let message):
                    self.botAnswering = true
                    self.botMessage = message
                    print("Claude's Response: \(message)")
                case .failure(let error):
                    self.botAnswering = true
                    self.botMessage = "AI API needs to be clarified for proper responses."
                    print("Claude API Error: \(error.localizedDescription)")
                }
            }
        }
         */
    }
}
