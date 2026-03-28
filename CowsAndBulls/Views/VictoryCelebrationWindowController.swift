//
//  VictoryCelebrationWindowController.swift
//  CowsAndBulls
//
//  Created by OpenAI Codex.
//

import AppKit

enum CelebrationDirection {
    case leftToRight
    case rightToLeft
}

struct CelebrationTrajectory {
    static let startYRange: ClosedRange<CGFloat> = 0.72...0.94
    static let endYRange: ClosedRange<CGFloat> = 0.08...0.28

    let panelSize: CGSize
    let centerPoint: CGPoint
    let cowSize: CGFloat
    let direction: CelebrationDirection
    let startYRatio: CGFloat
    let endYRatio: CGFloat

    var startY: CGFloat { panelSize.height * startYRatio }
    var endY: CGFloat { panelSize.height * endYRatio }
    let enterMargin: CGFloat = 0.7   // enter from fully outside
    let exitMargin: CGFloat  = 0.45  // exit from partially visible state

    var startX: CGFloat {
        switch direction {
        case .leftToRight:
            return -cowSize * enterMargin
        case .rightToLeft:
            return panelSize.width + cowSize * enterMargin
        }
    }

    var endX: CGFloat {
        switch direction {
        case .leftToRight:
            return panelSize.width + cowSize * exitMargin
        case .rightToLeft:
            return -cowSize * exitMargin
        }
    }

    init(
        panelSize: CGSize,
        centerPoint: CGPoint,
        cowSize: CGFloat,
        direction: CelebrationDirection,
        startYRatio: CGFloat,
        endYRatio: CGFloat
    ) {
        self.panelSize = panelSize
        self.centerPoint = centerPoint
        self.cowSize = cowSize
        self.direction = direction
        self.startYRatio = startYRatio
        self.endYRatio = endYRatio
    }

    static func random<R: RandomNumberGenerator>(
        panelSize: CGSize,
        centerPoint: CGPoint,
        cowSize: CGFloat,
        using generator: inout R
    ) -> CelebrationTrajectory {
        let direction: CelebrationDirection = Bool.random(using: &generator) ? .leftToRight : .rightToLeft
        let startYRatio = CGFloat.random(in: startYRange, using: &generator)
        let endYRatio = CGFloat.random(in: endYRange, using: &generator)
        return CelebrationTrajectory(
            panelSize: panelSize,
            centerPoint: centerPoint,
            cowSize: cowSize,
            direction: direction,
            startYRatio: startYRatio,
            endYRatio: endYRatio
        )
    }

    func position(for progress: CGFloat, centerProgress: CGFloat) -> CGPoint {
        let x: CGFloat
        if progress <= centerProgress {
            let localProgress = progress / max(centerProgress, 0.001)
            x = startX + (centerPoint.x - startX) * localProgress
        } else {
            let localProgress = (progress - centerProgress) / max(1 - centerProgress, 0.001)
            x = centerPoint.x + (endX - centerPoint.x) * localProgress
        }

        let y: CGFloat
        if progress <= centerProgress {
            let localProgress = progress / max(centerProgress, 0.001)
            y = startY + (centerPoint.y - startY) * localProgress
        } else {
            let localProgress = (progress - centerProgress) / max(1 - centerProgress, 0.001)
            y = centerPoint.y + (endY - centerPoint.y) * localProgress
        }

        return CGPoint(x: x, y: y)
    }
}

@MainActor
final class VictoryCelebrationWindowController {
    static let shared = VictoryCelebrationWindowController()
    // When the cow reaches the middle milestone, the win alert is shown.
    static let alertTriggerDuration: TimeInterval = 2.2
    // The full screen-level celebration keeps running a bit longer than the alert trigger.
    static let fullAnimationDuration: TimeInterval = 4.5
    private static let cowAssetSets: [[String]] = [
        [
            "Walking Cow Black - Frame 1",
            "Walking Cow Black - Frame 2",
            "Walking Cow Black - Frame 3",
            "Walking Cow Black - Frame 4",
        ],
        [
            "Walking Cow Purple - Frame 1",
            "Walking Cow Purple - Frame 2",
            "Walking Cow Purple - Frame 3",
            "Walking Cow Purple - Frame 4",
        ],
        [
            "Walking Cow Yellow - Frame 1",
            "Walking Cow Yellow - Frame 2",
            "Walking Cow Yellow - Frame 3",
            "Walking Cow Yellow - Frame 4",
        ],
    ]

