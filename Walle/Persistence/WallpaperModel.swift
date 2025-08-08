//
//  WallpaperModel.swift
//  Walle
//
//  Created by GitHub Copilot on 08/08/25.
//

import Foundation
import SwiftData

public enum WallpaperSourceKind: String, Codable, Sendable {
    case local
    case remote
}

public enum DownloadStatusKind: String, Codable, Sendable {
    case notDownloaded
    case downloading
    case downloaded
    case failed
}

@Model
public final class WallpaperModel {
    @Attribute(.unique) public var id: UUID
    public var title: String

    // Source info
    public var sourceRaw: String // WallpaperSourceKind
    public var remoteURL: URL?

    // Local persistence
    public var localFileURL: URL?

    // Download state
    public var downloadStatusRaw: String // DownloadStatusKind
    public var downloadProgress: Double?
    public var lastErrorMessage: String?

    // Metadata
    public var isApplied: Bool
    public var createdAt: Date
    public var updatedAt: Date
    public var durationSeconds: Double?
    public var fileSizeBytes: Int64?
    public var resolutionWidth: Double?
    public var resolutionHeight: Double?
    // Primary persisted thumbnail path (preferred)
    public var thumbnailFileURL: URL?
    // Back-compat inline thumbnail data
    public var thumbnailPNGData: Data?
    private var tagsRaw: String?

    public init(id: UUID = UUID(),
                title: String,
                source: WallpaperSourceKind,
                remoteURL: URL? = nil,
                localFileURL: URL? = nil,
                downloadStatus: DownloadStatusKind = .notDownloaded,
                downloadProgress: Double? = nil,
                isApplied: Bool = false,
                createdAt: Date = .now,
                updatedAt: Date = .now,
                durationSeconds: Double? = nil,
                fileSizeBytes: Int64? = nil,
                resolutionWidth: Double? = nil,
                resolutionHeight: Double? = nil,
                thumbnailFileURL: URL? = nil,
                thumbnailPNGData: Data? = nil,
                tags: [String]? = nil,
                lastErrorMessage: String? = nil) {
        self.id = id
        self.title = title
        self.sourceRaw = source.rawValue
        self.remoteURL = remoteURL
        self.localFileURL = localFileURL
        self.downloadStatusRaw = downloadStatus.rawValue
        self.downloadProgress = downloadProgress
        self.isApplied = isApplied
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.durationSeconds = durationSeconds
        self.fileSizeBytes = fileSizeBytes
        self.resolutionWidth = resolutionWidth
        self.resolutionHeight = resolutionHeight
        self.thumbnailFileURL = thumbnailFileURL
        self.thumbnailPNGData = thumbnailPNGData
        self.tagsRaw = tags?.joined(separator: ",")
        self.lastErrorMessage = lastErrorMessage
    }
}

public extension WallpaperModel {
    var source: WallpaperSourceKind {
        get { WallpaperSourceKind(rawValue: sourceRaw) ?? .local }
        set { sourceRaw = newValue.rawValue }
    }

    var downloadStatus: DownloadStatusKind {
        get { DownloadStatusKind(rawValue: downloadStatusRaw) ?? .notDownloaded }
        set { downloadStatusRaw = newValue.rawValue }
    }

    var tags: [String]? {
        get { tagsRaw?.split(separator: ",").map { String($0) } }
        set { tagsRaw = newValue?.joined(separator: ",") }
    }
}
