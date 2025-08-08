import Cocoa
import SwiftData
import AVFoundation

@objc(WallpaperLibraryViewController)
final class WallpaperLibraryViewController: NSViewController, NSCollectionViewDataSource, NSCollectionViewDelegate {
    private let searchField = NSSearchField()
    private let collectionView = NSCollectionView()
    private let scrollView = NSScrollView()

    private var all: [WallpaperModel] = []
    private var filtered: [WallpaperModel] = []
    private lazy var storage = WallpaperStorageManager(context: ModelContainerProvider.shared.context)

    override func loadView() {
        view = NSView()
        setupUI()
        reload()
    }

    private func setupUI() {
        view.translatesAutoresizingMaskIntoConstraints = false
        searchField.placeholderString = "Search"
        searchField.target = self
        searchField.action = #selector(onSearch)
        searchField.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(searchField)

        let layout = NSCollectionViewFlowLayout()
        layout.itemSize = NSSize(width: 260, height: 180)
        layout.minimumInteritemSpacing = 12
        layout.minimumLineSpacing = 12
        layout.sectionInset = NSEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)

        collectionView.collectionViewLayout = layout
        collectionView.register(WallpaperItemView.self, forItemWithIdentifier: WallpaperItemView.identifier)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.isSelectable = true

    scrollView.documentView = collectionView
        scrollView.hasVerticalScroller = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        NSLayoutConstraint.activate([
            searchField.topAnchor.constraint(equalTo: view.topAnchor, constant: 12),
            searchField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            searchField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),

            scrollView.topAnchor.constraint(equalTo: searchField.bottomAnchor, constant: 8),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

    // Ensure the collection view fills the scroll view's content
    collectionView.frame = scrollView.bounds
    collectionView.autoresizingMask = [.width, .height]
    }

    @objc private func onSearch() {
        let q = searchField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if q.isEmpty { filtered = all } else {
            filtered = all.filter { $0.title.lowercased().contains(q) }
        }
        collectionView.reloadData()
    }

    private func reload() {
        all = storage.loadAll()
        filtered = all
        collectionView.reloadData()
    }

    // MARK: NSCollectionViewDataSource
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int { filtered.count }
    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        let item = collectionView.makeItem(withIdentifier: WallpaperItemView.identifier, for: indexPath)
        if let cell = item as? WallpaperItemView {
            let m = filtered[indexPath.item]
            let title = m.title
            let res = (m.resolutionWidth != nil && m.resolutionHeight != nil) ? "\(Int(m.resolutionWidth!))x\(Int(m.resolutionHeight!))" : ""
            let dur = m.durationSeconds != nil ? String(format: "%.0fs", m.durationSeconds!) : ""
            let info = [res, dur].filter { !$0.isEmpty }.joined(separator: " • ")
            var image: NSImage? = nil
            if let thumbURL = m.thumbnailFileURL, let data = try? Data(contentsOf: thumbURL) { image = NSImage(data: data) }
            else if let data = m.thumbnailPNGData { image = NSImage(data: data) }
            cell.configure(title: title, info: info, image: image)
        }
        return item
    }
}
