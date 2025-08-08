//
//  LocalWallpaperImporter.swift
//  Walle
//
//  Created by GitHub Copilot on 08/08/25.
//

import AppKit
import AVFoundation
import UniformTypeIdentifiers

final class LocalWallpaperImporter {
    func pickMovie() throws -> URL? {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.allowedContentTypes = [.movie]
        panel.canChooseFiles = true
        panel.title = "Choose a video file"
        let response = panel.runModal()
        guard response == .OK, let url = panel.url else { return nil }
        // Validate
        let asset = AVURLAsset(url: url)
        guard asset.isPlayable else { return nil }
        return url
    }
}
