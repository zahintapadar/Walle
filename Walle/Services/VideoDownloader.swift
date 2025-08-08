//
//  VideoDownloader.swift
//  Walle
//
//  Created by GitHub Copilot on 08/08/25.
//

import Foundation

final class VideoDownloader: NSObject, URLSessionDownloadDelegate {
    typealias ProgressHandler = (Double) -> Void

    private lazy var session: URLSession = {
        let config = URLSessionConfiguration.default
        // Use a background delegate queue to avoid blocking the main thread
        let queue = OperationQueue()
        queue.qualityOfService = .utility
        queue.maxConcurrentOperationCount = 1
        return URLSession(configuration: config, delegate: self, delegateQueue: queue)
    }()

    private var progressHandlers: [URLSessionTask: ProgressHandler] = [:]
    private var completionHandlers: [URLSessionTask: (Result<URL, Error>) -> Void] = [:]

    func download(from url: URL, progress: ProgressHandler? = nil, completion: @escaping (Result<URL, Error>) -> Void) {
        let task = session.downloadTask(with: url)
        if let p = progress { progressHandlers[task] = p }
        completionHandlers[task] = completion
        task.resume()
    }

    // MARK: URLSessionDownloadDelegate
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        let completion = completionHandlers.removeValue(forKey: downloadTask) ?? { _ in }
        do {
            let suggested = downloadTask.originalRequest?.url?.lastPathComponent ?? UUID().uuidString
            let ext = (suggested as NSString).pathExtension.isEmpty ? "mp4" : (suggested as NSString).pathExtension
            let safe = FileManagerService.safeFilename(for: (suggested as NSString).deletingPathExtension, ext: ext)
            let dest = FileManagerService.appSupportFolder.appendingPathComponent(safe)
            try? FileManager.default.removeItem(at: dest)
            try FileManager.default.moveItem(at: location, to: dest)

            DispatchQueue.main.async { completion(.success(dest)) }
        } catch {
            DispatchQueue.main.async { completion(.failure(error)) }
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            let completion = completionHandlers.removeValue(forKey: task) ?? { _ in }
            DispatchQueue.main.async { completion(.failure(error)) }
        }
        progressHandlers.removeValue(forKey: task)
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        guard totalBytesExpectedToWrite > 0 else { return }
        let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        if let handler = progressHandlers[downloadTask] {
            DispatchQueue.main.async { handler(progress) }
        }
    }
}
