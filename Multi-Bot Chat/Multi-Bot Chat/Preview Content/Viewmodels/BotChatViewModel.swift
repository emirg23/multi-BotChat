

import Foundation
import SwiftUI

class BotChatViewModel: ObservableObject {
    @ObservedObject var dataStore: UserDataStore

    private var messageAreaVM: MessageAreaViewModel
    @Published var text: String = ""
    @Published var textHeight: CGFloat = 50
    @Published var rightTabPresent = false
    @Published var bot: Bot
    
    init(dataStore: UserDataStore, messageAreaVM: MessageAreaViewModel, bot: Bot) {
        self.dataStore = dataStore
        self.messageAreaVM = messageAreaVM
        self.bot = bot
    }
    
    func sendMessage() {
        withAnimation(.easeInOut(duration: 0.15)) {
            if let id = messageAreaVM.selectedChatId, let chatIndex = dataStore.user.chats.firstIndex(where: { $0.id == id }) {
                dataStore.user.chats[chatIndex].messages.append(ChatMessage(sender: "user", text: text))
                messageAreaVM.botAnswer(systemPrompt: self.bot.prompt.joined(separator: ". ") + ".", userText: text)
            } else {
                let id = UUID().uuidString
                let chat = Chat(id: id, botName: bot.name, promptName: bot.promptName, name: "Need AI for names")
                dataStore.user.chats.append(chat)
                messageAreaVM.selectedChatId = id
                
                if let chatIndex = dataStore.user.chats.firstIndex(where: { $0.id == id }) {
                    dataStore.user.chats[chatIndex].messages.append(ChatMessage(sender: "user", text: text))
                }
                
                messageAreaVM.botAnswer(systemPrompt: self.bot.prompt.joined(separator: ". ") + ".", userText: text)
            }
            self.closeKeyboard()
            text.removeAll()
        }
    }
    
    func closeKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    func updateTextHeight() {
        let maxWidth = UIScreen.main.bounds.width - 50 // because of padding
        let newSize = text.boundingRect(
            with: CGSize(width: maxWidth, height: .infinity),
            options: .usesLineFragmentOrigin,
            attributes: [.font: UIFont.systemFont(ofSize: 17)],
            context: nil
        )
        textHeight = min(120, max(40, newSize.height + 30))
    }
}