    private var panel: NSPanel?
    private var alertTask: Task<Void, Never>?
    private var dismissTask: Task<Void, Never>?

    private init() {}

    func present(from window: NSWindow?, onReachedCenter: @escaping @MainActor () -> Void) {
        // Start from a clean state so repeated wins cannot leave an old panel around.
        dismiss()

        guard let screen = window?.screen ?? NSScreen.main else {
            onReachedCenter()
            return
        }

        // We animate in screen coordinates, but the "show alert now" milestone should line up
        // with the center of the actual game content, not the screen center.
        let centerPoint = targetPointInScreenSpace(for: window, screen: screen)
        let localCenterPoint = CGPoint(
            x: centerPoint.x - screen.frame.origin.x,
            y: centerPoint.y - screen.frame.origin.y
        )

        // A transparent borderless panel lets the celebration float above the app window
        // without disturbing the existing SwiftUI view hierarchy.
        let panel = NSPanel(
            contentRect: screen.frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false
        panel.ignoresMouseEvents = true
        panel.level = .statusBar
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]
        panel.isReleasedWhenClosed = false
        panel.hidesOnDeactivate = false

        let selectedAssetSet = Self.cowAssetSets.randomElement() ?? Self.cowAssetSets[0]
        let celebrationController = VictoryCelebrationViewController(
            panelSize: screen.frame.size,
            centerPoint: localCenterPoint,
            assetNames: selectedAssetSet
        )
        panel.contentViewController = celebrationController
        panel.setFrame(screen.frame, display: true)
        panel.orderFrontRegardless()

        self.panel = panel
        alertTask = Task {
            // The alert appears mid-flight; the panel itself stays alive independently.
            try? await Task.sleep(for: .seconds(Self.alertTriggerDuration))
            guard Task.isCancelled == false else { return }
            await MainActor.run {
                onReachedCenter()
            }
        }
        dismissTask = Task {
            // Even if the user never interacts with the alert, the celebration should not
            // stay on screen forever.
            try? await Task.sleep(for: .seconds(Self.fullAnimationDuration))
            guard Task.isCancelled == false else { return }
            await MainActor.run {
                self.dismiss()
            }
        }
    }

    func dismiss(animated: Bool = true) {
        alertTask?.cancel()
        alertTask = nil
        dismissTask?.cancel()
        dismissTask = nil

        guard let panel else { return }

        let closePanel = {
            panel.orderOut(nil)
            panel.contentViewController = nil
            if self.panel === panel {
                self.panel = nil
            }
        }

        guard animated else {
            closePanel()
            return
        }

        NSAnimationContext.runAnimationGroup { context in
            // A short fade looks better than an instant disappearance when the alert closes it.
            context.duration = 0.18
            panel.animator().alphaValue = 0
        } completionHandler: {
            panel.alphaValue = 1
            closePanel()
        }
    }

    private func targetPointInScreenSpace(for window: NSWindow?, screen: NSScreen) -> CGPoint {
        guard
            let window,
            let contentView = window.contentView
        else {
            // Fallback only used if the source window is unavailable.
            return CGPoint(x: screen.frame.midX, y: screen.frame.midY)
        }

        // Convert the game content's visual center from content-view space -> window space
        // -> global screen space, so the celebration can align with the actual app window.
        let contentCenter = CGPoint(
            x: contentView.bounds.midX + 40,
            y: contentView.bounds.midY - 30
        )
        let centerInWindow = contentView.convert(contentCenter, to: nil)
        return window.convertPoint(toScreen: centerInWindow)
    }
}

private final class VictoryCelebrationViewController: NSViewController {
    private let panelSize: CGSize
    private let centerPoint: CGPoint
    private let assetNames: [String]
    private let cowView = AccessibilityView()
    private let trajectory: CelebrationTrajectory
    // Sublayer that holds the image frames and the horizontal flip transform.
    // Keeping it separate from cowView.layer means the CAKeyframeAnimation that
    // drives position is never affected by the scale(-1,1,1) flip.
    private var imageLayer: CALayer?

    init(panelSize: CGSize, centerPoint: CGPoint, assetNames: [String]) {
        self.panelSize = panelSize
        self.centerPoint = centerPoint
        self.assetNames = assetNames
        let cowSize = min(max(panelSize.width * 0.14, 160), 230)
        var generator = SystemRandomNumberGenerator()
        self.trajectory = CelebrationTrajectory.random(
            panelSize: panelSize,
            centerPoint: centerPoint,
            cowSize: cowSize,
            using: &generator
        )
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        let rootView = AccessibilityView(frame: CGRect(origin: .zero, size: panelSize))
        rootView.wantsLayer = true
        rootView.layer?.backgroundColor = NSColor.clear.cgColor
        rootView.setAccessibilityIdentifier("victoryCelebrationScene")
        self.view = rootView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureImageView()
        startAnimations()
    }

