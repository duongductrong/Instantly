import SwiftUI

enum DesignTokens {
    // Corner radii
    static let panelCornerRadius: CGFloat = 24
    static let pillCornerRadius: CGFloat = pillSize / 2

    // Sizes
    static let pillSize: CGFloat = 48
    static let pillWidth: CGFloat = pillSize
    static let pillHeight: CGFloat = pillSize
    static let expandedWidth: CGFloat = 480
    static let expandedToggledWidth: CGFloat = 920
    static let expandedHeight: CGFloat = 520

    /// Layout
    static let bottomMargin: CGFloat = 20

    // Animation
    static let morphSpringResponse: Double = 0.45
    static let morphSpringDamping: Double = 0.78
    static let slideUpDuration: Double = 0.38
    static let slideDownDuration: Double = 0.28
    static let contentFadeDelay: Double = 0.25
    static let contentFadeDuration: Double = 0.18
    static let collapseContentDuration: Double = 0.12

    // Quick Toolbar (CMD+E)
    static let toolbarWidth: CGFloat = 240
    static let toolbarRowHeight: CGFloat = 36
    static let toolbarCornerRadius: CGFloat = 12
    static let toolbarShadowRadius: CGFloat = 16
    static let toolbarVerticalOffset: CGFloat = 8
}
