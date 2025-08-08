//
//  FileManagerService.swift
//  Walle
//
//  Created by GitHub Copilot on 08/08/25.
//

import Foundation

enum FileManagerService {
    static var appSupportFolder: URL {
        let base: URL
        do {
            base = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        } catch {
            // Fallback to ~/Library/Application Support
            base = URL(fileURLWithPath: (NSHomeDirectory() as NSString).appendingPathComponent("Library/Application Support"), isDirectory: true)
        }
        let folder = base.appendingPathComponent("Walle/Wallpapers", isDirectory: true)
        do { try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true) } catch { }
        return folder
    }

    static var thumbnailsFolder: URL {
        let folder = appSupportFolder.appendingPathComponent("Thumbnails", isDirectory: true)
        do { try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true) } catch { }
        return folder
    }

    static func safeFilename(for title: String, ext: String) -> String {
        let sanitized = title.replacingOccurrences(of: "[^A-Za-z0-9_-]", with: "-", options: .regularExpression)
        return "\(sanitized)-\(UUID().uuidString).\(ext)"
    }

    static func moveToLibrary(from src: URL, preferredTitle: String) throws -> URL {
        let ext = src.pathExtension.lowercased()
        let name = safeFilename(for: preferredTitle.isEmpty ? src.deletingPathExtension().lastPathComponent : preferredTitle, ext: ext.isEmpty ? "mp4" : ext)
        let dest = appSupportFolder.appendingPathComponent(name)
        if FileManager.default.fileExists(atPath: dest.path) {
            try FileManager.default.removeItem(at: dest)
        }
        try FileManager.default.copyItem(at: src, to: dest)
        return dest
    }

    static func thumbnailURL(for id: UUID) -> URL {
        thumbnailsFolder.appendingPathComponent("\(id.uuidString).png")
    }

    @discardableResult
    static func saveThumbnail(_ data: Data, for id: UUID) -> URL? {
        let url = thumbnailURL(for: id)
        do {
            try data.write(to: url, options: .atomic)
            return url
        } catch {
            return nil
        }
    }
}
