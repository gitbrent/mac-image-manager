//
//  BrowserModel.swift
//  MacImageManager
//
//  Created by Brent Ely on 9/20/25.
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers
import Combine

class BrowserModel: ObservableObject {
    @Published var items: [FileItem] = []
    @Published var currentDirectory: URL
    @Published var canNavigateUp: Bool = false
    @Published var showingFileImporter: Bool = false

    // Caches to speed up metadata/icon recomputation in large directories
    private var fileItemCache: [URL: FileItem] = [:]
    private var iconNameCache: [String: String] = [:] // key: UTI identifier

    private let fileManager = FileManager.default

    init() {
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
        let desktopURL = fileManager.urls(for: .desktopDirectory, in: .userDomainMask).first
        let homeURL = fileManager.homeDirectoryForCurrentUser

        // Initialize with a default value first to satisfy the compiler
        self.currentDirectory = homeURL

        let candidates = [documentsURL, desktopURL, homeURL].compactMap { $0 }

        // Use the `first` method to find the appropriate directory
        if let foundURL = candidates.first(where: { url in
            var isDirFlag: ObjCBool = false
            return fileManager.fileExists(atPath: url.path, isDirectory: &isDirFlag) && isDirFlag.boolValue
        }) {
            self.currentDirectory = foundURL
        }

        updateNavigationState()
    }

    var currentDirectoryName: String {
        currentDirectory.lastPathComponent
    }

    var imageCount: Int {
        items.filter { isImageFile($0) }.count
    }

    func loadInitialDirectory() {
        loadCurrentDirectory()
    }

    func loadCurrentDirectory() {
        do {
            let contents = try fileManager.contentsOfDirectory(
                at: currentDirectory,
                includingPropertiesForKeys: [.isDirectoryKey, .fileSizeKey, .contentModificationDateKey, .isReadableKey, .contentTypeKey],
                options: [.skipsHiddenFiles]
            )

            var fileItems: [FileItem] = []

            for url in contents {
                let resourceValues = try url.resourceValues(forKeys: [.isDirectoryKey, .fileSizeKey, .contentModificationDateKey, .isReadableKey, .contentTypeKey])
                
                // GUARD: Check if the file is readable.
                guard resourceValues.isReadable ?? false else { continue }
                
                let uti = resourceValues.contentType
                let isDir = resourceValues.isDirectory ?? false
                let isAnimatedGif = uti?.conforms(to: UTType.gif) ?? false
                let isVideo = uti?.conforms(to: UTType.movie) ?? false
                let fileSize = resourceValues.fileSize ?? 0
                let modDate = resourceValues.contentModificationDate ?? Date()

                let iconName: String
                if isDir {
                    iconName = "folder.fill"
                } else {
                    iconName = self.iconName(for: uti)
                }

                // Reuse cached FileItem when unchanged to avoid recomputing
                if let cached = fileItemCache[url],
                   cached.isDirectory == isDir,
                   cached.fileSize == fileSize,
                   cached.modificationDate == modDate,
                   cached.uti == uti {
                    fileItems.append(cached)
                } else {
                    let fileItem = FileItem(
                        url: url,
                        name: url.lastPathComponent,
                        iconName: iconName,
                        isDirectory: isDir,
                        fileSize: fileSize,
                        modificationDate: modDate,
                        uti: uti,
                        isAnimatedGif: isAnimatedGif,
                        isVideo: isVideo
                    )
                    fileItems.append(fileItem)
                    fileItemCache[url] = fileItem
                }
            }

            fileItems.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }

            self.items = fileItems
            // Prune cache to current directory entries to bound memory usage
            let currentURLs = Set(fileItems.map { $0.url })
            fileItemCache = fileItemCache.filter { currentURLs.contains($0.key) }
            print("Loaded \(items.count) items.")

            updateNavigationState()

        } catch {
            print("Error loading directory: \(error)")
            self.items = []
        }
    }

    func navigateUp() {
        let parentDirectory = currentDirectory.deletingLastPathComponent()

        // Don't go above the user's home directory for safety
        if parentDirectory.path.count >= fileManager.homeDirectoryForCurrentUser.path.count {
            currentDirectory = parentDirectory
            loadCurrentDirectory()
        }
    }

    func navigateInto(item: FileItem) {
        guard item.isDirectory else {
            print("Not a directory: \(item.url.path)")
            return
        }

        // Check if we can actually read this directory before navigating
        var isDirFlag: ObjCBool = false
        guard fileManager.fileExists(atPath: item.url.path, isDirectory: &isDirFlag),
              isDirFlag.boolValue else {
            print("Directory doesn't exist or isn't accessible: \(item.url.path)")
            return
        }

        // Test if we can read the directory
        do {
            _ = try fileManager.contentsOfDirectory(at: item.url, includingPropertiesForKeys: nil, options: [])
            print("Navigating into: \(item.url.path)")
            currentDirectory = item.url
            loadCurrentDirectory()
        } catch {
            print("Cannot access directory \(item.url.path): \(error)")
        }
    }

    func isImageFile(_ item: FileItem) -> Bool {
        guard !item.isDirectory else { return false }

        // Prefer the UTI from metadata; if missing, derive from the filename extension
        let type = item.uti ?? UTType(filenameExtension: item.url.pathExtension.lowercased())

        if let type {
            return type.conforms(to: .rawImage) || type.conforms(to: .image)
        }

        return false
    }

    func openDirectory(_ item: FileItem) {
        self.currentDirectory = item.url
        loadCurrentDirectory()
    }

    // Returns an SF Symbol name for a given UTI, with simple caching
    private func iconName(for uti: UTType?) -> String {
        guard let uti = uti else { return "doc" }
        let key = uti.identifier
        if let cached = iconNameCache[key] {
            return cached
        }

        let name: String
        if uti.conforms(to: UTType.rawImage) || uti.conforms(to: UTType.image) {
            name = "photo"
        } else if uti.conforms(to: UTType.movie) {
            name = "film"
        } else if uti.conforms(to: UTType.text) {
            name = "doc.text"
        } else if uti.conforms(to: UTType.sourceCode) {
            name = "doc.text.fill"
        } else {
            name = "doc"
        }
        iconNameCache[key] = name
        return name
    }

    private func updateNavigationState() {
        let homeDirectory = fileManager.homeDirectoryForCurrentUser
        canNavigateUp = currentDirectory.path != homeDirectory.path &&
                       currentDirectory.pathComponents.count > homeDirectory.pathComponents.count
    }

    // Convenience method for keyboard navigation
    func selectNextImage(after currentItem: FileItem?) -> FileItem? {
        let imageItems = items.filter { !$0.isDirectory }

        guard !imageItems.isEmpty else { return nil }

        if let currentItem = currentItem,
           let currentIndex = imageItems.firstIndex(where: { $0.url == currentItem.url }),
           currentIndex + 1 < imageItems.count {
            return imageItems[currentIndex + 1]
        }

        return imageItems.first
    }

    func selectPreviousImage(before currentItem: FileItem?) -> FileItem? {
        let imageItems = items.filter { !$0.isDirectory }

        guard !imageItems.isEmpty else { return nil }

        if let currentItem = currentItem,
           let currentIndex = imageItems.firstIndex(where: { $0.url == currentItem.url }),
           currentIndex > 0 {
            return imageItems[currentIndex - 1]
        }

        return imageItems.last
    }
}

