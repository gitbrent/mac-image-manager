//
//  DirectoryBrowserModel.swift
//  MacImageManager
//
//  Created by Brent Ely on 9/20/25.
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers
internal import Combine

class BrowserModel: ObservableObject {
    @Published var items: [URL] = []
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
        items.filter { !isDirectory($0) }.count
    }

    func loadInitialDirectory() {
        loadCurrentDirectory()
    }

    func loadCurrentDirectory() {
        // First verify the directory exists and is accessible
        var isDirFlag: ObjCBool = false
        guard fileManager.fileExists(atPath: currentDirectory.path, isDirectory: &isDirFlag),
              isDirFlag.boolValue else {
            print("Directory doesn't exist or isn't accessible: \(currentDirectory.path)")
            // Fall back to home directory
            currentDirectory = fileManager.homeDirectoryForCurrentUser
            updateNavigationState()
            loadCurrentDirectory()
            return
        }

        print("Loading directory: \(currentDirectory.path)")

        do {
            let contents = try fileManager.contentsOfDirectory(
                at: currentDirectory,
                includingPropertiesForKeys: [.isDirectoryKey, .isReadableKey],
                options: [.skipsHiddenFiles]
            )

            var directories: [URL] = []
            var images: [URL] = []

            for url in contents {
                // Skip items we can't read
                if let resourceValues = try? url.resourceValues(forKeys: [.isReadableKey]),
                   let isReadable = resourceValues.isReadable,
                   !isReadable {
                    continue
                }

                if isDirectory(url) {
                    directories.append(url)
                } else if isImageFile(url) {
                    images.append(url)
                }
            }

            // Sort directories and images separately, then combine
            directories.sort { $0.lastPathComponent.localizedCaseInsensitiveCompare($1.lastPathComponent) == .orderedAscending }
            images.sort { $0.lastPathComponent.localizedCaseInsensitiveCompare($1.lastPathComponent) == .orderedAscending }

            self.items = directories + images
            print("Loaded \(directories.count) directories and \(images.count) images")

            // Update navigation state
            updateNavigationState()

        } catch {
            print("Error loading directory: \(error)")
            print("Current directory path: \(currentDirectory.path)")
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

    func navigateInto(directory: URL) {
        guard isDirectory(directory) else {
            print("Not a directory: \(directory.path)")
            return
        }

        // Check if we can actually read this directory before navigating
        var isDirFlag: ObjCBool = false
        guard fileManager.fileExists(atPath: directory.path, isDirectory: &isDirFlag),
              isDirFlag.boolValue else {
            print("Directory doesn't exist or isn't accessible: \(directory.path)")
            return
        }

        // Test if we can read the directory
        do {
            _ = try fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil, options: [])
            print("Navigating into: \(directory.path)")
            currentDirectory = directory
            loadCurrentDirectory()
        } catch {
            print("Cannot access directory \(directory.path): \(error)")
        }
    }

    func isDirectory(_ url: URL) -> Bool {
        do {
            let resourceValues = try url.resourceValues(forKeys: [.isDirectoryKey])
            return resourceValues.isDirectory ?? false
        } catch {
            return false
        }
    }

    func openDirectory(_ url: URL) {
        self.currentDirectory = url
        loadCurrentDirectory()
    }

    private func isImageFile(_ url: URL) -> Bool {
        let fileExtension = url.pathExtension.lowercased()

        // First check by extension
        if imageTypes.contains(fileExtension) {
            return true
        }

        // Fallback: check UTI (Uniform Type Identifier)
        if #available(macOS 11.0, *) {
            if let uti = UTType(filenameExtension: fileExtension) {
                return uti.conforms(to: .image)
            }
        }

        return false
    }

    private func updateNavigationState() {
        let homeDirectory = fileManager.homeDirectoryForCurrentUser
        canNavigateUp = currentDirectory.path != homeDirectory.path &&
                       currentDirectory.pathComponents.count > homeDirectory.pathComponents.count
    }

    // Convenience method for keyboard navigation
    func selectNextImage(after currentURL: URL?) -> URL? {
        let imageURLs = items.filter { !isDirectory($0) }

        guard !imageURLs.isEmpty else { return nil }

        if let currentURL = currentURL,
           let currentIndex = imageURLs.firstIndex(of: currentURL),
           currentIndex + 1 < imageURLs.count {
            return imageURLs[currentIndex + 1]
        }

        return imageURLs.first
    }

    func selectPreviousImage(before currentURL: URL?) -> URL? {
        let imageURLs = items.filter { !isDirectory($0) }

        guard !imageURLs.isEmpty else { return nil }

        if let currentURL = currentURL,
           let currentIndex = imageURLs.firstIndex(of: currentURL),
           currentIndex > 0 {
            return imageURLs[currentIndex - 1]
        }

        return imageURLs.last
    }
}
/*
extension DirectoryBrowserModel {
    static func forPreview() -> DirectoryBrowserModel {
        let model = PreviewDirectoryBrowserModel()
        model.items = [
            URL(fileURLWithPath: "/Users/testuser/Documents/Folder A"),
            URL(fileURLWithPath: "/Users/testuser/Documents/image1.jpg"),
            URL(fileURLWithPath: "/Users/testuser/Documents/image2.png"),
            URL(fileURLWithPath: "/Users/testuser/Documents/Folder B"),
            URL(fileURLWithPath: "/tmp/preview.png"),
        ]
        model.currentDirectory = URL(fileURLWithPath: "/Users/testuser/Documents")
        return model
    }
}

// Special preview-only subclass that overrides file system operations
private class PreviewDirectoryBrowserModel: DirectoryBrowserModel {
    private let mockDirectories: Set<String> = ["Folder A", "Folder B"]

    override func isDirectory(_ url: URL) -> Bool {
        return mockDirectories.contains(url.lastPathComponent)
    }

    override func loadCurrentDirectory() {
        // Do nothing in preview - we use the static items
    }

    override func navigateInto(directory: URL) {
        // Do nothing in preview - we use the static items
    }
}
*/

