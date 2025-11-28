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

enum SortCriteria: String, CaseIterable, Identifiable {
    case name = "Name"
    case size = "Size"
    case date = "Date"

    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .name: return "textformat"
        case .size: return "chart.bar"
        case .date: return "calendar"
        }
    }
}

class BrowserModel: ObservableObject {
    @Published var items: [FileItem] = []
    @Published var currentDirectory: URL
    @Published var canNavigateUp: Bool = false
    @Published var showingFileImporter: Bool = false
    @Published var selectedFile: FileItem?
    @Published var isRenamingFile = false
    @Published var renamingText = ""
    @Published var currentVideoPlayer: AVPlayer?
    @Published var shouldFocusSearchField = false
    @Published var pathComponents: [PathComponent] = []
    @Published var sortBy: SortCriteria = .name
    @Published var sortAscending: Bool = true

    enum VideoAction {
        case play, pause, toggle, jumpForward, jumpBackward, restart
    }

    enum GifAction {
        case playPause, nextFrame, previousFrame
    }

    // Cache to speed up metadata recomputation in large directories
    private var fileItemCache: [URL: FileItem] = [:]

    // Volume manager for breadcrumb navigation
    @Published var volumeManager = VolumeManager()

    // Publishers for video and GIF control actions
    let videoActionPublisher = PassthroughSubject<VideoAction, Never>()
    let gifActionPublisher = PassthroughSubject<GifAction, Never>()

    private let fileManager = FileManager.default

    // Helper function to determine if a file could be a media file using UTType
    private func isPotentialMediaFile(_ item: FileItem) -> Bool {
        // If we have a UTType, check if it's media-related or if it's nil (unknown)
        guard let uti = item.uti else {
            // No UTType means the system couldn't identify it - could be a media file without proper extension
            return true
        }

        // Allow known media types
        if uti.conforms(to: .image) || uti.conforms(to: .movie) || uti.conforms(to: .audiovisualContent) {
            return true
        }

        // Explicitly exclude known non-media types
        if uti.conforms(to: .sourceCode) ||
           uti.conforms(to: .json) ||
           uti.conforms(to: .xml) ||
           uti.conforms(to: .plainText) ||
           uti.conforms(to: .archive) ||
           uti.conforms(to: .executable) ||
           uti.conforms(to: .application) {
            return false
        }

        // If it's an unknown type that doesn't conform to known non-media types, allow it
        // This covers potential media files with unusual extensions or no extensions
        return true
    }

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

    var folderCount: Int {
        items.filter { $0.isDirectory }.count
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

            // Filter to only show directories and potential media files
            let filteredItems = fileItems.filter { item in
                // Always show directories for navigation
                if item.isDirectory {
                    return true
                }

                // Show files that could be media files using UTType
                return isPotentialMediaFile(item)
            }

            // Sort the filtered items before assigning
            self.items = sortItems(filteredItems)
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

    // MARK: - Sorting

    /// Sort items based on current sort criteria and direction
    func sortItems(_ items: [FileItem]) -> [FileItem] {
        let sorted = items.sorted { item1, item2 in
            // Always keep directories at the top, sorted by name
            if item1.isDirectory && !item2.isDirectory {
                return true
            } else if !item1.isDirectory && item2.isDirectory {
                return false
            } else if item1.isDirectory && item2.isDirectory {
                return item1.name.localizedCaseInsensitiveCompare(item2.name) == .orderedAscending
            }

            // Sort files based on criteria
            switch sortBy {
            case .name:
                let comparison = item1.name.localizedCaseInsensitiveCompare(item2.name)
                return sortAscending ? comparison == .orderedAscending : comparison == .orderedDescending
            case .size:
                return sortAscending ? item1.fileSize < item2.fileSize : item1.fileSize > item2.fileSize
            case .date:
                return sortAscending ? item1.modificationDate < item2.modificationDate : item1.modificationDate > item2.modificationDate
            }
        }
        return sorted
    }

    /// Update sort criteria and re-sort items
    func setSortCriteria(_ criteria: SortCriteria) {
        sortBy = criteria
        items = sortItems(items)
    }

    /// Toggle sort direction and re-sort items
    func toggleSortDirection() {
        sortAscending.toggle()
        items = sortItems(items)
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

        // Update path components for breadcrumb navigation
        updatePathComponents()
    }

    private func updatePathComponents() {
        pathComponents = volumeManager.generatePathComponents(for: currentDirectory)
    }

    // Navigate to a specific path component (breadcrumb navigation)
    func navigateToPathComponent(_ component: PathComponent) {
        currentDirectory = component.url
        Task {
            await loadCurrentDirectory()
        }
    }

    // Get sibling directories for dropdown functionality
    func getSiblingDirectories(for component: PathComponent) async -> [FileItem] {
        return await volumeManager.getSiblingDirectories(for: component.url)
    }

    // Navigate to a different volume
    func navigateToVolume(_ volume: VolumeInfo) {
        currentDirectory = volume.url
        Task {
            await loadCurrentDirectory()
        }
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

    /// Focus the search field in the browser
    func focusSearchField() {
        shouldFocusSearchField = true
        // Reset the flag after a short delay to allow for repeated triggers
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.shouldFocusSearchField = false
        }
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

        // Validate the filename
        guard isValidFilename(renamingText) else {
            cancelRename()
            return
        }

        // Check if the name hasn't actually changed
        guard renamingText != file.name else {
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

                        // Cancel rename mode after UI is updated
                        cancelRename()
                    }
                }
            } else {
                // If item not found in list, still cancel rename mode
                cancelRename()
            }

            print("Successfully renamed \(file.name) to \(renamingText)")
        } catch {
            print("Failed to rename file: \(error.localizedDescription)")
            cancelRename()
        }
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

    // MARK: - GIF Control Actions

    /// Toggle GIF playback (play/pause)
    func toggleGifPlayback() {
        gifActionPublisher.send(.playPause)
    }

    /// Go to next GIF frame
    func nextGifFrame() {
        gifActionPublisher.send(.nextFrame)
    }

    /// Go to previous GIF frame
    func previousGifFrame() {
        gifActionPublisher.send(.previousFrame)
    }

    /// Check if current selection is a GIF file
    var selectedFileIsGif: Bool {
        selectedFile?.mediaType == .animatedGif
    }

    /// Validate filename for macOS compatibility
    private func isValidFilename(_ filename: String) -> Bool {
        let trimmedName = filename.trimmingCharacters(in: .whitespacesAndNewlines)

        // Check for empty or whitespace-only names
        guard !trimmedName.isEmpty else { return false }

        // Check if it's just an extension (starts with .)
        guard !trimmedName.hasPrefix(".") else { return false }

        // Check filename length (macOS limit is 255 bytes, but we'll use a conservative limit)
        guard trimmedName.count <= 255 else { return false }

        // Check for invalid characters on macOS
        // macOS is more permissive than Windows, but these are still problematic
        let invalidCharacters = CharacterSet(charactersIn: ":\0")
        guard trimmedName.rangeOfCharacter(from: invalidCharacters) == nil else { return false }

        // Check for names that are just dots
        guard trimmedName != "." && trimmedName != ".." else { return false }

        // Check for control characters (0x00-0x1F and 0x7F)
        for char in trimmedName.unicodeScalars {
            if char.value <= 0x1F || char.value == 0x7F {
                return false
            }
        }

        return true
    }
}
