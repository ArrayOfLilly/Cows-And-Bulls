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
    let enterMargin: CGFloat = 0.7
    let exitMargin: CGFloat  = 0.45

    var startX: CGFloat {
        switch direction {
        case .leftToRight:  return -cowSize * enterMargin
        case .rightToLeft:  return panelSize.width + cowSize * enterMargin
        }
    }

    var endX: CGFloat {
        switch direction {
        case .leftToRight:  return panelSize.width + cowSize * exitMargin
        case .rightToLeft:  return -cowSize * exitMargin
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
        let endYRatio   = CGFloat.random(in: endYRange,   using: &generator)
        return CelebrationTrajectory(
            panelSize: panelSize,
            centerPoint: centerPoint,
            cowSize: cowSize,
            direction: direction,
            startYRatio: startYRatio,
            endYRatio: endYRatio
        )
    }

    // MARK: - Arc-length midpoint

    /// Returns the progress value [0…1] at which the cow has travelled exactly
    /// half of the total arc length of its path (including the sine arc lift and
    /// bobbing). This is used to fire the alert at the true visual midpoint.
    func alertProgress(sampleCount: Int = 240) -> CGFloat {
        var points: [CGPoint] = []
        for step in 0...sampleCount {
            let t = CGFloat(step) / CGFloat(sampleCount)
            points.append(sampledPosition(for: t))
        }

        var lengths: [CGFloat] = [0]
        var total: CGFloat = 0
        for i in 1..<points.count {
            let dx = points[i].x - points[i - 1].x
            let dy = points[i].y - points[i - 1].y
            total += sqrt(dx * dx + dy * dy)
            lengths.append(total)
        }

        let half = total / 2
        for i in 1..<lengths.count {
            if lengths[i] >= half {
                let prev = lengths[i - 1]
                let next = lengths[i]
                let frac = (half - prev) / max(next - prev, 0.001)
                let tPrev = CGFloat(i - 1) / CGFloat(sampleCount)
                let tNext = CGFloat(i)     / CGFloat(sampleCount)
                return tPrev + frac * (tNext - tPrev)
            }
        }
        return 0.5
    }

    /// Position including arc lift and bob — matches what the animation actually draws.
    /// centerProgress is fixed at 0.5 here because the two legs are equal in time;
    /// the arc-length query above finds the geometric midpoint within that uniform motion.
    private func sampledPosition(for progress: CGFloat) -> CGPoint {
        let diag = position(for: progress, centerProgress: 0.5)
        let arcLift = sin(progress * .pi) * panelSize.height * 0.18
        let bob     = sin(progress * .pi * 8) * 6
        // Y is already in Core Animation (non-flipped) space for length purposes.
        return CGPoint(x: diag.x, y: diag.y - arcLift + bob)
    }

    // MARK: - Linear leg interpolation

    func position(for progress: CGFloat, centerProgress: CGFloat) -> CGPoint {
        let x: CGFloat
        if progress <= centerProgress {
            let lp = progress / max(centerProgress, 0.001)
            x = startX + (centerPoint.x - startX) * lp
        } else {
            let lp = (progress - centerProgress) / max(1 - centerProgress, 0.001)
            x = centerPoint.x + (endX - centerPoint.x) * lp
        }

        let y: CGFloat
        if progress <= centerProgress {
            let lp = progress / max(centerProgress, 0.001)
            y = startY + (centerPoint.y - startY) * lp
        } else {
            let lp = (progress - centerProgress) / max(1 - centerProgress, 0.001)
            y = centerPoint.y + (endY - centerPoint.y) * lp
        }

        return CGPoint(x: x, y: y)
    }
}

// MARK: -

@MainActor
final class VictoryCelebrationWindowController {
    static let shared = VictoryCelebrationWindowController()
    static let fullAnimationDuration: TimeInterval = 4.5

    private static let cowAssetSets: [[String]] = [
        ["Walking Cow Black - Frame 1",  "Walking Cow Black - Frame 2",
         "Walking Cow Black - Frame 3",  "Walking Cow Black - Frame 4"],
        ["Walking Cow Purple - Frame 1", "Walking Cow Purple - Frame 2",
         "Walking Cow Purple - Frame 3", "Walking Cow Purple - Frame 4"],
        ["Walking Cow Yellow - Frame 1", "Walking Cow Yellow - Frame 2",
         "Walking Cow Yellow - Frame 3", "Walking Cow Yellow - Frame 4"],
    ]

    private var panel: NSPanel?
    private var alertTask: Task<Void, Never>?
    private var dismissTask: Task<Void, Never>?

    private init() {}

    func present(from window: NSWindow?, onReachedCenter: @escaping @MainActor () -> Void) {
        dismiss()

        guard let screen = window?.screen ?? NSScreen.main else {
            onReachedCenter()
            return
        }

        // The cow's waypoint is the centre of the NSPanel (= full screen).
        // Using the ContentView centre here caused the path to be very short
        // (the app window is small), which made the cow rush through it.
        let panelSize = screen.frame.size
        let panelCenter = CGPoint(x: panelSize.width / 2, y: panelSize.height / 2)

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
            panelSize: panelSize,
            centerPoint: panelCenter,
            assetNames: selectedAssetSet
        )
        panel.contentViewController = celebrationController
        panel.setFrame(screen.frame, display: true)
        panel.orderFrontRegardless()

