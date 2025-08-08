import Cocoa

@objc(WallpaperDownloadsViewController)
final class WallpaperDownloadsViewController: NSViewController, NSCollectionViewDataSource, NSCollectionViewDelegate {
    private let aspectPopup = NSPopUpButton()
    private let importButton = NSButton(title: "Import", target: nil, action: nil)
    private let applyButton = NSButton(title: "Apply", target: nil, action: nil)
    private let collectionView = NSCollectionView()
    private let scrollView = NSScrollView()
    private lazy var storage = WallpaperStorageManager(context: ModelContainerProvider.shared.context)
    private lazy var coordinator = WallpaperCoordinator(modelContext: ModelContainerProvider.shared.context)
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
    aspectPopup.addItems(withTitles: ["Fit", "Fill", "Original"])
    aspectPopup.selectItem(at: 1)
    aspectPopup.target = self
    aspectPopup.action = #selector(onAspectChanged)
    aspectPopup.translatesAutoresizingMaskIntoConstraints = false

    importButton.target = self
    importButton.action = #selector(onImport)
    importButton.translatesAutoresizingMaskIntoConstraints = false

    applyButton.target = self
    applyButton.action = #selector(onApply)
    applyButton.isEnabled = false
    applyButton.translatesAutoresizingMaskIntoConstraints = false

    let topBar = NSStackView(views: [NSView(), aspectPopup, importButton, applyButton])
    topBar.orientation = .horizontal
    topBar.alignment = .centerY
    topBar.spacing = 8
    topBar.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(topBar)

    view.addSubview(scrollView)

    // Double-click to apply
    let doubleClick = NSClickGestureRecognizer(target: self, action: #selector(onDoubleClickItem(_:)))
    doubleClick.numberOfClicksRequired = 2
    collectionView.addGestureRecognizer(doubleClick)

        NSLayoutConstraint.activate([
            topBar.topAnchor.constraint(equalTo: view.topAnchor, constant: 12),
            topBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            topBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),

            scrollView.topAnchor.constraint(equalTo: topBar.bottomAnchor, constant: 8),
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

    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int { items.count }
    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        let item = collectionView.makeItem(withIdentifier: WallpaperItemView.identifier, for: indexPath)
        if let cell = item as? WallpaperItemView {
            let m = items[indexPath.item]
            let title = m.title
            let res = (m.resolutionWidth != nil && m.resolutionHeight != nil) ? "\(Int(m.resolutionWidth!))x\(Int(m.resolutionHeight!))" : ""
            let dur = m.durationSeconds != nil ? String(format: "%.0fs", m.durationSeconds!) : ""
            let info = [res, dur].filter { !$0.isEmpty }.joined(separator: " • ")
            cell.configure(title: title, info: info, image: nil)
            if let thumbURL = m.thumbnailFileURL {
                DispatchQueue.global(qos: .userInitiated).async {
                    let image: NSImage?
                    if let data = try? Data(contentsOf: thumbURL) { image = NSImage(data: data) } else { image = nil }
                    DispatchQueue.main.async { if collectionView.indexPath(for: item) == indexPath { cell.configure(title: title, info: info, image: image) } }
                }
            } else if let data = m.thumbnailPNGData, let image = NSImage(data: data) {
                cell.configure(title: title, info: info, image: image)
            }
        }
        return item
    }

    func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>) {
        applyButton.isEnabled = !indexPaths.isEmpty
    }

    @objc private func onAspectChanged() {
        switch aspectPopup.indexOfSelectedItem {
        case 0: WallpaperRenderer.shared.setAspect(.fit)
        case 1: WallpaperRenderer.shared.setAspect(.fill)
        default: WallpaperRenderer.shared.setAspect(.original)
        }
    }

    @objc private func onImport() {
        coordinator.importAndApply()
        reload()
    }

    @objc private func onApply() {
        guard let idx = collectionView.selectionIndexPaths.first?.item else { return }
        let model = items[idx]
        coordinator.apply(wallpaper: model)
    }

    @objc private func onDoubleClickItem(_ sender: NSClickGestureRecognizer) {
        let p = sender.location(in: collectionView)
        if let indexPath = collectionView.indexPathForItem(at: p) {
            let model = items[indexPath.item]
            coordinator.apply(wallpaper: model)
        }
    }
}
