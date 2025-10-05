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
            .popover(isPresented: $showingVolumeMenu) {
                VolumeMenuView(browserModel: browserModel)
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
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                .background(Color.secondary.opacity(0.05))
                .cornerRadius(4)
            }
            .buttonStyle(.plain)
            .popover(isPresented: $showingPathDropdown) {
                PathDropdownView(browserModel: browserModel)
            }
        }
    }

    private var fullPathText: String {
        let components = browserModel.pathComponents
        if components.isEmpty {
            return "/"
        }

        // Skip the volume name and show the path from the volume root
        let pathComponents = components.dropFirst()
        if pathComponents.isEmpty {
            return components.first?.name ?? "/"
        }

        return pathComponents.map { $0.name }.joined(separator: " › ")
    }
}

struct VolumeMenuView: View {
    @ObservedObject var browserModel: BrowserModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("Volumes")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            Divider()

            // Volume list
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(browserModel.volumeManager.volumes, id: \.url) { volume in
                        Button(action: {
                            browserModel.navigateToVolume(volume)
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: volume.icon)
                                    .font(.system(size: 16))
                                    .foregroundColor(.primary)
                                    .frame(width: 20)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(volume.name)
                                        .font(.system(size: 13, weight: .medium))
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
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .background(Color.secondary.opacity(0.0))
                        .onHover { isHovering in
                            // Add hover effect if needed
                        }
                    }
                }
            }
            .frame(maxHeight: 300)
        }
        .frame(minWidth: 280, maxWidth: 320)
    }
}

struct PathDropdownView: View {
    @ObservedObject var browserModel: BrowserModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("Go to")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            Divider()

            // Path levels
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(browserModel.pathComponents.enumerated()), id: \.element.url) { index, component in
                        Button(action: {
                            browserModel.navigateToPathComponent(component)
                        }) {
                            HStack(spacing: 8) {
                                // Indentation based on level
                                HStack(spacing: 0) {
                                    ForEach(0..<index, id: \.self) { _ in
                                        Rectangle()
                                            .fill(Color.clear)
                                            .frame(width: 16, height: 1)
                                    }
                                }

                                Image(systemName: component.icon)
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                                    .frame(width: 16)

                                Text(component.name)
                                    .font(.system(size: 13, weight: index == browserModel.pathComponents.count - 1 ? .semibold : .regular))
                                    .foregroundColor(index == browserModel.pathComponents.count - 1 ? .primary : .secondary)
                                    .lineLimit(1)
                                    .truncationMode(.middle)

                                Spacer()

                                if index == browserModel.pathComponents.count - 1 {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.blue)
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .background(
                            index == browserModel.pathComponents.count - 1
                                ? Color.blue.opacity(0.1)
                                : Color.clear
                        )
                        .onHover { isHovering in
                            // Could add hover effects here
                        }

                        // Add separator except for last item
                        if index < browserModel.pathComponents.count - 1 {
                            Divider()
                                .padding(.leading, CGFloat(12 + (index * 16) + 24))
                        }
                    }
                }
            }
            .frame(maxHeight: 250)
        }
        .frame(minWidth: 220, maxWidth: 350)
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
        .frame(width: 500, height: 200)
}
