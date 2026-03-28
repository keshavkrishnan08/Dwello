import SwiftUI

struct GradientBackground: View {
    var body: some View {
        LinearGradient(
            colors: [.hbBackground, .hbBackgroundEnd],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}

struct ScreenTemplate<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ZStack {
            GradientBackground()
            ScrollView(showsIndicators: false) {
                content
                    .padding(.horizontal, HBSpacing.lg)
            }
        }
    }
}
