
import SwiftUI
import Firebase
import FirebaseAuth

struct RegisterOrLogin: View {
    @ObservedObject var botChatVM: BotChatViewModel
    @ObservedObject var messageAreaVM: MessageAreaViewModel
    @ObservedObject var dataStore: UserDataStore
    
    @State var isVisible = false
    @State var registering = false
    var body: some View {
        ZStack {
            if isVisible {
                Color.black.opacity(0.75)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            dataStore.registerOrLoginPresent = false
                        }
                    }
                
                if registering {
                    RegisterView(registering: $registering, dataStore: dataStore)
                } else {
                    LogInView(registering: $registering, dataStore: dataStore)
                }
            }
        }
        .onChange(of: dataStore.registerOrLoginPresent) {
            withAnimation(.easeInOut(duration: 0.2)) {
                isVisible = dataStore.registerOrLoginPresent
            }
        }
    }
}

#Preview {
    var dataStore = UserDataStore(user: User(chats: []))
    var messageAreaVM = MessageAreaViewModel(dataStore: dataStore)
    
    RegisterOrLogin(botChatVM: BotChatViewModel(dataStore: dataStore, messageAreaVM: messageAreaVM, bot: Bot.chatGPT), messageAreaVM: messageAreaVM, dataStore: dataStore)
}

struct RegisterView: View {
    @Binding var registering: Bool
    @ObservedObject var dataStore: UserDataStore
    @State var emailEntered = false
    @State var email = ""
    @State var password = ""
    @State var passwordAgain = ""
    @State var infoText = ""
    @State var buttonLoading = false
    @State var buttonFailed = false
    @State var buttonSucceed = false
    
    var emailValid: Bool {
        let emailRegex = #"^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$"#
        return NSPredicate(format: "SELF MATCHES[c] %@", emailRegex).evaluate(with: email)
    }
    var passwordValid: Bool {
        let passwordRegex = #"^(?!.*[\s"'\`\\]).{6,}$"#
        let isPasswordValid = NSPredicate(format: "SELF MATCHES %@", passwordRegex).evaluate(with: password)
        
        return (!emailEntered || isPasswordValid) && password == passwordAgain
    }
    
    var body: some View {
        VStack {
            Text(infoText)
                .padding(.top, 15)
                .foregroundStyle(.red.opacity(0.9))
                .font(.system(size: 17, weight: .semibold))
            
            Spacer()
            VStack(spacing: 40){
                textFieldArea()
                
                theButton()
                
                registeringChanger()
                    .padding(.bottom, 30)
            }
            
        }
        .frame(width: UIScreen.main.bounds.width * 0.8, height: 360)
        .background(.backgroundCl)
        .cornerRadius(10)
        .shadow(color: .gray.opacity(0.75), radius: 1.5)
    }
    