    private func configureImageView() {
        let cowSize = trajectory.cowSize

        // cowView.layer is responsible ONLY for position animation.
        // It must have no transform of its own so the CAKeyframeAnimation
        // path is applied cleanly in the superlayer's coordinate space.
        cowView.frame = CGRect(x: 0, y: 0, width: cowSize, height: cowSize)
        cowView.wantsLayer = true
        cowView.layer?.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        cowView.layer?.position = startPoint()
        // No transform on the outer layer.
        cowView.setAccessibilityIdentifier("victoryCelebrationCow")
        view.addSubview(cowView)

        // imageLayer sits inside cowView.layer and owns the visual appearance:
        // image contents, shadow, and the horizontal flip for rightToLeft runs.
        let imgLayer = CALayer()
        imgLayer.frame = CGRect(origin: .zero, size: CGSize(width: cowSize, height: cowSize))
        imgLayer.contentsGravity = .resizeAspect
        imgLayer.contents = NSImage(named: assetNames[0])?.cgImage(forProposedRect: nil, context: nil, hints: nil)
        imgLayer.shadowColor = NSColor.black.withAlphaComponent(0.18).cgColor
        imgLayer.shadowOpacity = 1
        imgLayer.shadowRadius = 10
        imgLayer.shadowOffset = CGSize(width: 0, height: -6)

        if trajectory.direction == .rightToLeft {
            imgLayer.transform = CATransform3DMakeScale(-1, 1, 1)
        }

        cowView.layer?.addSublayer(imgLayer)
        imageLayer = imgLayer
    }

    private func startAnimations() {
        guard let positionLayer = cowView.layer, let imgLayer = imageLayer else { return }

        // Position animation targets the outer layer (no transform = no interference).
        let motion = CAKeyframeAnimation(keyPath: "position")
        motion.path = animationPath()
        motion.duration = VictoryCelebrationWindowController.fullAnimationDuration
        motion.timingFunction = CAMediaTimingFunction(name: .linear)
        motion.isRemovedOnCompletion = false
        motion.fillMode = .forwards
        positionLayer.add(motion, forKey: "victoryCowPosition")

        // Frame animation targets the inner image layer.
        let images = assetNames.compactMap { name in
            NSImage(named: name)?.cgImage(forProposedRect: nil, context: nil, hints: nil)
        }
        guard images.isEmpty == false else { return }

        let frameAnimation = CAKeyframeAnimation(keyPath: "contents")
        frameAnimation.values = images
        frameAnimation.calculationMode = .discrete
        frameAnimation.duration = 0.4
        frameAnimation.repeatDuration = VictoryCelebrationWindowController.fullAnimationDuration
        frameAnimation.isRemovedOnCompletion = false
        frameAnimation.fillMode = .forwards
        imgLayer.contents = images[0]
        imgLayer.add(frameAnimation, forKey: "victoryCowFrames")
    }

    private func startPoint() -> CGPoint {
        CGPoint(x: trajectory.startX, y: flippedY(trajectory.startY))
    }

    private func animationPath() -> CGMutablePath {
        let path = CGMutablePath()
        let sampleCount = 120

        for step in 0...sampleCount {
            let progress = CGFloat(step) / CGFloat(sampleCount)
            let point = position(for: progress)
            if step == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }

        return path
    }

    private func position(for progress: CGFloat) -> CGPoint {
        let diagonalPoint = trajectory.position(for: progress, centerProgress: centerProgress)
        let arcLift = sin(progress * .pi) * panelSize.height * 0.18
        let bob = sin(progress * .pi * 8) * 6
        let y = diagonalPoint.y - arcLift + bob

        return CGPoint(x: diagonalPoint.x, y: flippedY(y))
    }

    private var centerProgress: CGFloat {
        CGFloat(
            min(
                max(
                    VictoryCelebrationWindowController.alertTriggerDuration
                        / VictoryCelebrationWindowController.fullAnimationDuration,
                    0
                ),
                1
            )
        )
    }

    private func flippedY(_ y: CGFloat) -> CGFloat {
        panelSize.height - y
    }
}

private final class AccessibilityView: NSView {
    override func isAccessibilityElement() -> Bool {
        true
    }
}
