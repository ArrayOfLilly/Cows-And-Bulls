//
//  WindowCloseHandler.swift
//  CowsAndBulls
//
//  Created by Ildikó Kasza on 2026. 03. 11..
//

import SwiftUI
import AppKit

struct WindowCloseHandler: NSViewRepresentable {
    let shouldPromptOnClose: () -> Bool
    let onPause: () -> Void
    let onGiveUp: () -> Void
    let onResume: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(
            shouldPromptOnClose: shouldPromptOnClose,
            onPause: onPause,
            onGiveUp: onGiveUp,
            onResume: onResume
        )
    }

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            if let window = view.window {
                context.coordinator.attach(to: window)
            }
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        context.coordinator.shouldPromptOnClose = shouldPromptOnClose
        context.coordinator.onPause = onPause
        context.coordinator.onGiveUp = onGiveUp
        context.coordinator.onResume = onResume

        if let window = nsView.window, context.coordinator.window !== window {
            context.coordinator.attach(to: window)
        }
    }

    final class Coordinator: NSObject, NSWindowDelegate {
        var shouldPromptOnClose: () -> Bool
        var onPause: () -> Void
        var onGiveUp: () -> Void
        var onResume: () -> Void
        weak var window: NSWindow?

        init(
            shouldPromptOnClose: @escaping () -> Bool,
            onPause: @escaping () -> Void,
            onGiveUp: @escaping () -> Void,
            onResume: @escaping () -> Void
        ) {
            self.shouldPromptOnClose = shouldPromptOnClose
            self.onPause = onPause
            self.onGiveUp = onGiveUp
            self.onResume = onResume
        }

        func attach(to window: NSWindow) {
            self.window = window
            window.delegate = self
        }

        func windowShouldClose(_ sender: NSWindow) -> Bool {
            guard shouldPromptOnClose() else { return true }

            let alert = NSAlert()
            alert.messageText = localized("game.close.title")
            alert.informativeText = localized("game.close.message")
            alert.addButton(withTitle: localized("game.timer.pause"))
            alert.addButton(withTitle: localized("game.action.surrender"))
            alert.addButton(withTitle: localized("common.action.cancel"))
            alert.alertStyle = .warning

            let response = alert.runModal()
            switch response {
            case .alertFirstButtonReturn:
                onPause()
                sender.orderOut(nil)
                return false
            case .alertSecondButtonReturn:
                onGiveUp()
                return true
            default:
                return false
            }
        }

        func windowDidBecomeKey(_ notification: Notification) {
            onResume()
        }
    }
}
