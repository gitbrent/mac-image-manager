//
//  BrowserModel.swift
//  MacImageManager
//
//  Created by Brent Ely on 9/20/25.
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers
internal import Combine

class BrowserModel: ObservableObject {
    @Published var items: [FileItem] = []
    @Published var currentDirectory: URL
    @Published var canNavigateUp: Bool = false
    @Published var showingFileImporter: Bool = false

    private let fileManager = FileManager.default
    private let imageTypes: Set<String> = {
        var types = Set<String>()

        // Common image extensions
        let extensions = ["jpg", "jpeg", "png", "gif", "bmp", "tiff", "tif", "heic", "heif", "webp", "svg", "ico"]

        for ext in extensions {
            types.insert(ext.lowercased())
        }

        return types
    }()

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
                
                let isDir = resourceValues.isDirectory ?? false
                let fileSize = resourceValues.fileSize ?? 0
                let modDate = resourceValues.contentModificationDate ?? Date()
                let uti = resourceValues.contentType

                let iconName: String
                if isDir {
                    iconName = "folder.fill"
                } else if uti?.conforms(to: .image) ?? false {
                    iconName = "photo"
                } else if uti?.conforms(to: .movie) ?? false {
                    iconName = "film"
                } else if uti?.conforms(to: .text) ?? false {
                    iconName = "doc.text"
                } else if uti?.conforms(to: .sourceCode) ?? false {
                    iconName = "doc.text.fill"
                } else {
                    iconName = "doc"
                }

                let fileItem = FileItem(url: url, name: url.lastPathComponent, iconName: iconName, isDirectory: isDir, fileSize: fileSize, modificationDate: modDate, uti: uti)
                fileItems.append(fileItem)
            }

            fileItems.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }

            self.items = fileItems
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
        let ext = item.url.pathExtension.lowercased()
        return imageTypes.contains(ext)
    }

    func openDirectory(_ item: FileItem) {
        self.currentDirectory = item.url
        loadCurrentDirectory()
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
