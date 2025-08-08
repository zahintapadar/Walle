//
//  PreviewPanelViewController.swift
//  Walle
//
//  Created by GitHub Copilot on 08/08/25.
//

import AppKit
import AVFoundation

final class PreviewPanelViewController: NSViewController {
    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?

    private let titleField = NSTextField(labelWithString: "")
    private let metaField = NSTextField(labelWithString: "")
    private let aspectPopup = NSPopUpButton()
    private let applyButton = NSButton(title: "Apply", target: nil, action: nil)

    var onApply: ((URL, WallpaperRenderer.AspectMode) -> Void)?

    override func loadView() {
        self.view = NSView()
        self.view.wantsLayer = true

        let preview = NSView()
        preview.wantsLayer = true
        preview.layer?.backgroundColor = NSColor.black.cgColor

        titleField.font = .boldSystemFont(ofSize: 13)
        metaField.font = .systemFont(ofSize: 11)
        metaField.textColor = .secondaryLabelColor

        aspectPopup.addItems(withTitles: ["Fit", "Fill", "Original"]) // maps to enum
        aspectPopup.selectItem(at: 1)

        let checkbox = NSButton(checkboxWithTitle: "Hide app after apply", target: self, action: #selector(toggleHide))
        checkbox.state = PreferencesStore.load().hideAppAfterApply ? .on : .off

        let stack = NSStackView(views: [titleField, metaField, aspectPopup, checkbox, applyButton])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 8

        let container = NSStackView(views: [preview, stack])
        container.orientation = .horizontal
        container.spacing = 12
        container.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(container)

        NSLayoutConstraint.activate([
            container.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            container.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            container.topAnchor.constraint(equalTo: view.topAnchor, constant: 12),
            container.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -12),
            preview.widthAnchor.constraint(equalToConstant: 420),
            preview.heightAnchor.constraint(equalToConstant: 240),
        ])

        // store preview layer holder
        self.playerLayer = AVPlayerLayer()
        self.playerLayer?.videoGravity = .resizeAspectFill
        preview.layer?.addSublayer(self.playerLayer!)

        applyButton.target = self
        applyButton.action = #selector(applyTapped)
    }

    override func viewDidLayout() {
        super.viewDidLayout()
        if let holder = playerLayer?.superlayer { playerLayer?.frame = holder.bounds }
    }

    func configure(with url: URL, title: String) {
        titleField.stringValue = title
        let asset = AVURLAsset(url: url)
        let duration = CMTimeGetSeconds(asset.duration)
        var resolution = "Unknown"
        if let track = asset.tracks(withMediaType: .video).first {
            let size = track.naturalSize.applying(track.preferredTransform)
            resolution = "\(abs(Int(size.width)))x\(abs(Int(size.height)))"
        }
        metaField.stringValue = "Duration: \(String(format: "%.1fs", duration))  •  Resolution: \(resolution)"
        let player = AVPlayer(url: url)
        player.isMuted = true
        self.player = player
        self.playerLayer?.player = player
        player.play()
    }

    @objc private func applyTapped() {
        guard let url = (player?.currentItem?.asset as? AVURLAsset)?.url else { return }
        let mode: WallpaperRenderer.AspectMode
        switch aspectPopup.indexOfSelectedItem {
        case 0: mode = .fit
        case 1: mode = .fill
        default: mode = .original
        }
        onApply?(url, mode)
        let prefs = PreferencesStore.load()
        if prefs.hideAppAfterApply {
            self.view.window?.miniaturize(nil)
        }
    }

    @objc private func toggleHide(_ sender: NSButton) {
        var prefs = PreferencesStore.load()
        prefs.hideAppAfterApply = (sender.state == .on)
        PreferencesStore.save(prefs)
    }
}
