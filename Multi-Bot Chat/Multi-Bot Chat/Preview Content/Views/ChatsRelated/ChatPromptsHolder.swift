
import SwiftUI

struct ChatPromptsHolder: View {
    @State var bot: Bot
    @Binding var creatingNewPrompt: Bot?
    @ObservedObject var dataStore: UserDataStore
    @Binding var presentingPrompts: [Bool]
    
    var index: Int {
        Bot.allBots.firstIndex(of: bot)!
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                Button {
                    withAnimation(.bouncy(duration: 0.3)) {
                        if !presentingPrompts[index] {
                            presentingPrompts = Array(repeating: false, count: Bot.allBots.count)
                            presentingPrompts[index] = true
                        } else {
                            presentingPrompts[index] = false
                        }
                    }
                } label: {
                    HStack {
                        bot.logo(size: 50)
                            .background(bot.lightColor)
                            .cornerRadius(25)
                        Text(bot.name)
                        Spacer()
                        
                        Image(systemName: "chevron.down")
                            .rotationEffect(Angle(degrees: presentingPrompts[index] ? 180 : 0))
                            .padding(.trailing, 10)
                            .font(.system(size: 20))
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                    .background(.backgroundCl)
                    .foregroundStyle(Color.reversePrimary)

                }
                
                if presentingPrompts[index] {
                    ForEach(Bot.allBots.filter { $0.name == bot.name }) { prompt in
                        if let indexOfBot = Bot.allBots.firstIndex(where: { $0.id == prompt.id }) {
                            ChatItem(dataStore: dataStore, bot: prompt)
                        }
                    }
                    addAPrompt()
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .background(.backgroundCl)
        }
    }
    
    func addAPrompt() -> some View{
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                creatingNewPrompt = bot
            }
        } label: {
            HStack {
                bot.logo(size: 50)
                    .background(bot.lightColor)
                    .cornerRadius(25)
                Spacer()
                Text("Create a prompt")
                Spacer()
                Image(systemName: "plus")
            }
            .padding(.horizontal)
            .padding(.vertical, 5)
            .background(bot.darkColor.opacity(0.1))
            .foregroundStyle(Color.reversePrimary.opacity(0.7))
        }
    }
}

#Preview {
    var dataStore = UserDataStore(user: User.userDef)
    ChatPromptsHolder(bot: Bot.chatGPT, creatingNewPrompt: .constant(nil), dataStore: dataStore, presentingPrompts: .constant([true]))
}


struct ChatItem: View {
    @ObservedObject var dataStore: UserDataStore
    @StateObject var botChatVM: BotChatViewModel
    @StateObject var messageAreaVM: MessageAreaViewModel
    
    init(dataStore: UserDataStore, bot: Bot) {
        self.dataStore = dataStore
        
        let messageArea = MessageAreaViewModel(dataStore: dataStore)
        
        _messageAreaVM = StateObject(wrappedValue: messageArea)
        _botChatVM = StateObject(wrappedValue: BotChatViewModel(dataStore: dataStore, messageAreaVM: messageArea, bot: bot))
    }
    
    @State var navigate = false
    @State private var dragOffset: CGFloat = 0
    @State private var dragAmount: CGFloat = 0
    var chatNumber: Int {
        dataStore.user.chats
            .filter ({ $0.botName == botChatVM.bot.name && $0.promptName == botChatVM.bot.promptName})
            .count
    }

    var body: some View {
        ZStack {
            HStack {
                Button {
                    print("deleting")
                    withAnimation(.easeInOut(duration: 0.2)) {
                        dataStore.objectWillChange.send()
                        Bot.allBots.removeAll(where: { $0.id == botChatVM.bot.id})
                        dataStore.saveUser()
                    }
                } label: {
                    Image("DeleteButton")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: dragAmount, height: 60, alignment: .leading)
                        .clipped()
                        .opacity(0.75)
                        .background(
                            ZStack {
                                botChatVM.bot.darkColor.opacity(0.1)
                            }
                        )
                }
                Spacer()
            }

            Button {
                if dragAmount > 40 {
                    withAnimation(.spring(duration: 0.25)) {
                        dragAmount = 0
                        dragOffset = 0
                    }
                } else {
                    navigate = true
                }
            } label: {
                HStack {
                    botChatVM.bot.logo(size: 50)
                        .background(botChatVM.bot.lightColor)
                        .cornerRadius(25)
                    Spacer()
                    if botChatVM.bot.promptName == "" {
                        Text(String(chatNumber))
                    } else {
                        Text(botChatVM.bot.promptName)
                    }
                    Image(systemName: "chevron.right")
                }
                .padding(.horizontal)
                .padding(.vertical, 5)
                .background(botChatVM.bot.darkColor.opacity(0.1))
                .foregroundStyle(Color.reversePrimary.opacity(0.7))
            }
            .offset(x: dragAmount)
            .highPriorityGesture( // has to be dragamount >= 0
                DragGesture()
                    .onChanged { value in
                        if botChatVM.bot.promptName != "" {
                            withAnimation(.spring(duration: 0.15)) {
                                dragAmount = min(70, max(0, value.translation.width + dragOffset))
                            }
                        }
                    }
                    .onEnded { value in
                        withAnimation(.spring(duration: 0.15)) {
                            if dragAmount > 40 {
                                dragAmount = 60
                            } else {
                                dragAmount = 0
                            }
                        }
                        dragOffset = dragAmount
                    }
            )
            .onDisappear() {
                dragAmount = 0
                dragOffset = 0
            }
        }
        NavigationLink(destination: BotChat(botChatVM: botChatVM, messageAreaVM: messageAreaVM, dataStore: dataStore), isActive: $navigate) {
            EmptyView()
        }
    }
}
