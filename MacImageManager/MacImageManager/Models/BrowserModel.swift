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
import AVKit

class BrowserModel: ObservableObject {
    @Published var items: [FileItem] = []
    @Published var currentDirectory: URL
    @Published var canNavigateUp: Bool = false
    @Published var showingFileImporter: Bool = false
    @Published var selectedFile: FileItem?
    @Published var isRenamingFile = false
    @Published var renamingText = ""

    // Video control state
    @Published var currentVideoPlayer: AVPlayer?

    // Publisher for video actions
    let videoActionPublisher = PassthroughSubject<VideoAction, Never>()

    enum VideoAction {
        case play, pause, toggle, jumpForward, jumpBackward, restart
    }

    // Cache to speed up metadata recomputation in large directories
    private var fileItemCache: [URL: FileItem] = [:]

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

    var supportedFileCount: Int {
        items.filter { $0.mediaType != .unknown && !$0.isDirectory }.count
    }

    @MainActor func loadInitialDirectory() async {
        await loadCurrentDirectory()
    }

    @MainActor func loadCurrentDirectory() async {
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

                // Directory check moved to FileItem initialization

                // Reuse cached FileItem when unchanged to avoid recomputing
                if let cached = fileItemCache[url],
                   cached.isDirectory == isDir,
                   cached.fileSize == fileSize,
                   cached.modificationDate == modDate,
                   cached.uti == uti {
                    fileItems.append(cached)
                } else {
                    let fileItem = await FileItem(
                        url: url,
                        name: url.lastPathComponent,
                        isDirectory: isDir,
                        fileSize: fileSize,
                        modificationDate: modDate,
                        uti: uti
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
            Task {
                await loadCurrentDirectory()
            }
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
            Task {
                await loadCurrentDirectory()
            }
        } catch {
            print("Cannot access directory \(item.url.path): \(error)")
        }
    }

    func isImageFile(_ item: FileItem) -> Bool {
        return item.mediaType == .staticImage
    }

    @MainActor func openDirectory(_ item: FileItem) async {
        self.currentDirectory = item.url
        await loadCurrentDirectory()
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

    // MARK: - Menu Actions

    /// Computed property to check if a file is selected for menu state
    var hasSelectedFile: Bool {
        selectedFile != nil
    }

    /// Computed property to check if selected file is renameable
    var canRenameSelectedFile: Bool {
        guard let file = selectedFile else { return false }
        return !file.isDirectory // For now, only allow renaming files, not directories
    }

    /// Start renaming the currently selected file
    func startRenamingSelectedFile() {
        guard let file = selectedFile else { return }
        renamingText = file.name
        isRenamingFile = true
    }

    /// Complete the rename operation
    func completeRename() {
        guard let file = selectedFile, !renamingText.isEmpty else {
            cancelRename()
            return
        }

        let newURL = file.url.deletingLastPathComponent().appendingPathComponent(renamingText)

        do {
            try FileManager.default.moveItem(at: file.url, to: newURL)

            // Update the file item in our list
            if let index = items.firstIndex(where: { $0.url == file.url }) {
                Task {
                    let updatedItem = await FileItem(
                        url: newURL,
                        name: renamingText,
                        isDirectory: file.isDirectory,
                        fileSize: file.fileSize,
                        modificationDate: file.modificationDate,
                        uti: file.uti
                    )
                    await MainActor.run {
                        items[index] = updatedItem
                        selectedFile = updatedItem

                        // Update cache
                        fileItemCache.removeValue(forKey: file.url)
                        fileItemCache[newURL] = updatedItem
                    }
                }
            }

            print("Successfully renamed \(file.name) to \(renamingText)")
        } catch {
            print("Failed to rename file: \(error.localizedDescription)")
        }

        cancelRename()
    }

    /// Cancel the rename operation
    func cancelRename() {
        isRenamingFile = false
        renamingText = ""
    }

    /// Delete the currently selected file
    func deleteSelectedFile() {
        guard let file = selectedFile else { return }

        do {
            try FileManager.default.trashItem(at: file.url, resultingItemURL: nil)

            // Remove from our list
            items.removeAll { $0.url == file.url }
            fileItemCache.removeValue(forKey: file.url)
            selectedFile = nil

            print("Successfully moved \(file.name) to trash")
        } catch {
            print("Failed to delete file: \(error.localizedDescription)")
        }
    }

    /// Show selected file in Finder
    func showSelectedFileInFinder() {
        guard let file = selectedFile else { return }
        NSWorkspace.shared.selectFile(file.url.path, inFileViewerRootedAtPath: "")
    }

    // MARK: - Video Control Actions

    /// Toggle video playback (play/pause)
    func toggleVideoPlayback() {
        videoActionPublisher.send(.toggle)
    }

    /// Play video
    func playVideo() {
        videoActionPublisher.send(.play)
    }

    /// Pause video
    func pauseVideo() {
        videoActionPublisher.send(.pause)
    }

    /// Jump forward 10 seconds
    func jumpVideoForward() {
        videoActionPublisher.send(.jumpForward)
    }

    /// Jump backward 10 seconds
    func jumpVideoBackward() {
        videoActionPublisher.send(.jumpBackward)
    }

    /// Restart video from beginning
    func restartVideo() {
        videoActionPublisher.send(.restart)
    }

    /// Set the current video player reference
    func setVideoPlayer(_ player: AVPlayer?) {
        currentVideoPlayer = player
    }

    /// Check if we currently have a video playing
    var hasVideoPlayer: Bool {
        currentVideoPlayer != nil
    }

    /// Check if current selection is a video file
    var selectedFileIsVideo: Bool {
        selectedFile?.mediaType == .video
    }
}
