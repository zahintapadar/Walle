import Foundation
#if canImport(SwiftSoup)
import SwiftSoup
#endif

struct WallpaperListing: Identifiable, Codable {
    let id: String
    let title: String
    let resolution: String
    let duration: String
    let thumbnailURL: URL
    let downloadURL: URL
}

final class WallpaperLibraryService {
    static let shared = WallpaperLibraryService()
    private let baseURL = URL(string: "https://motionbgs.com")!

    func fetchWallpapers(completion: @escaping (Result<[WallpaperListing], Error>) -> Void) {
        let url = baseURL
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = data, let html = String(data: data, encoding: .utf8) else {
                completion(.failure(NSError(domain: "WallpaperLibraryService", code: 1, userInfo: [NSLocalizedDescriptionKey: "No data"])));
                return
            }
            do {
                #if canImport(SwiftSoup)
                let doc = try SwiftSoup.parse(html)
                let elements = try doc.select(".video-item")
                var listings: [WallpaperListing] = []
                for el in elements.array() {
                    let title = try el.select(".video-title").text()
                    let resolution = try el.select(".video-resolution").text()
                    let duration = try el.select(".video-duration").text()
                    let thumbSrc = try el.select("img").attr("src")
                    let downloadHref = try el.select("a.download").attr("href")
                    guard let thumbURL = URL(string: thumbSrc, relativeTo: self.baseURL),
                          let downloadURL = URL(string: downloadHref, relativeTo: self.baseURL) else { continue }
                    let id = downloadURL.absoluteString
                    listings.append(WallpaperListing(id: id, title: title, resolution: resolution, duration: duration, thumbnailURL: thumbURL, downloadURL: downloadURL))
                }
                completion(.success(listings))
                #else
                // SwiftSoup not available; return an informative error
                completion(.failure(NSError(domain: "WallpaperLibraryService", code: 2, userInfo: [NSLocalizedDescriptionKey: "SwiftSoup dependency missing. Install via Swift Package Manager or guard usage."])));
                #endif
            } catch {
                completion(.failure(error))
            }
        }
        task.resume()
    }
}