        self.panel = panel

        let alertTriggerDuration = celebrationController.alertTriggerDuration

        alertTask = Task {
            try? await Task.sleep(for: .seconds(alertTriggerDuration))
            guard !Task.isCancelled else { return }
            await MainActor.run { onReachedCenter() }
        }
        dismissTask = Task {
            try? await Task.sleep(for: .seconds(Self.fullAnimationDuration))
            guard !Task.isCancelled else { return }
            await MainActor.run { self.dismiss() }
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
            if self.panel === panel { self.panel = nil }
        }

        guard animated else { closePanel(); return }

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.18
            panel.animator().alphaValue = 0
        } completionHandler: {
            panel.alphaValue = 1
            closePanel()
        }
    }
}

// MARK: -

private final class VictoryCelebrationViewController: NSViewController {
    private let panelSize: CGSize
    private let centerPoint: CGPoint
    private let assetNames: [String]
    private let cowView = AccessibilityView()
    private let trajectory: CelebrationTrajectory
    private var imageLayer: CALayer?

    /// The time at which the cow reaches the arc-length midpoint of its full path.
    var alertTriggerDuration: TimeInterval {
        TimeInterval(trajectory.alertProgress()) * VictoryCelebrationWindowController.fullAnimationDuration
    }

    /// Split progress used by position(for:centerProgress:) — equals alertProgress
    /// so both legs of the path are walked at the same speed.
    private var centerProgress: CGFloat {
        trajectory.alertProgress()
    }

    init(panelSize: CGSize, centerPoint: CGPoint, assetNames: [String]) {
        self.panelSize   = panelSize
        self.centerPoint = centerPoint
        self.assetNames  = assetNames
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
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

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
        cowView.frame = CGRect(x: 0, y: 0, width: cowSize, height: cowSize)
        cowView.wantsLayer = true
        cowView.layer?.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        cowView.layer?.position = startPoint()
        cowView.setAccessibilityIdentifier("victoryCelebrationCow")
        view.addSubview(cowView)

        let imgLayer = CALayer()
        imgLayer.frame = CGRect(origin: .zero, size: CGSize(width: cowSize, height: cowSize))
        imgLayer.contentsGravity = .resizeAspect
        imgLayer.contents = NSImage(named: assetNames[0])?.cgImage(forProposedRect: nil, context: nil, hints: nil)
        imgLayer.shadowColor   = NSColor.black.withAlphaComponent(0.18).cgColor
        imgLayer.shadowOpacity = 1
        imgLayer.shadowRadius  = 10
        imgLayer.shadowOffset  = CGSize(width: 0, height: -6)

        if trajectory.direction == .rightToLeft {
            imgLayer.transform = CATransform3DMakeScale(-1, 1, 1)
        }

        cowView.layer?.addSublayer(imgLayer)
        imageLayer = imgLayer
    }

    private func startAnimations() {
        guard let positionLayer = cowView.layer, let imgLayer = imageLayer else { return }

        let motion = CAKeyframeAnimation(keyPath: "position")
        motion.path            = animationPath()
        motion.duration        = VictoryCelebrationWindowController.fullAnimationDuration
        motion.timingFunction  = CAMediaTimingFunction(name: .linear)
        motion.isRemovedOnCompletion = false
        motion.fillMode        = .forwards
        positionLayer.add(motion, forKey: "victoryCowPosition")

        let images = assetNames.compactMap { name in
            NSImage(named: name)?.cgImage(forProposedRect: nil, context: nil, hints: nil)
        }
        guard !images.isEmpty else { return }

        let frameAnimation = CAKeyframeAnimation(keyPath: "contents")
        frameAnimation.values        = images
        frameAnimation.calculationMode = .discrete
        frameAnimation.duration      = 0.4
        frameAnimation.repeatDuration = VictoryCelebrationWindowController.fullAnimationDuration
        frameAnimation.isRemovedOnCompletion = false
        frameAnimation.fillMode      = .forwards
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
            if step == 0 { path.move(to: point) } else { path.addLine(to: point) }
        }
        return path
    }

    private func position(for progress: CGFloat) -> CGPoint {
        let diag    = trajectory.position(for: progress, centerProgress: centerProgress)
        let arcLift = sin(progress * .pi) * panelSize.height * 0.18
        let bob     = sin(progress * .pi * 8) * 6
        return CGPoint(x: diag.x, y: flippedY(diag.y - arcLift + bob))
    }

    private func flippedY(_ y: CGFloat) -> CGFloat {
        panelSize.height - y
    }
}

private final class AccessibilityView: NSView {
    override func isAccessibilityElement() -> Bool { true }
}
