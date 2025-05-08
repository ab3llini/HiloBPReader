import SwiftUI

struct SplashScreenView: View {
    @State private var isAnimating = false
    @State private var showMainApp = false
    
    var body: some View {
        ZStack {
            Color.mainBackground.ignoresSafeArea()
            
            VStack(spacing: 20) {
                Image(systemName: "heart.text.square.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.primaryAccent)
                    .scaleEffect(isAnimating ? 1.1 : 0.9)
                    .opacity(isAnimating ? 1.0 : 0.8)
                
                Text("HiloBP Reader")
                    .font(.title)
                    .fontWeight(.bold)
                    .opacity(isAnimating ? 1.0 : 0.0)
                    .offset(y: isAnimating ? 0 : 20)
                
                Text("Monitor your blood pressure")
                    .foregroundColor(.secondary)
                    .opacity(isAnimating ? 1.0 : 0.0)
                    .offset(y: isAnimating ? 0 : 10)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2)) {
                isAnimating = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation {
                    showMainApp = true
                }
            }
        }
        .fullScreenCover(isPresented: $showMainApp) {
            MainView()
        }
    }
}
