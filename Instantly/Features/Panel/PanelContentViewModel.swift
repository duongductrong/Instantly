import SwiftUI

@Observable
final class PanelContentViewModel {
    var isExpanded = false
    var showContent = false

    func expand() {
        isExpanded = true
        DispatchQueue.main.asyncAfter(deadline: .now() + DesignTokens.contentFadeDelay) {
            withAnimation(.easeIn(duration: DesignTokens.contentFadeDuration)) {
                self.showContent = true
            }
        }
    }

    func collapse() {
        withAnimation(.easeOut(duration: DesignTokens.collapseContentDuration)) {
            showContent = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + DesignTokens.collapseContentDuration) {
            self.isExpanded = false
        }
    }
}
