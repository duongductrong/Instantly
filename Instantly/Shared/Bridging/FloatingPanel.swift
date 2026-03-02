import AppKit
import SwiftUI

/// NSPanel subclass for non-activating, borderless floating panel with frosted glass support.
class FloatingPanel: NSPanel {
    init(contentView: some View) {
        super.init(
            contentRect: .zero,
            styleMask: [.nonactivatingPanel, .borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        level = .floating
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        isFloatingPanel = true
        hidesOnDeactivate = false
        backgroundColor = .clear
        isOpaque = false
        hasShadow = true

        let hostingView = NSHostingView(rootView: AnyView(contentView.ignoresSafeArea()))
        self.contentView = hostingView
        self.contentView?.wantsLayer = true
        self.contentView?.layer?.cornerRadius = DesignTokens.panelCornerRadius
        self.contentView?.layer?.masksToBounds = true
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override var canBecomeKey: Bool {
        true
    }

    override var canBecomeMain: Bool {
        false
    }

    func updateCornerRadius(_ radius: CGFloat) {
        contentView?.layer?.cornerRadius = radius
    }

    func animateFrame(to rect: NSRect, cornerRadius: CGFloat, duration: TimeInterval) {
        NSAnimationContext.runAnimationGroup { context in
            context.duration = duration
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            self.animator().setFrame(rect, display: true)
        }

        if let layer = contentView?.layer {
            let anim = CABasicAnimation(keyPath: "cornerRadius")
            anim.fromValue = layer.cornerRadius
            anim.toValue = cornerRadius
            anim.duration = duration
            layer.add(anim, forKey: "cornerRadius")
            layer.cornerRadius = cornerRadius
        }
    }
}
