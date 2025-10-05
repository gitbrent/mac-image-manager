//
//  PaneFileBrowserView.swift
//  MacImageManager
//
//  Created by Brent Ely on 9/22/25.
//

import SwiftUI

enum NavigationDirection {
    case up, down
}

struct PaneFileBrowserView: View {
    @EnvironmentObject var browserModel: BrowserModel
    @Binding var selectedImage: FileItem?
    @FocusState private var isListFocused: Bool
    @FocusState private var isSearchFieldFocused: Bool
    @State private var searchText = ""

    private func clearSearch() {
        searchText = ""
        // Restore focus to the list after clearing search
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            isListFocused = true
        }
    }

    // Computed property to filter media files based on search text (excludes directories)
    private var filteredItems: [FileItem] {
        let mediaFiles = browserModel.items.filter { !$0.isDirectory }

        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return mediaFiles
        } else {
            return mediaFiles.filter { item in
                item.name.localizedCaseInsensitiveContains(searchText)
            }
        }
    }

    // Computed property for directories (for navigation) - hide when filtering
    private var directories: [FileItem] {
        // Hide directories when filtering (when search text is not empty)
        if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return []
        }
        return browserModel.items.filter { $0.isDirectory }
    }

    // Computed property for file count display
    private var fileCountText: String {
        let count = filteredItems.count
        if count == 0 {
            return "No items"
        } else if count == 1 {
            return "Found 1 item"
        } else {
            return "Found \(count) items"
        }
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 1: Navigation header with breadcrumb
            VStack(spacing: 8) {
                // Breadcrumb navigation
                BreadcrumbNavigationView(browserModel: browserModel)

                // File count display
                HStack {
                    Spacer()
                    Text("\(browserModel.supportedFileCount) items")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }

                // Search field
                HStack {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)

                        TextField("Search...", text: $searchText)
                            .textFieldStyle(.plain)
                            .focused($isSearchFieldFocused)
                            .onKeyPress(.escape) {
                                clearSearch()
                                return .handled
                            }

                        if !searchText.isEmpty {
                            Button(action: {
                                clearSearch()
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }
                            .buttonStyle(.plain)
                            .help("Clear search")
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(6)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            // 2: divider
            Divider()

            // 3: File count label
            if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                HStack {
                    Spacer()
                    Text(fileCountText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.vertical, 4)
                    Spacer()
                }
                .background(Color.secondary.opacity(0.15))
            }

            // 4: File list or no results view
            if filteredItems.isEmpty && !searchText.isEmpty {
                // No results state
                VStack(spacing: 20) {
                    Spacer()

                    // Decorative elements similar to VS Code's no results screen
                    ZStack {
                        Circle()
                            .fill(Color.secondary.opacity(0.1))
                            .frame(width: 80, height: 80)

                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 32, weight: .light))
                            .foregroundColor(.secondary)
                    }

                    VStack(spacing: 8) {
                        Text("No items match your search")
                            .font(.headline)
                            .foregroundColor(.primary)

                        Text("Sorry, no items matching \"\(searchText)\" were found.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }

                    Button("Clear search") {
                        clearSearch()
                    }
                    .buttonStyle(.bordered)

                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollViewReader { proxy in
                    List(selection: $selectedImage) {
                        // Show directories first (for navigation) - only when not filtering
                        if !directories.isEmpty {
                            ForEach(directories, id: \.id) { item in
                                FileBrowserRowView(item: item)
                                    .environmentObject(browserModel)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        browserModel.navigateInto(item: item)
                                        // Scroll to top when navigating into a directory
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                            if let firstItem = directories.first {
                                                withAnimation(.easeInOut(duration: 0.3)) {
                                                    proxy.scrollTo(firstItem.id, anchor: .top)
                                                }
                                            }
                                        }
                                    }
                            }
                        }

                        // Show filtered media files
                        ForEach(filteredItems, id: \.id) { item in
                            FileBrowserRowView(item: item)
                                .environmentObject(browserModel)
                                .tag(item)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedImage = item
                                }
                        }
                    }
                    .focused($isListFocused)
                    .onKeyPress(.upArrow) {
                        navigateToNextImage(direction: .up)
                        return .handled
                    }
                    .onKeyPress(.downArrow) {
                        navigateToNextImage(direction: .down)
                        return .handled
                    }
                    .onAppear {
                        isListFocused = true
                    }
                    .onChange(of: browserModel.isRenamingFile) { _, isRenaming in
                        // Restore focus to list when exiting rename mode
                        if !isRenaming {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                isListFocused = true
                            }
                        }
                    }
                    .onChange(of: browserModel.currentDirectory) { _, _ in
                        // Also scroll to top when using the "up" navigation button
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            let firstItem = directories.first ?? filteredItems.first
                            if let item = firstItem {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    proxy.scrollTo(item.id, anchor: .top)
                                }
                            }
                        }
                    }
                }
            }
        }
        .onChange(of: browserModel.shouldFocusSearchField) { _, shouldFocus in
            if shouldFocus {
                isSearchFieldFocused = true
            }
        }
    }

    private func navigateToNextImage(direction: NavigationDirection) {
        // Get only viewable media files (staticImage, animatedGif, and video)
        let mediaFiles = filteredItems.filter { item in
            item.mediaType == .staticImage || item.mediaType == .animatedGif || item.mediaType == .video
        }

        guard !mediaFiles.isEmpty else { return }

        // If no media is currently selected, select the first or last media based on direction
        guard let currentSelection = selectedImage,
              let currentIndex = mediaFiles.firstIndex(of: currentSelection) else {
            selectedImage = direction == .down ? mediaFiles.first : mediaFiles.last
            return
        }

        // Navigate to next/previous media file
        switch direction {
        case .down:
            if currentIndex < mediaFiles.count - 1 {
                selectedImage = mediaFiles[currentIndex + 1]
            }
            // If at the end, do nothing (don't wrap around)
        case .up:
            if currentIndex > 0 {
                selectedImage = mediaFiles[currentIndex - 1]
            }
            // If at the beginning, do nothing (don't wrap around)
        }
    }
}

private struct PaneFileBrowserPreviewContainer: View {
    @StateObject private var model = BrowserModel.preview
    @State private var selectedFile: FileItem?

    var body: some View {
        PaneFileBrowserView(selectedImage: $selectedFile)
            .environmentObject(model)
    }
}

#Preview {
    PaneFileBrowserPreviewContainer()
        .frame(width: 300, height: 400)
}
