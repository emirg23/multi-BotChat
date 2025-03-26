
import SwiftUI

struct TypingEffect: View { // CLASS FOR BOT ANSWERING & WELCOMING MESSAGES' ANIMATION
    @State var chatId: String?
    @ObservedObject var messageAreaVm: MessageAreaViewModel
    @ObservedObject var botChatVM: BotChatViewModel
    @ObservedObject var dataStore: UserDataStore
    
    @State var chatChanged = false
    @State private var showingString = ""
    @State private var textPossibilities: [String] = []
    @State var writingDotOpacity = 1.0
    let writingDotSpeed = 0.4
    let typingSpeed = 0.1
    let startWait = 0.5
    let endWait = 1.5
    var specificText: String? = nil
    var size: CGFloat
    @State var typingTimer: DispatchSourceTimer?
    @State var dotTimer: DispatchSourceTimer?
    
    init(chatId: String? = nil, messageAreaVm: MessageAreaViewModel, botChatVM: BotChatViewModel, dataStore: UserDataStore, specificText: String? = nil, textsToPossibilities: [String]? = nil, size: CGFloat = 17) {
        let bot = botChatVM.bot
        let textsToShow = [
            "\(bot.name) is ready!",
            "\(bot.name), ready for your requests.",
            "How can \(bot.name) help you today?",
            "Hello, I'm here to help.",
            "Need assistance? \(bot.name) is here!",
            "\(bot.name) is ready to assist.",
            "How can \(bot.name) assist you today?",
            "Hey! \(bot.name) is here to help.",
            "Ready when you are! \(bot.name) is here.",
            "\(bot.name) is all set to help you out.",
            "\(bot.name) is running. How can I assist?"
        ]
        
        self.chatId = chatId
        self.messageAreaVm = messageAreaVm
        self.botChatVM = botChatVM
        self.dataStore = dataStore
        self._textPossibilities = State(initialValue: textsToPossibilities ?? textsToShow)
        self.specificText = specificText
        self.size = size
    }
    
    var body: some View {
        HStack(spacing: 3) {
            if specificText == nil {
                Text(showingString)
                    .font(.system(size: size, weight: .semibold))
            } else {
                Text(showingString)
                    .padding(.horizontal, 12)
                    .padding(.trailing, 18)
                    .padding(.vertical, 4)
                    .foregroundStyle(.reversePrimary)
            }
            
            if specificText == nil {
                writingDot()
            }
            if specificText != nil {
                Spacer()
            }
        }
        .padding(.leading, specificText != nil ? 10 : 0)
        .onAppear {
            startTyping()
            startDotTimer()
        }
        .onChange(of: messageAreaVm.selectedChatId) {
            if specificText != nil && dataStore.user.chats.map({$0.id}).contains(chatId) {
                if let chatIndex = dataStore.user.chats.firstIndex(where: { $0.id == chatId }) {
                    dataStore.user.chats[chatIndex].messages.append(ChatMessage(sender: "bot", text: specificText!))
                    messageAreaVm.botAnswering = false
                    chatChanged = true
                    dataStore.saveUser()
                }
            }
        }
        .onDisappear() {
            if let chatIndex = dataStore.user.chats.firstIndex(where: { $0.id == chatId }) {
                if dataStore.user.chats[chatIndex].messages.last?.sender != "bot" && specificText != nil && dataStore.user.chats.map({$0.id}).contains(chatId) {
                    
                    dataStore.user.chats[chatIndex].messages.append(ChatMessage(sender: "bot", text: specificText!))
                    messageAreaVm.botAnswering = false
                    chatChanged = true
                    dataStore.saveUser()
                }
            }
            stopTyping()
            stopDotTimer()
        }
    }
    
    func writingDot() -> some View {
        Circle()
            .frame(width: size, height: size)
            .foregroundStyle(.reversePrimary)
            .opacity(writingDotOpacity)
    }
    
    func startDotTimer() {

        dotTimer?.cancel()
        dotTimer = nil

        dotTimer = DispatchSource.makeTimerSource(queue: DispatchQueue.main)
        
        dotTimer?.schedule(deadline: .now(), repeating: writingDotSpeed)
        
        dotTimer?.setEventHandler {
            writingDotOpacity = writingDotOpacity == 1 ? 0 : 1
        }
        
        dotTimer?.resume()
    }

    func stopDotTimer() {
        dotTimer?.cancel()
        dotTimer = nil
    }
    
    func startTyping() {
        let textToShow = specificText ?? textPossibilities.randomElement() ?? "Hello!"
        
        showingString = ""
        typingTimer?.cancel()
        typingTimer = nil
        
        DispatchQueue.main.asyncAfter(deadline: specificText == nil ? .now() + startWait : .now()) {
            var index = 0
            self.typingTimer = DispatchSource.makeTimerSource(queue: DispatchQueue.global(qos: .userInitiated))
            
            self.typingTimer?.schedule(deadline: .now(), repeating: specificText != nil ? typingSpeed / 10 : typingSpeed)
            
            self.typingTimer?.setEventHandler {
                if index < textToShow.count {
                    let char = textToShow[textToShow.index(textToShow.startIndex, offsetBy: index)]
                    DispatchQueue.main.async {
                        showingString.append(char)
                    }
                    index += 1
                } else {
                    self.typingTimer?.cancel()
                    self.typingTimer = nil
                    handleTypingCompletion(textToShow: textToShow)
                }
            }
            
            self.typingTimer?.resume()
        }
    }
    
    func stopTyping() {
        typingTimer?.cancel()
        typingTimer = nil
    }

    private func handleTypingCompletion(textToShow: String) {
        if specificText == nil {
            DispatchQueue.main.asyncAfter(deadline: .now() + endWait) {
                let eraseTimer = DispatchSource.makeTimerSource(queue: DispatchQueue.global(qos: .userInitiated))
                
                eraseTimer.schedule(deadline: .now(), repeating: typingSpeed / 5)
                eraseTimer.setEventHandler {
                    DispatchQueue.main.async {
                        if showingString.isEmpty {
                            eraseTimer.cancel()
                            textPossibilities.removeAll(where: { $0 == textToShow })
                            startTyping()
                            textPossibilities.append(textToShow)
                        } else {
                            showingString.removeLast()
                        }
                    }
                }
                
                eraseTimer.resume()
            }
        } else if !chatChanged && dataStore.user.chats.map({ $0.id }).contains(chatId) {
            DispatchQueue.main.async {
                if let chatIndex = dataStore.user.chats.firstIndex(where: { $0.id == chatId }) {
                    dataStore.user.chats[chatIndex].messages.append(ChatMessage(sender: "bot", text: specificText!))
                    dataStore.saveUser()
                }
                messageAreaVm.botAnswering = false
            }
        }
    }

}

#Preview {
    var dataStore = UserDataStore(user: User(chats: []))
    var messageAreaVM = MessageAreaViewModel(dataStore: dataStore)
    var id = UUID().uuidString
    TypingEffect(messageAreaVm: messageAreaVM, botChatVM: BotChatViewModel(dataStore: dataStore, messageAreaVM: messageAreaVM, bot: Bot.chatGPT), dataStore: dataStore)
}
