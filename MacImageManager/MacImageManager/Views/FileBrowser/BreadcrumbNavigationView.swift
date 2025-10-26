//
//  BreadcrumbNavigationView.swift
//  MacImageManager
//
//  Created by Brent Ely on 10/5/25.
//

import SwiftUI

struct BreadcrumbNavigationView: View {
    @ObservedObject var browserModel: BrowserModel
    @State private var showingPathDropdown = false
    @State private var showingVolumeMenu = false

    var body: some View {
        HStack(spacing: 8) {
            // Volume selector button
            Button(action: {
                showingVolumeMenu.toggle()
            }) {
                HStack(spacing: 4) {
                    if let firstComponent = browserModel.pathComponents.first,
                       firstComponent.isVolume {
                        Image(systemName: firstComponent.icon)
                            .font(.system(size: 14))
                            .foregroundColor(.primary)
                    } else {
                        Image(systemName: "internaldrive")
                            .font(.system(size: 14))
                            .foregroundColor(.primary)
                    }

                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(4)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Select volume")
            .accessibilityHint("Choose a different storage volume to browse")
            .help("Select volume")
            .popover(isPresented: $showingVolumeMenu) {
                VolumeMenuView(browserModel: browserModel, isPresented: $showingVolumeMenu)
            }

            // Full-length path dropdown
            Button(action: {
                showingPathDropdown.toggle()
            }) {
                HStack(spacing: 6) {
                    // Current directory icon
                    if let currentComponent = browserModel.pathComponents.last {
                        Image(systemName: currentComponent.icon)
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }

                    // Full path text
                    Text(fullPathText)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .truncationMode(.middle)

                    Spacer()

                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .frame(maxWidth: 400, alignment: .leading)
                .background(Color.secondary.opacity(0.05))
                .cornerRadius(4)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Navigate to parent folder")
            .accessibilityHint("Show path hierarchy and navigate to parent directories")
            .accessibilityValue(fullPathText)
            .help("Select volume location")
            .popover(isPresented: $showingPathDropdown) {
                PathDropdownView(browserModel: browserModel, isPresented: $showingPathDropdown)
            }
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    private var fullPathText: String {
        let components = browserModel.pathComponents
        if components.isEmpty {
            return "/"
        }

        // Show only the current directory name
        if let currentComponent = components.last {
            return currentComponent.name
        }

        return "/"
    }
}

struct VolumeMenuView: View {
    @ObservedObject var browserModel: BrowserModel
    @Binding var isPresented: Bool
    @State private var selectedVolumeIndex: Int = 0
    @FocusState private var isFocused: Bool

    private var currentVolumeIndex: Int {
        let currentVolumeURL = browserModel.volumeManager.getVolumeInfo(for: browserModel.currentDirectory)?.url
        return browserModel.volumeManager.volumes.firstIndex { $0.url == currentVolumeURL } ?? 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("Volumes")
                    .font(.headline)
                    .foregroundColor(.primary)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            Divider()

            // Volume list
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(browserModel.volumeManager.volumes.enumerated()), id: \.element.url) { index, volume in
                        let isCurrentVolume = browserModel.volumeManager.getVolumeInfo(for: browserModel.currentDirectory)?.url == volume.url

                        Button(action: {
                            browserModel.navigateToVolume(volume)
                            isPresented = false
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: volume.icon)
                                    .font(.system(size: 16))
                                    .foregroundColor(.primary)
                                    .frame(width: 20)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(volume.name)
                                        .font(.system(size: 13, weight: isCurrentVolume ? .semibold : .medium))
                                        .foregroundColor(.primary)

                                    if let freeSpace = volume.freeSpace,
                                       let totalSpace = volume.totalSpace {
                                        let freeGB = Double(freeSpace) / 1_000_000_000
                                        let totalGB = Double(totalSpace) / 1_000_000_000
                                        Text("\(String(format: "%.1f", freeGB)) GB free of \(String(format: "%.1f", totalGB)) GB")
                                            .font(.system(size: 11))
                                            .foregroundColor(.secondary)
                                    } else {
                                        Text(volume.type.displayName)
                                            .font(.system(size: 11))
                                            .foregroundColor(.secondary)
                                    }
                                }

                                Spacer()

                                if isCurrentVolume {
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
                        .accessibilityLabel(volume.name)
                        .accessibilityHint(isCurrentVolume ? "Currently selected volume" : "Navigate to \(volume.name)")
                        .accessibilityAddTraits(isCurrentVolume ? [.isSelected] : [])
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(
                                    index == selectedVolumeIndex && isFocused
                                        ? Color.secondary.opacity(0.2)
                                        : (isCurrentVolume ? Color.blue.opacity(0.1) : Color.clear)
                                )
                        )
                        .onHover { isHovering in
                            if isHovering {
                                selectedVolumeIndex = index
                            }
                        }
                        .animation(.easeInOut(duration: 0.1), value: selectedVolumeIndex)
                        .animation(.easeInOut(duration: 0.1), value: isCurrentVolume)
                    }
                }
            }
            .frame(maxHeight: 300)
        }
        .frame(minWidth: 280, maxWidth: 320)
        .focused($isFocused)
        .onAppear {
            selectedVolumeIndex = currentVolumeIndex
            isFocused = true
        }
        .onKeyPress(.upArrow) {
            if selectedVolumeIndex > 0 {
                selectedVolumeIndex -= 1
            }
            return .handled
        }
        .onKeyPress(.downArrow) {
            if selectedVolumeIndex < browserModel.volumeManager.volumes.count - 1 {
                selectedVolumeIndex += 1
            }
            return .handled
        }
        .onKeyPress(.return) {
            let selectedVolume = browserModel.volumeManager.volumes[selectedVolumeIndex]
            browserModel.navigateToVolume(selectedVolume)
            isPresented = false
            return .handled
        }
        .onKeyPress(.escape) {
            isPresented = false
            return .handled
        }
    }
}

struct PathDropdownView: View {
    @ObservedObject var browserModel: BrowserModel
    @Binding var isPresented: Bool
    @State private var selectedPathIndex: Int = 0
    @FocusState private var isFocused: Bool

    private var currentPathIndex: Int {
        return browserModel.pathComponents.count - 1
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            headerView
            Divider()
            pathListView
        }
        .frame(minWidth: 250, idealWidth: 300)
        .focused($isFocused)
        .onAppear {
            selectedPathIndex = currentPathIndex
            isFocused = true
        }
        .onKeyPress(.upArrow) {
            if selectedPathIndex > 0 {
                selectedPathIndex -= 1
            }
            return .handled
        }
        .onKeyPress(.downArrow) {
            if selectedPathIndex < browserModel.pathComponents.count - 1 {
                selectedPathIndex += 1
            }
            return .handled
        }
        .onKeyPress(.return) {
            let selectedComponent = browserModel.pathComponents[selectedPathIndex]
            browserModel.navigateToPathComponent(selectedComponent)
            isPresented = false
            return .handled
        }
        .onKeyPress(.escape) {
            isPresented = false
            return .handled
        }
    }

    private var headerView: some View {
        HStack {
            Text("Location")
                .font(.headline)
                .foregroundColor(.primary)
                .accessibilityAddTraits(.isHeader)
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private var pathListView: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(Array(browserModel.pathComponents.enumerated()), id: \.element.url) { index, component in
                    PathComponentRow(
                        component: component,
                        index: index,
                        totalCount: browserModel.pathComponents.count,
                        selectedIndex: selectedPathIndex,
                        isFocused: isFocused,
                        onTap: {
                            browserModel.navigateToPathComponent(component)
                            isPresented = false
                        },
                        onHover: { isHovering in
                            if isHovering {
                                selectedPathIndex = index
                            }
                        }
                    )
                }
            }
        }
        .frame(idealHeight: 200, maxHeight: 500)
    }
}

