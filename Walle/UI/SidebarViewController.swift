//
//  SidebarViewController.swift
//  Walle
//
//  Created by GitHub Copilot on 08/08/25.
//

import AppKit
import SwiftData

final class SidebarViewController: NSViewController, NSCollectionViewDelegate, NSCollectionViewDataSource, NSCollectionViewDelegateFlowLayout {
    private let collectionView = NSCollectionView()
    private let scrollView = NSScrollView()
    private var data: [WallpaperModel] = []

    private let modelContext: ModelContext
    private lazy var storage = WallpaperStorageManager(context: modelContext)

    var onSelect: ((WallpaperModel) -> Void)?
    var currentSelection: WallpaperModel?

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        super.init(nibName: nil, bundle: nil)
        reload()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func loadView() {
        view = NSView()
        view.wantsLayer = true

        scrollView.documentView = collectionView
        scrollView.hasVerticalScroller = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        collectionView.isSelectable = true
        collectionView.allowsEmptySelection = true
        collectionView.delegate = self
        collectionView.dataSource = self
        let layout = NSCollectionViewFlowLayout()
        layout.itemSize = NSSize(width: 200, height: 120)
        layout.minimumInteritemSpacing = 8
        layout.minimumLineSpacing = 8
        collectionView.collectionViewLayout = layout

        collectionView.register(ThumbnailItem.self, forItemWithIdentifier: ThumbnailItem.reuseID)

        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),
            scrollView.topAnchor.constraint(equalTo: view.topAnchor, constant: 8),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -8)
        ])

        // Drag & drop
        collectionView.registerForDraggedTypes([.fileURL])
    }

    func reload(query: String? = nil) {
        var items = storage.loadAll()
        if let q = query, !q.isEmpty {
            items = items.filter { $0.title.localizedCaseInsensitiveContains(q) || ($0.tags?.contains(where: { $0.localizedCaseInsensitiveContains(q) }) ?? false) }
        }
        // Ensure thumbnails are present
        for m in items { storage.ensureThumbnailIfMissing(for: m) }
        data = items
        collectionView.reloadData()
    }

    func updateSearch(query: String) { reload(query: query) }

    // MARK: NSCollectionViewDataSource
    func numberOfSections(in collectionView: NSCollectionView) -> Int { 1 }
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int { data.count }
    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        let item = collectionView.makeItem(withIdentifier: ThumbnailItem.reuseID, for: indexPath) as! ThumbnailItem
        let model = data[indexPath.item]
        item.configure(with: model)
        return item
    }

    // MARK: Selection
    func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>) {
        guard let idx = indexPaths.first?.item else { return }
        currentSelection = data[idx]
        onSelect?(data[idx])
    }

    // MARK: DnD
    func collectionView(_ collectionView: NSCollectionView, validateDrop draggingInfo: NSDraggingInfo, proposedIndexPath: AutoreleasingUnsafeMutablePointer<NSIndexPath>, dropOperation: UnsafeMutablePointer<NSCollectionView.DropOperation>) -> NSDragOperation {
        return .copy
    }

    func collectionView(_ collectionView: NSCollectionView, acceptDrop draggingInfo: NSDraggingInfo, indexPath: NSIndexPath, dropOperation: NSCollectionView.DropOperation) -> Bool {
        guard let files = draggingInfo.draggingPasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL] else { return false }
        // Import first file
        if let url = files.first { NotificationCenter.default.post(name: .importURL, object: url) }
        return true
    }
}

final class ThumbnailItem: NSCollectionViewItem {
    static let reuseID = NSUserInterfaceItemIdentifier("ThumbnailItem")
    private let imageViewContainer = NSView()
    private let progress = NSProgressIndicator()
    private let statusLabel = NSTextField(labelWithString: "")

    override func loadView() {
        self.view = NSView()
        self.view.wantsLayer = true

        imageViewContainer.wantsLayer = true
        imageViewContainer.layer?.cornerRadius = 8
        imageViewContainer.layer?.masksToBounds = true

        let iv = NSImageView()
        iv.imageScaling = .scaleAxesIndependently
        iv.imageAlignment = .alignCenter
        iv.translatesAutoresizingMaskIntoConstraints = false
        self.imageView = iv

        progress.isIndeterminate = false
        progress.minValue = 0
        progress.maxValue = 1
        progress.isHidden = true

        let stack = NSStackView(views: [imageViewContainer, statusLabel])
        stack.orientation = .vertical
        stack.spacing = 6
        stack.translatesAutoresizingMaskIntoConstraints = false

        imageViewContainer.addSubview(iv)
        view.addSubview(stack)

        view.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            stack.topAnchor.constraint(equalTo: view.topAnchor),
            stack.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            iv.leadingAnchor.constraint(equalTo: imageViewContainer.leadingAnchor),
            iv.trailingAnchor.constraint(equalTo: imageViewContainer.trailingAnchor),
            iv.topAnchor.constraint(equalTo: imageViewContainer.topAnchor),
            iv.bottomAnchor.constraint(equalTo: imageViewContainer.bottomAnchor),
            imageViewContainer.heightAnchor.constraint(equalToConstant: 110)
        ])
    }

    func configure(with model: WallpaperModel) {
        statusLabel.stringValue = model.downloadStatus == .downloading ? "Downloading…" : (model.downloadStatus == .failed ? "Failed" : "")
        if let thumbURL = model.thumbnailFileURL, let img = NSImage(contentsOf: thumbURL) {
            imageView?.image = img
        } else if let data = model.thumbnailPNGData, let image = NSImage(data: data) {
            imageView?.image = image
        } else if let url = model.localFileURL, let data = WallpaperStorageManager.generateThumbnailPNG(url: url) {
            imageView?.image = NSImage(data: data)
        } else {
            imageView?.image = NSImage(systemSymbolName: "film", accessibilityDescription: nil)
        }

        if let w = model.resolutionWidth, let h = model.resolutionHeight, let dur = model.durationSeconds {
            statusLabel.stringValue = "\(Int(w))x\(Int(h)) • \(String(format: "%.1fs", dur))"
        }
    }
}

extension Notification.Name { static let importURL = Notification.Name("ImportURL") }
