
import SwiftUI

struct RightBarChatLine: View {
    @State var chat: Chat
    @State var threeDotMenuOpened = false
    @ObservedObject var botChatVM: BotChatViewModel
    @ObservedObject var messageAreaVM: MessageAreaViewModel
    @ObservedObject var dataStore: UserDataStore
    var selected: Bool {
        chat.id == messageAreaVM.selectedChatId
    }
    
    var body: some View {
        VStack(spacing: 2){
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    if selected {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            threeDotMenuOpened.toggle()
                        }
                    } else {
                        messageAreaVM.selectedChatId = chat.id
                        botChatVM.rightTabPresent = false
                    }
                }
            } label: {
                Text(chat.name)
                    .font(.system(size: 16))
                    .foregroundStyle(selected ? .reversePrimary.opacity(0.5) : .reversePrimary.opacity(0.85))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                    .padding(.bottom, 3)
                    .padding(.leading, 3)
                    .padding(.vertical, 3)
                Spacer()
                if selected {
                    Image(systemName: "ellipsis")
                        .foregroundStyle(.reversePrimary)
                        .padding(.trailing, 5)
                }
            }
            .background(selected ? botChatVM.bot.lightColor : .clear)
            .cornerRadius(6)
            
            if threeDotMenuOpened {
                Button {
                    deleteChat()
                } label: {
                    HStack {
                        Image(systemName: "trash.fill")
                            .padding(.leading, 5)
                        Text("Delete chat")
                        Spacer()
                    }
                    .font(.system(size: 15))
                    .foregroundStyle(.red)
                    .padding(5)
                    .background(.reversePrimary.opacity(0.2))
                    .cornerRadius(6)
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }
    
    func deleteChat() {
        messageAreaVM.botAnswering = false
        messageAreaVM.botGenerating = false
        DispatchQueue.main.async {
            let idToDelete = chat.id
            if messageAreaVM.selectedChatId == idToDelete {
                messageAreaVM.selectedChatId = nil
            }
            withAnimation(.easeInOut(duration: 0.2)) {
                dataStore.user.chats.removeAll(where: { $0.id == idToDelete})
                botChatVM.rightTabPresent = false
                dataStore.saveUser()
            }
        }
    }
}

#Preview {
    var dataStore = UserDataStore(user: User.userDef)
    var messageAreaVM = MessageAreaViewModel(dataStore: dataStore)
    RightBarChatLine(chat: Chat(id: UUID().uuidString, botName: "ChatGPT", promptName: "", name: "lelele"), botChatVM: BotChatViewModel(dataStore: dataStore, messageAreaVM: messageAreaVM, bot: Bot.chatGPT), messageAreaVM: messageAreaVM, dataStore: dataStore)
}
