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
    @State private var showingSortMenu = false

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
            // Navigation header with breadcrumb, search, and sort controls
            VStack(spacing: 8) {
                // Breadcrumb navigation
                BreadcrumbNavigationView(browserModel: browserModel)

                // Search and Sort controls in same row
                HStack(spacing: 8) {
                    // Sort button
                    Button(action: {
                        showingSortMenu.toggle()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: browserModel.sortBy.iconName)
                                .font(.system(size: 14))
                            Image(systemName: "chevron.down")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        .foregroundColor(.primary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(4)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Sorting options")
                    .accessibilityHint("Choose a different sorting criteria and direction")
                    .help("Sort options")
                    .popover(isPresented: $showingSortMenu) {
                        SortMenuView(browserModel: browserModel, isPresented: $showingSortMenu)
                    }

                    // Search field
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
            .padding(.top, 2)
            .padding(.bottom, 8)

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
                                        isSearchFieldFocused = false
                                        isListFocused = true
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
                                    isSearchFieldFocused = false
                                    isListFocused = true
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
                        // Unfocus search field when navigating
                        isSearchFieldFocused = false
                        isListFocused = true
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

            // File count display at bottom - breakdown by type
            Divider()
            FileMetricsView()
                .environmentObject(browserModel)
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

struct SortMenuView: View {
    @ObservedObject var browserModel: BrowserModel
    @Binding var isPresented: Bool
    @State private var selectedIndex: Int = 0
    @FocusState private var isFocused: Bool

    private var currentSortIndex: Int {
        if let index = SortCriteria.allCases.firstIndex(of: browserModel.sortBy) {
            return index + (browserModel.sortAscending ? 0 : SortCriteria.allCases.count)
        }
        return 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("Sort Options")
                    .font(.headline)
                    .foregroundColor(.primary)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            Divider()

            // Sort criteria list
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(SortCriteria.allCases.enumerated()), id: \.element) { index, criteria in
                        let isSelected = browserModel.sortBy == criteria

                        Button(action: {
                            browserModel.setSortCriteria(criteria)
                            isPresented = false
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: criteria.iconName)
                                    .font(.system(size: 16))
                                    .foregroundColor(.primary)
                                    .frame(width: 20)

                                Text(criteria.rawValue)
                                    .font(.system(size: 13, weight: isSelected ? .semibold : .medium))
                                    .foregroundColor(.primary)

                                Spacer()

                                if isSelected {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.blue)
                                        .accessibilityLabel("Currently selected")
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(criteria.rawValue)
                        .accessibilityHint(isSelected ? "Currently selected sort criteria" : "Sort by \(criteria.rawValue)")
                        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(
                                    index == selectedIndex && isFocused && selectedIndex < SortCriteria.allCases.count
                                        ? Color.secondary.opacity(0.2)
                                        : (isSelected ? Color.blue.opacity(0.1) : Color.clear)
                                )
                        )
                        .onHover { isHovering in
                            if isHovering {
                                selectedIndex = index
                            }
                        }
                        .animation(.easeInOut(duration: 0.1), value: selectedIndex)
                        .animation(.easeInOut(duration: 0.1), value: isSelected)
                    }

                    Divider()
                        .padding(.vertical, 4)

                    // Ascending option
                    Button(action: {
                        if !browserModel.sortAscending {
                            browserModel.toggleSortDirection()
                        }
                        isPresented = false
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "chevron.up")
                                .font(.system(size: 16))
                                .foregroundColor(.primary)
                                .frame(width: 20)

                            Text("Ascending")
                                .font(.system(size: 13, weight: browserModel.sortAscending ? .semibold : .medium))
                                .foregroundColor(.primary)

                            Spacer()

                            if browserModel.sortAscending {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.blue)
                                    .accessibilityLabel("Currently selected")
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Ascending")
                    .accessibilityHint(browserModel.sortAscending ? "Currently selected order" : "Sort in ascending order")
                    .accessibilityAddTraits(browserModel.sortAscending ? [.isSelected] : [])
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                selectedIndex == SortCriteria.allCases.count && isFocused
                                    ? Color.secondary.opacity(0.2)
                                    : (browserModel.sortAscending ? Color.blue.opacity(0.1) : Color.clear)
                            )
                    )
                    .onHover { isHovering in
                        if isHovering {
                            selectedIndex = SortCriteria.allCases.count
                        }
                    }

                    // Descending option
                    Button(action: {
                        if browserModel.sortAscending {
                            browserModel.toggleSortDirection()
                        }
                        isPresented = false
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "chevron.down")
                                .font(.system(size: 16))
                                .foregroundColor(.primary)
                                .frame(width: 20)

                            Text("Descending")
                                .font(.system(size: 13, weight: !browserModel.sortAscending ? .semibold : .medium))
                                .foregroundColor(.primary)

                            Spacer()

                            if !browserModel.sortAscending {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.blue)
                                    .accessibilityLabel("Currently selected")
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Descending")
                    .accessibilityHint(!browserModel.sortAscending ? "Currently selected order" : "Sort in descending order")
                    .accessibilityAddTraits(!browserModel.sortAscending ? [.isSelected] : [])
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                selectedIndex == SortCriteria.allCases.count + 1 && isFocused
                                    ? Color.secondary.opacity(0.2)
                                    : (!browserModel.sortAscending ? Color.blue.opacity(0.1) : Color.clear)
                            )
                    )
                    .onHover { isHovering in
                        if isHovering {
                            selectedIndex = SortCriteria.allCases.count + 1
                        }
                    }
                }
            }
            .frame(maxHeight: 300)
        }
        .frame(minWidth: 200, maxWidth: 240)
        .focused($isFocused)
        .onAppear {
            selectedIndex = currentSortIndex
            isFocused = true
        }
        .onKeyPress(.upArrow) {
            if selectedIndex > 0 {
                selectedIndex -= 1
            }
            return .handled
        }
        .onKeyPress(.downArrow) {
            if selectedIndex < SortCriteria.allCases.count + 1 {
                selectedIndex += 1
            }
            return .handled
        }
        .onKeyPress(.return) {
            if selectedIndex < SortCriteria.allCases.count {
                browserModel.setSortCriteria(SortCriteria.allCases[selectedIndex])
            } else if selectedIndex == SortCriteria.allCases.count {
                if !browserModel.sortAscending {
                    browserModel.toggleSortDirection()
                }
            } else {
                if browserModel.sortAscending {
                    browserModel.toggleSortDirection()
                }
            }
            isPresented = false
            return .handled
        }
        .onKeyPress(.escape) {
            isPresented = false
            return .handled
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
