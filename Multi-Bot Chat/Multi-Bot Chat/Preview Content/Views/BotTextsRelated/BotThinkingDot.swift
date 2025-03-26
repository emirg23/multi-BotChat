
import SwiftUI

struct BotThinkingDot: View { // circle animation while waiting for generated answer
    @State var loop = true
    var body: some View {
        HStack {
            Circle()
                .frame(height: loop ? 15 : 12.5)
                .opacity(loop ? 1 : 0.5)
                .onAppear() {
                    Timer.scheduledTimer(withTimeInterval: 0.4, repeats: true) { _ in
                        withAnimation(.easeInOut(duration: 0.4)) {
                            loop.toggle()
                        }
                    }
                }
                .padding(.leading, 12)
                .padding(.vertical, 4)
            Spacer()
        }
    }
}

#Preview {
    BotThinkingDot()
}
