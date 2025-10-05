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
    @State private var searchText = ""

    // Computed property to filter items based on search text
    private var filteredItems: [FileItem] {
        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return browserModel.items
        } else {
            return browserModel.items.filter { item in
                // Always show directories for navigation
                if item.isDirectory {
                    return true
                }
                // Filter files by name containing search text
                return item.name.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 1: Navigation header
            NavigationHeader(browserModel: browserModel, searchText: $searchText)
            // 2: divider
            Divider()
                        // 3: File list or no results view
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
                        Text("No files match your search")
                            .font(.headline)
                            .foregroundColor(.primary)

                        Text("Sorry, no files matching \"\(searchText)\" were found.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }

                    Button("Clear search") {
                        searchText = ""
                    }
                    .buttonStyle(.bordered)

                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollViewReader { proxy in
                    List(filteredItems, id: \.id, selection: $selectedImage) { item in
                        FileBrowserRowView(item: item)
                            .environmentObject(browserModel)
                            .tag(item)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if item.isDirectory {
                                    browserModel.navigateInto(item: item)
                                    // Scroll to top when navigating into a directory
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                        if let firstItem = filteredItems.first {
                                            withAnimation(.easeInOut(duration: 0.3)) {
                                                proxy.scrollTo(firstItem.id, anchor: .top)
                                            }
                                        }
                                    }
                                } else {
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
                            if let firstItem = filteredItems.first {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    proxy.scrollTo(firstItem.id, anchor: .top)
                                }
                            }
                        }
                    }
                }
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

struct NavigationHeader: View {
    @ObservedObject var browserModel: BrowserModel
    @Binding var searchText: String

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Button(action: {
                    browserModel.navigateUp()
                }) {
                    Image(systemName: "chevron.up")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.primary)
                }
                .buttonStyle(.plain)
                .frame(width: 24, height: 24)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(4)
                .disabled(!browserModel.canNavigateUp)
                .help("Go up one level")

                Text(browserModel.currentDirectoryName)
                    .font(.headline)
                    .lineLimit(1)
                    .truncationMode(.middle)

                Spacer()

                Text("\(browserModel.supportedFileCount) items")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            HStack {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)

                    TextField("Search files...", text: $searchText)
                        .textFieldStyle(.plain)

                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
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