    func textFieldArea() -> some View {
        VStack(spacing: 20){
            TextField("Email address", text: $email)
                .padding(5)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(.clear)
                        .stroke(.green, lineWidth: 0.5)
                )
                .opacity(emailEntered ? 0.5 : 1)
                .padding(.horizontal)
            
            if emailEntered {
                SecureField("Password", text: $password)
                    .padding(5)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(.clear)
                            .stroke(.green, lineWidth: 0.5)
                    )
                    .padding(.horizontal)
                    .onChange(of: email) {
                        withAnimation(.bouncy(duration: 0.2)) {
                            emailEntered = false
                        }
                    }
                
                SecureField("Password again", text: $passwordAgain)
                    .padding(5)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(.clear)
                            .stroke(.green, lineWidth: 0.5)
                    )
                    .padding(.horizontal)
            }
        }
        .disabled(buttonLoading)
    }
    
    func theButton() -> some View {
        Button {
            if emailEntered {
                register()
            } else {
                verifyEmail()
            }
        } label: {
            Spacer()
            if buttonSucceed {
                Image(systemName: "checkmark")
            } else if buttonFailed {
                Image(systemName: "xmark")
            } else if buttonLoading {
                ProgressView()
                    .tint(.white)
            } else {
                Text("Continue")
            }
            Spacer()
        }
        .font(.system(size: 17, weight: .semibold))
        .foregroundStyle(.white)
        .padding(.vertical, 10)
        .background(buttonFailed ? .red : .green)
        .cornerRadius(10)
        .padding(.horizontal, 40)
        .disabled(buttonLoading || buttonSucceed || buttonFailed || !emailValid || !passwordValid)
        .opacity(emailValid && passwordValid ? 1 : 0.5)
        .animation(.easeInOut(duration: 0.2), value: emailValid)
        .animation(.easeInOut(duration: 0.2), value: passwordValid)
    }
    
    func register() {
        buttonLoading = true
        
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            DispatchQueue.main.async {
                if let error = error as NSError? {
                    let errorMessage = getAuthErrorMessage(error)
                    buttonFail(fail: errorMessage)
                } else {
                    Auth.auth().signIn(withEmail: email, password: password) { result, error in

                        DispatchQueue.main.async {
                            if let error = error as NSError? {
                                let errorMessage = getAuthErrorMessage(error)
                                buttonFail(fail: errorMessage)
                            } else {
                                dataStore.user.email = email
                                Firestore.firestore().collection("users").document(email.lowercased()).setData(["active":true]
                                )
                                dataStore.updateFirebaseUser() { _ in
                                    dataStore.initFirebaseUser() { _ in
                                        buttonSuccess()
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    func getAuthErrorMessage(_ error: NSError) -> String {
        switch error.code {
        default:
            return "Registration failed. Try again."
        }
    }
    
    func verifyEmail() {
        buttonLoading = true
        dataStore.fetchAllEmails() { emails in
            if emails.map( {$0.lowercased()} ).contains(email.lowercased()) {
                buttonFail(fail: "Email already registered.")
            } else {
                withAnimation(.bouncy(duration: 0.5)) {
                    emailEntered = true
                    buttonLoading = false
                }
            }
        }
    }
    
    
    func buttonFail(fail: String) {
        withAnimation(.bouncy(duration: 0.5)) {
            infoText = fail
            buttonLoading = false
            buttonFailed = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation(.bouncy(duration: 0.5)) {
                buttonFailed = false
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            withAnimation(.bouncy(duration: 0.5)) {
                infoText = ""
            }
        }
    }
    
    func buttonSuccess() {
        withAnimation(.bouncy(duration: 0.5)) {
            buttonLoading = false
            buttonSucceed = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation(.bouncy(duration: 0.5)) {
                dataStore.objectWillChange.send()
                dataStore.registerOrLoginPresent = false
                buttonSucceed = false
            }
        }
    }
    
    func registeringChanger() -> some View {
        HStack {
            Text("Already have an account?")
            Button {
                withAnimation(.spring(duration: 0.2)) {
                    registering = false
                }
            } label: {
                Text("Log In")
            }
        }

    }
}

struct LogInView: View {
    @Binding var registering: Bool
    @ObservedObject var dataStore: UserDataStore
    @State var emailEntered = false
    @State var email = ""
    @State var password = ""
    @State var infoText = ""
    @State var buttonLoading = false
    @State var buttonFailed = false
    @State var buttonSucceed = false
    
    var emailValid: Bool {
        let emailRegex = #"^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$"#
        return NSPredicate(format: "SELF MATCHES[c] %@", emailRegex).evaluate(with: email)
    }
    var passwordValid: Bool {
        let passwordRegex = #"^(?!.*[\s"'\`\\]).{6,}$"#
        let isPasswordValid = NSPredicate(format: "SELF MATCHES %@", passwordRegex).evaluate(with: password)
        
        return !emailEntered || isPasswordValid
    }
    
    var body: some View {
        VStack {
            Text(infoText)
                .padding(.top, 15)
                .foregroundStyle(.red.opacity(0.9))
                .font(.system(size: 17, weight: .semibold))
            
            Spacer()
            VStack(spacing: 40){
                textFieldArea()
                
                theButton()
                
                registeringChanger()
                    .padding(.bottom, 30)
            }
            
        }
        .frame(width: UIScreen.main.bounds.width * 0.8, height: 310)
        .background(.backgroundCl)
        .cornerRadius(10)
        .shadow(color: .gray.opacity(0.75), radius: 1.5)
    }
    
    
    func textFieldArea() -> some View {
        VStack(spacing: 20){
            TextField("Email address", text: $email)
                .padding(5)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(.clear)
                        .stroke(.green, lineWidth: 0.5)
                )
                .opacity(emailEntered ? 0.5 : 1)
                .padding(.horizontal)
            
            if emailEntered {
                SecureField("Password", text: $password)
                    .padding(5)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(.clear)
                            .stroke(.green, lineWidth: 0.5)
                    )
                    .padding(.horizontal)
                    .onChange(of: email) {
                        withAnimation(.bouncy(duration: 0.2)) {
                            emailEntered = false
                        }
                    }
            }
        }
        .disabled(buttonLoading)
    }
    
    func theButton() -> some View {
        Button {
            if emailEntered {
                login()
            } else {
                verifyEmail()
            }
        } label: {
            Spacer()
            if buttonSucceed {
                Image(systemName: "checkmark")
            } else if buttonFailed {
                Image(systemName: "xmark")
            } else if buttonLoading {
                ProgressView()
                    .tint(.white)
            } else {
                Text("Continue")
            }
            Spacer()
        }
        .font(.system(size:17, weight: .semibold))
        .foregroundStyle(.white)
        .padding(.vertical, 10)
        .background(buttonFailed ? .red : .green)
        .cornerRadius(10)
        .padding(.horizontal, 40)
        .disabled(buttonLoading || buttonSucceed || buttonFailed || !emailValid || !passwordValid)
        .opacity(emailValid && passwordValid ? 1 : 0.5)
        .animation(.easeInOut(duration: 0.2), value: emailValid)
        .animation(.easeInOut(duration: 0.2), value: passwordValid)
    }

    func login() {
        buttonLoading = true
        
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            DispatchQueue.main.async {
                if let error = error as NSError? {
                    let errorMessage = getAuthErrorMessage(error)
                    buttonFail(fail: errorMessage)
                } else {
                    dataStore.user.email = email
                    dataStore.initFirebaseUser() { _ in
                        buttonSuccess()
                    }
                }
            }
        }
    }
    
    func getAuthErrorMessage(_ error: NSError) -> String {
        switch error.code {
        default:
            return "Login failed. Try again."
        }
    }
    
    func verifyEmail() {
        buttonLoading = true
        
        dataStore.fetchAllEmails() { emails in
            if emails.map( {$0.lowercased()} ).contains(email.lowercased()) {
                withAnimation(.bouncy(duration: 0.5)) {
                    emailEntered = true
                    buttonLoading = false
                }
            } else {
                buttonFail(fail: "This email is not registered.")
            }
        }
    }
    
    
    func buttonFail(fail: String) {
        withAnimation(.bouncy(duration: 0.5)) {
            infoText = fail
            buttonLoading = false
            buttonFailed = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation(.bouncy(duration: 0.5)) {
                buttonFailed = false
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            withAnimation(.bouncy(duration: 0.5)) {
                infoText = ""
            }
        }
    }
    
    func buttonSuccess() {
        withAnimation(.bouncy(duration: 0.5)) {
            buttonLoading = false
            buttonSucceed = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation(.bouncy(duration: 0.5)) {
                dataStore.objectWillChange.send()
                dataStore.registerOrLoginPresent = false
                buttonSucceed = false
            }
        }
    }
    
    func registeringChanger() -> some View {
        HStack {
            Text("Don't have an account?")
            Button {
                withAnimation(.spring(duration: 0.2)) {
                    registering = true
                }
            } label: {
                Text("Register")
            }
        }
    }
}
