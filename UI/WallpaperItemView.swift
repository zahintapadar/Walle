import Cocoa

final class WallpaperItemView: NSCollectionViewItem {
    static let identifier = NSUserInterfaceItemIdentifier("WallpaperItem")

    private let thumbView = NSImageView()
    private let titleLabel = NSTextField(labelWithString: "")
    private let infoLabel = NSTextField(labelWithString: "")

    override func loadView() {
        self.view = NSView()
        view.wantsLayer = true
        view.layer?.cornerRadius = 8
        view.layer?.masksToBounds = true

        thumbView.imageScaling = .scaleProportionallyUpOrDown
        thumbView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = .systemFont(ofSize: 12, weight: .medium)
        titleLabel.lineBreakMode = .byTruncatingMiddle
        infoLabel.font = .systemFont(ofSize: 11)
        infoLabel.textColor = .secondaryLabelColor
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        infoLabel.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(thumbView)
        view.addSubview(titleLabel)
        view.addSubview(infoLabel)

        NSLayoutConstraint.activate([
            thumbView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            thumbView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            thumbView.topAnchor.constraint(equalTo: view.topAnchor),
            thumbView.heightAnchor.constraint(equalTo: thumbView.widthAnchor, multiplier: 9.0/16.0),

            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 6),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -6),
            titleLabel.topAnchor.constraint(equalTo: thumbView.bottomAnchor, constant: 6),

            infoLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 6),
            infoLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -6),
            infoLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 2),
            infoLabel.bottomAnchor.constraint(lessThanOrEqualTo: view.bottomAnchor, constant: -6)
        ])
    }

    func configure(title: String, info: String, image: NSImage?) {
        titleLabel.stringValue = title
        infoLabel.stringValue = info
        thumbView.image = image
    }
}
