//
//  WallpaperRenderer.swift
//  Walle
//
//  Created by GitHub Copilot on 08/08/25.
//

import AppKit
import AVFoundation

final class WallpaperRenderer {
    static let shared = WallpaperRenderer()

    enum AspectMode { case fit, fill, original }

    // Single shared player/looper across all screens
    private var player: AVQueuePlayer?
    private var looper: AVPlayerLooper?

    // One layer per screen key
    private var playerLayers: [ObjectIdentifier: AVPlayerLayer] = [:]
    private var aspectMode: AspectMode = .fill

    private init() {
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(screensDidWake), name: NSWorkspace.screensDidWakeNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(windowResized(_:)), name: NSWindow.didResizeNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(screenParametersChanged), name: NSApplication.didChangeScreenParametersNotification, object: nil)
    }

    func setAspect(_ mode: AspectMode) {
        if !Thread.isMainThread { return DispatchQueue.main.async { self.setAspect(mode) } }
        aspectMode = mode
        // Update all layers
        for (_, layer) in playerLayers {
            switch mode {
            case .fit: layer.videoGravity = .resizeAspect
            case .fill: layer.videoGravity = .resizeAspectFill
            case .original: layer.videoGravity = .resize
            }
        }
        reattachLayers()
    }

    func playOnAllScreens(url: URL) {
        if !Thread.isMainThread { return DispatchQueue.main.async { self.playOnAllScreens(url: url) } }
        // Stop current
        stopAll()
        // Build new shared player
        let asset = AVURLAsset(url: url)
        let item = AVPlayerItem(asset: asset)
        let player = AVQueuePlayer(items: [item])
        player.isMuted = true
        player.actionAtItemEnd = .none
        let looper = AVPlayerLooper(player: player, templateItem: item)
        self.player = player
        self.looper = looper
        // Attach layers to every screen
        reattachLayers()
        player.play()
    }

    private func reattachLayers() {
        if !Thread.isMainThread { return DispatchQueue.main.async { self.reattachLayers() } }
        guard let player else { return }
    // Remove and rebuild per-screen player layers only
    for (key, layer) in playerLayers { layer.removeFromSuperlayer(); playerLayers.removeValue(forKey: key) }
    // Attach new layers to each window
        for screen in NSScreen.screens {
            let key = ObjectIdentifier(screen)
            guard let window = WindowManager.shared.window(for: screen), let contentView = window.contentView else { continue }
            let layer = AVPlayerLayer(player: player)
            switch aspectMode {
            case .fit: layer.videoGravity = .resizeAspect
            case .fill: layer.videoGravity = .resizeAspectFill
            case .original: layer.videoGravity = .resize
            }
            CATransaction.begin(); CATransaction.setDisableActions(true)
            layer.frame = contentView.bounds
            // Ensure a backing layer exists
            if contentView.layer == nil { contentView.wantsLayer = true }
            // Remove previous player layers to avoid stacking
            contentView.layer?.sublayers?.filter { $0 is AVPlayerLayer }.forEach { $0.removeFromSuperlayer() }
            contentView.layer?.addSublayer(layer)
            CATransaction.commit()
            playerLayers[key] = layer
        }
    }

    func stop(on screen: NSScreen?) {
        if let s = screen {
            let key = ObjectIdentifier(s)
            playerLayers[key]?.removeFromSuperlayer()
            playerLayers.removeValue(forKey: key)
        } else {
            stopAll()
        }
    }

    private func stopAll() {
        if !Thread.isMainThread { return DispatchQueue.main.async { self.stopAll() } }
        for layer in playerLayers.values { layer.removeFromSuperlayer() }
        playerLayers.removeAll()
        player?.pause()
        looper = nil
        player = nil
    }

    func pauseAll() { player?.pause() }
    func resumeAll() { player?.play() }

    // Reassert current player layers onto windows without changing aspect
    func reassert() {
        reattachLayers()
    }

    @objc private func windowResized(_ notification: Notification) {
        guard let window = notification.object as? NSWindow, let screen = window.screen else { return }
        let key = ObjectIdentifier(screen)
        if let layer = playerLayers[key], let contentView = window.contentView {
            CATransaction.begin(); CATransaction.setDisableActions(true)
            layer.frame = contentView.bounds
            CATransaction.commit()
        }
    }

    @objc private func screenParametersChanged() { reattachLayers() }
    @objc private func screensDidWake() { resumeAll() }
}
