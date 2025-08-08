//
//  PreviewPaneViewController.swift
//  Walle
//
//  Created by GitHub Copilot on 08/08/25.
//

import AppKit
import AVFoundation

final class PreviewPaneViewController: NSViewController {
    private let titleField = NSTextField(labelWithString: "")
    private let metaField = NSTextField(labelWithString: "")
    private let aspectPopup = NSPopUpButton()
    private let applyButton = NSButton(title: "Apply", target: nil, action: nil)

    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?

    var onApply: ((URL, WallpaperRenderer.AspectMode) -> Void)?

    override func loadView() {
        view = NSView()
        view.wantsLayer = true

        let vev = NSVisualEffectView()
        vev.material = .hudWindow
        vev.blendingMode = .behindWindow
        vev.state = .active
        vev.wantsLayer = true
        vev.layer?.cornerRadius = 10
        vev.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(vev)

        let preview = NSView(); preview.wantsLayer = true; preview.layer?.backgroundColor = NSColor.black.cgColor
        let overlay = NSVisualEffectView(); overlay.material = .underWindowBackground; overlay.state = .active

        titleField.font = .boldSystemFont(ofSize: 14)
        metaField.font = .systemFont(ofSize: 12)
        metaField.textColor = .secondaryLabelColor

        aspectPopup.addItems(withTitles: ["Fit", "Fill", "Original"])
        aspectPopup.selectItem(at: 1)

        applyButton.target = self
        applyButton.action = #selector(applyTapped)

        let rightStack = NSStackView(views: [titleField, metaField, aspectPopup, applyButton])
        rightStack.orientation = .vertical
        rightStack.alignment = .leading
        rightStack.spacing = 8

        let container = NSStackView(views: [preview, rightStack])
        container.orientation = .horizontal
        container.spacing = 12

        vev.addSubview(container)

        vev.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8).isActive = true
        vev.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8).isActive = true
        vev.topAnchor.constraint(equalTo: view.topAnchor, constant: 8).isActive = true
        vev.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -8).isActive = true

        container.translatesAutoresizingMaskIntoConstraints = false
        preview.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            container.leadingAnchor.constraint(equalTo: vev.leadingAnchor, constant: 12),
            container.trailingAnchor.constraint(equalTo: vev.trailingAnchor, constant: -12),
            container.topAnchor.constraint(equalTo: vev.topAnchor, constant: 12),
            container.bottomAnchor.constraint(equalTo: vev.bottomAnchor, constant: -12),
            preview.widthAnchor.constraint(equalToConstant: 520),
            preview.heightAnchor.constraint(equalToConstant: 300)
        ])

        let pl = AVPlayerLayer(); pl.videoGravity = .resizeAspectFill
        preview.layer?.addSublayer(pl)
        playerLayer = pl
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
        let player = AVPlayer(url: url); player.isMuted = true
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
    }
}
