import Cocoa

@objc(WallpaperTabViewController)
final class WallpaperTabViewController: NSTabViewController {
    private let libraryVC = WallpaperLibraryViewController()
    private let downloadsVC = WallpaperDownloadsViewController()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.translatesAutoresizingMaskIntoConstraints = true
        let libraryTab = NSTabViewItem(viewController: libraryVC)
        libraryTab.label = "Library"
        let downloadsTab = NSTabViewItem(viewController: downloadsVC)
        downloadsTab.label = "Downloads"
        self.tabViewItems = [libraryTab, downloadsTab]
        self.selectedTabViewItemIndex = 0
    }
}
