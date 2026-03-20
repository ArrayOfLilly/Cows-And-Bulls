//
//  VictoryCelebrationWindowController.swift
//  CowsAndBulls
//
//  Created by OpenAI Codex.
//

import SwiftUI
import AppKit

@MainActor
final class VictoryCelebrationWindowController {
    static let shared = VictoryCelebrationWindowController()
    static let alertTriggerDuration: TimeInterval = 2.2
    static let fullAnimationDuration: TimeInterval = 3.8

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

        let centerPoint = targetPointInScreenSpace(for: window, screen: screen)
        let localCenterPoint = CGPoint(
            x: centerPoint.x - screen.frame.origin.x,
            y: centerPoint.y - screen.frame.origin.y
        )

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

        let rootView = VictoryCelebrationScene(centerPoint: localCenterPoint)
        let hostingController = NSHostingController(rootView: rootView)
        hostingController.view.wantsLayer = true
        hostingController.view.layer?.backgroundColor = NSColor.clear.cgColor
        panel.contentViewController = hostingController
        panel.setFrame(screen.frame, display: true)
        panel.orderFrontRegardless()

        self.panel = panel
        alertTask = Task {
            try? await Task.sleep(for: .seconds(Self.alertTriggerDuration))
            guard Task.isCancelled == false else { return }
            await MainActor.run {
                onReachedCenter()
            }
        }
        dismissTask = Task {
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
            return CGPoint(x: screen.frame.midX, y: screen.frame.midY)
        }

        let contentCenter = CGPoint(x: contentView.bounds.midX, y: contentView.bounds.midY)
        let centerInWindow = contentView.convert(contentCenter, to: nil)
        return window.convertPoint(toScreen: centerInWindow)
    }
}

private struct VictoryCelebrationScene: View {
    @State private var progress: CGFloat = 0
    @State private var frameIndex = 0
    let centerPoint: CGPoint

    private let assetNames = [
        "Walking Cow frame 1",
        "Walking Cow frame 2",
        "Walking Cow frame 3",
        "Walking Cow frame 4",
    ]

    var body: some View {
        GeometryReader { proxy in
            let clampedProgress = min(max(progress, 0), 1)
            let cowSize = min(max(proxy.size.width * 0.16, 180), 260)
            let startX = -cowSize * 0.6
            let endX = proxy.size.width + cowSize * 0.3
            let x = startX + (endX - startX) * clampedProgress
            let diagonalY = pathY(in: proxy.size, progress: clampedProgress)
            let arcLift = sin(clampedProgress * .pi) * proxy.size.height * 0.12
            let bob = sin(clampedProgress * .pi * 8) * 6
            let y = diagonalY - arcLift + bob

            Image(assetNames[frameIndex % assetNames.count])
                .resizable()
                .scaledToFit()
                .frame(width: cowSize, height: cowSize)
                .shadow(color: .black.opacity(0.18), radius: 10, y: 6)
                .position(x: x, y: y)
                .accessibilityIdentifier("victoryCelebrationCow")
        }
        .ignoresSafeArea()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.clear)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("victoryCelebrationScene")
        .task {
            withAnimation(.linear(duration: VictoryCelebrationWindowController.fullAnimationDuration)) {
                progress = 1
            }

            while Task.isCancelled == false {
                try? await Task.sleep(for: .seconds(0.10))
                guard Task.isCancelled == false else { return }
                await MainActor.run {
                    frameIndex = (frameIndex + 1) % assetNames.count
                }
            }
        }
    }

    private func pathY(in size: CGSize, progress: CGFloat) -> CGFloat {
        let startY = size.height * 0.92
        let centerProgress = CGFloat(
            min(
                max(
                    VictoryCelebrationWindowController.alertTriggerDuration
                        / VictoryCelebrationWindowController.fullAnimationDuration,
                    0
                ),
                1
            )
        )
        let endY = size.height * 0.10

        if progress <= centerProgress {
            let localProgress = progress / max(centerProgress, 0.001)
            return startY + (centerPoint.y - startY) * localProgress
        }

        let localProgress = (progress - centerProgress) / max(1 - centerProgress, 0.001)
        return centerPoint.y + (endY - centerPoint.y) * localProgress
    }
}