// MARK: - Helper Components

struct PathComponentRow: View {
    let component: PathComponent
    let index: Int
    let totalCount: Int
    let selectedIndex: Int
    let isFocused: Bool
    let onTap: () -> Void
    let onHover: (Bool) -> Void

    private var isCurrentLocation: Bool {
        index == totalCount - 1
    }

    var body: some View {
        Button(action: onTap) {
            rowContent
        }
        .buttonStyle(.plain)
        .accessibilityLabel(component.name)
        .accessibilityHint(isCurrentLocation ? "Current location" : "Navigate to \(component.name)")
        .accessibilityAddTraits(isCurrentLocation ? [.isSelected] : [])
        .background(backgroundView)
        .onHover(perform: onHover)
        .animation(.easeInOut(duration: 0.1), value: selectedIndex)
        .animation(.easeInOut(duration: 0.1), value: isCurrentLocation)
    }

    private var rowContent: some View {
        HStack(spacing: 8) {
            Image(systemName: component.icon)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .frame(width: 16)

            Text(component.name)
                .font(.system(size: 13, weight: isCurrentLocation ? .semibold : .medium))
                .foregroundColor(isCurrentLocation ? .primary : .secondary)
                .lineLimit(1)
                .truncationMode(.middle)

            Spacer()

            /*if !isCurrentLocation {
                levelIndicator
            }*/

            if isCurrentLocation {
                currentLocationIndicator
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }

    private var levelIndicator: some View {
        Text("Level \(totalCount - index - 1)")
            .font(.system(size: 10))
            .foregroundColor(.secondary.opacity(0.6))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(3)
    }

    private var currentLocationIndicator: some View {
        Image(systemName: "checkmark")
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(.blue)
            .accessibilityLabel("Current location")
    }

    private var backgroundView: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(
                index == selectedIndex && isFocused
                    ? Color.secondary.opacity(0.2)
                    : (isCurrentLocation ? Color.blue.opacity(0.1) : Color.clear)
            )
    }
}

#Preview {
    struct BreadcrumbPreviewContainer: View {
        @StateObject private var browserModel = BrowserModel.preview

        var body: some View {
            VStack {
                BreadcrumbNavigationView(browserModel: browserModel)
                    .padding()
                Spacer()
            }
        }
    }

    return BreadcrumbPreviewContainer()
        .frame(width: 400, height: 200)
}
