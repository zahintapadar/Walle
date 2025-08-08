import Cocoa

@objc(WallpaperDownloadsViewController)
final class WallpaperDownloadsViewController: NSViewController, NSCollectionViewDataSource, NSCollectionViewDelegate {
    private let collectionView = NSCollectionView()
    private let scrollView = NSScrollView()
    private lazy var storage = WallpaperStorageManager(context: ModelContainerProvider.shared.context)
    private var items: [WallpaperModel] = []

    override func loadView() {
        view = NSView()
        setupUI()
        reload()
    }

    private func setupUI() {
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
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

    collectionView.frame = scrollView.bounds
    collectionView.autoresizingMask = [.width, .height]
    }

    private func reload() {
        items = storage.loadAll().filter { $0.downloadStatus == .downloaded }
        collectionView.reloadData()
    }

    // MARK: DataSource
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int { items.count }
    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        let item = collectionView.makeItem(withIdentifier: WallpaperItemView.identifier, for: indexPath)
        if let cell = item as? WallpaperItemView {
            let m = items[indexPath.item]
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
