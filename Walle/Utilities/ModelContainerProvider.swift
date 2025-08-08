//
//  ModelContainerProvider.swift
//  Walle
//
//  Created by GitHub Copilot on 08/08/25.
//

import Foundation
import SwiftData

// Centralizes a single ModelContainer and ModelContext for the whole app.
// Avoids multiple contexts/containers scattered across AppKit and SwiftUI layers.
final class ModelContainerProvider {
    static let shared = ModelContainerProvider()

    let container: ModelContainer
    let context: ModelContext

    private init() {
        let schema = Schema([
            Item.self,
            WallpaperModel.self,
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            container = try ModelContainer(for: schema, configurations: [configuration])
            context = ModelContext(container)
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }
}
