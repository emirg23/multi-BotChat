
import SwiftUI

struct RightTabView: View {
    @ObservedObject var botChatVM: BotChatViewModel
    @ObservedObject var messageAreaVM: MessageAreaViewModel
    @ObservedObject var dataStore: UserDataStore
    
    var body: some View {
        ZStack {
            if botChatVM.rightTabPresent {
                Color.black.opacity(0.75)
                    .edgesIgnoringSafeArea(.bottom)
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            botChatVM.rightTabPresent = false
                        }
                    }
            }
            
            HStack(spacing: 0) {
                Spacer()
                if botChatVM.rightTabPresent {
                    VStack(alignment: .leading, spacing: 0) {
                        
                        newChatButton()
                        
                        botChatVM.bot.lightColor
                            .frame(height: 1)
                            .padding(.top)
                        
                        if dataStore.user.chats.first(where: {$0.botName == botChatVM.bot.name}) == nil {
                            placeholderLogo()
                        } else {
                            chatsByLines()
                        }
                        
                        botChatVM.bot.lightColor
                            .frame(height: 1)
                            .padding(.bottom)
                        
                        if dataStore.user.email == nil {
                            registerOrLogin()
                        } else {
                            logOut()
                        }
                        Spacer()
                    }
                    .frame(width: UIScreen.main.bounds.width * 0.5, alignment: .leading)
                    .background(botChatVM.bot.darkColor)
                    .transition(.move(edge: .trailing))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
            
                RegisterOrLogin(botChatVM: botChatVM, messageAreaVM: messageAreaVM, dataStore: dataStore)

        }
        .padding(.top, 5)
        .animation(.easeInOut(duration: 0.2), value: botChatVM.rightTabPresent)
    }
    
    func placeholderLogo() -> some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                VStack {
                    botChatVM.bot.logo(size: 50)
                    Text("Explore with")
                    Text(botChatVM.bot.name)
                }
                .foregroundStyle(.reversePrimary.opacity(0.25))
                Spacer()
            }
            Spacer()
        }
    }
    
    func newChatButton() -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                messageAreaVM.selectedChatId = nil
                botChatVM.rightTabPresent = false
            }
        } label: {
            Image(systemName: "square.and.pencil")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(messageAreaVM.selectedChatId == nil ? .reversePrimary.opacity(0.5) : .reversePrimary)
        }
        .padding(.leading)
    }
    
    func chatsByLines() -> some View {
        var chats: [Chat] {
            dataStore.user.chats.filter( { $0.botName == botChatVM.bot.name && $0.promptName == botChatVM.bot.promptName} )
        }
        
        return ScrollView {
            VStack(alignment: .leading, spacing: 10){
                ForEach(groupChatsByDate(chats), id: \.0) { section in
                    Section(header: Text(section.0)
                        .font(.headline)
                        .padding(.top, 10)) {
                            ForEach(section.1, id: \.self) { chat in
                                RightBarChatLine(chat: chat, botChatVM: botChatVM, messageAreaVM: messageAreaVM, dataStore: dataStore)
                            }
                        }
                }
            }
        }
        .padding(.leading)
    }
    
    func groupChatsByDate(_ chats: [Chat]) -> [(String, [Chat])] {
        let calendar = Calendar.current
        let now = Date()
        
        var todayChats: [Chat] = []
        var yesterdayChats: [Chat] = []
        var last7DaysChats: [Chat] = []
        var olderChats: [Chat] = []
        
        for chat in chats.sorted(by: { $0.lastMessageDate > $1.lastMessageDate}) {
            if calendar.isDateInToday(chat.lastMessageDate) {
                todayChats.append(chat)
            } else if calendar.isDateInYesterday(chat.lastMessageDate) {
                yesterdayChats.append(chat)
            } else if let daysAgo = calendar.dateComponents([.day], from: chat.lastMessageDate, to: now).day, daysAgo <= 7 {
                last7DaysChats.append(chat)
            } else {
                olderChats.append(chat)
            }
        }
        
        var groupedChats: [(String, [Chat])] = []
        if !todayChats.isEmpty { groupedChats.append(("Today", todayChats)) }
        if !yesterdayChats.isEmpty { groupedChats.append(("Yesterday", yesterdayChats)) }
        if !last7DaysChats.isEmpty { groupedChats.append(("Last 7 Days", last7DaysChats)) }
        if !olderChats.isEmpty { groupedChats.append(("More than a week", olderChats)) }
        
        return groupedChats
    }
    
    func registerOrLogin() -> some View {
        HStack {
            Spacer()

            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    dataStore.registerOrLoginPresent = true
                } 
            } label: {
                Text("register/log in")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.reversePrimary)
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .shadow(color: .reversePrimary, radius: 1)
                            .foregroundStyle(botChatVM.bot.darkColor)
                    )
                    .padding(.bottom)
            }
            Spacer()
        }
    }
    
    func logOut() -> some View {
        HStack {
            Spacer()

            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    dataStore.logOut()
                }
            } label: {
                Text("Log out")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.reversePrimary)
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .shadow(color: .red.opacity(0.25), radius: 1)
                            .foregroundColor(Color.red.opacity(0.85))
                    )
                    .padding(.bottom)
            }

            Spacer()
        }
    }
}

#Preview {
    var id = UUID().uuidString
    var id2 = UUID().uuidString
    var dataStore = UserDataStore(user: User(chats: [Chat(id: id, botName: "ChatGPT", promptName: "", name: "try this and try that yeah yeah"), Chat(id: id2, botName: "ChatGPT", promptName: "History", name: "try that")]))
    var messageAreaVM = MessageAreaViewModel(dataStore: dataStore)
    var botChatVM = BotChatViewModel(dataStore: dataStore, messageAreaVM: messageAreaVM, bot: Bot.chatGPT)
    
    
    ZStack {
        Color.white
            .padding(.top, 5)
        RightTabView(botChatVM: botChatVM, messageAreaVM: messageAreaVM, dataStore: dataStore)
    }
    .onAppear() {
        botChatVM.rightTabPresent = true
    }
}


