import AppKit

final class TabMainWindowController: NSWindowController {
	private let tabVC: NSViewController

	init() {
		if let cls = NSClassFromString("WallpaperTabViewController") as? NSViewController.Type {
			tabVC = cls.init()
		} else {
			// Fallback to a basic container if resolution fails
			tabVC = NSViewController()
		}

		let win = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 1000, height: 700),
						   styleMask: [.titled, .closable, .miniaturizable, .resizable],
						   backing: .buffered, defer: false)
		win.title = "Walle"
		win.center()
		win.contentViewController = tabVC
		super.init(window: win)
	}

	required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

