
import SwiftUI

struct MessageArea: View {
    @ObservedObject var messageAreaVM: MessageAreaViewModel
    @ObservedObject var dataStore: UserDataStore
    @ObservedObject var botChatVM: BotChatViewModel
    
    var body: some View {
        if messageAreaVM.selectedChatId != nil {
            ScrollViewReader { proxy in
                ScrollView {
                    Spacer()
                        .frame(height: 20)
                    
                    VStack(spacing: 15){
                        if let chat = dataStore.user.chats.first(where: { $0.id == messageAreaVM.selectedChatId && $0.botName == botChatVM.bot.name}) { // find which bot are we in and the chat number
                            ForEach(chat.messages) { message in
                                if message.sender == "user" {
                                    userMessage(text: message.text)
                                } else {
                                    botMessage(text: message.text, lastMessage: chat.messages.last?.id == message.id)
                                }
                            }
                            .onAppear {
                                if let lastMessage = chat.messages.last {
                                    DispatchQueue.main.async {
                                        proxy.scrollTo(lastMessage.id, anchor: .top)
                                    }
                                }
                            }
                        }
                        
                        if messageAreaVM.botGenerating {
                            BotThinkingDot()
                        } else if messageAreaVM.botAnswering {
                            botTalking()
                        }
                        
                        Spacer()
                    }
                }
            }
            .padding(.top, 5) // space for toolbar
        } else {
            Spacer()
            TypingEffect(messageAreaVm: messageAreaVM, botChatVM: botChatVM, dataStore: dataStore) // welcome message
            Spacer()
        }
    }

    
    func botTalking() -> some View {
        TypingEffect(chatId: messageAreaVM.selectedChatId, messageAreaVm: messageAreaVM, botChatVM: botChatVM, dataStore: dataStore, specificText: messageAreaVM.botMessage)
    }
    
    func botMessage(text: String, lastMessage: Bool) -> some View {
        VStack(alignment: .leading) {
            HStack {
                Text(text)
                    .padding(.horizontal, 12)
                    .padding(.trailing, 10)
                    .padding(.vertical, 4)
                    .foregroundStyle(.reversePrimary)
                    .background(GeometryReader { proxy in
                        Color.clear
                            .onAppear {
                                messageAreaVM.textWidth = proxy.size.width
                            }
                    })
                
                Spacer()
            }
            .padding(.horizontal, 10)

            if lastMessage {
                HStack {
                    Button {
                        if let chatIndex = dataStore.user.chats.firstIndex(where: { $0.id == messageAreaVM.selectedChatId! }) {
                            dataStore.user.chats[chatIndex].messages.removeLast()
                            messageAreaVM.botAnswer(systemPrompt: botChatVM.bot.prompt.joined(separator: ". ") + ".", userText: text)
                        }
                    } label: {
                        Image(systemName: "arrow.3.trianglepath")
                    }
                    .foregroundStyle(.gray.opacity(0.75))
                    .padding(.horizontal, 12.5)
                }
                .frame(width: messageAreaVM.textWidth, alignment: .trailing)
            }
        }
    }
    
    func userMessage(text: String) -> some View {
        HStack {
            Spacer()
            
            Text(text)
                .padding(.horizontal, 20)
                .padding(.vertical, 15)
                .foregroundStyle(.reversePrimary)
                .background(
                    RoundedRectangle(cornerRadius: 30)
                        .fill(botChatVM.bot.lightColor)
                )
                .padding(.trailing, 5)
                .padding(.leading, 30)
        }
        .padding(.horizontal, 10)
    }
    
}

#Preview {
    var id = UUID().uuidString
    var dataStore = UserDataStore(user: User(chats: [Chat(
        id: id,
        messages: [
            ChatMessage(sender: "user", text: "WelcomebackAnyquestionstodayeeeeeeeeeeeeeeeeeeeeeeee "),
            ChatMessage(sender: "bot", text: "How do I implement dark mode?eee e e e e e e e e e e")
        ], botName: "ChatGPT", promptName: "", name: "trying test"
    )]))
    var messageAreaVM = MessageAreaViewModel(dataStore: dataStore)
    MessageArea(messageAreaVM: messageAreaVM, dataStore: dataStore, botChatVM: BotChatViewModel(dataStore: dataStore, messageAreaVM: messageAreaVM, bot: Bot.chatGPT))
}
