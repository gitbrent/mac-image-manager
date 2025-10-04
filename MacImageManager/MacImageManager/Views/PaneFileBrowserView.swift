//
//  PaneFileBrowserView.swift
//  MacImageManager
//
//  Created by Brent Ely on 9/22/25.
//

import SwiftUI

struct PaneFileBrowserView: View {
    @EnvironmentObject var browserModel: BrowserModel
    @Binding var selectedImage: FileItem?
    @FocusState private var isListFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 1: Navigation header
            NavigationHeader(browserModel: browserModel)
            // 2: divider
            Divider()
            // 3: File list
            ScrollViewReader { proxy in
                List(browserModel.items, id: \.id, selection: $selectedImage) { item in
                    FileBrowserRowView(item: item)
                        .environmentObject(browserModel)
                        .tag(item)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if item.isDirectory {
                                browserModel.navigateInto(item: item)
                                // Scroll to top when navigating into a directory
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    if let firstItem = browserModel.items.first {
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            proxy.scrollTo(firstItem.id, anchor: .top)
                                        }
                                    }
                                }
                            //} else if item.mediaType != .unknown {
                            } else {
                                selectedImage = item
                            }
                        }
                }
                .focused($isListFocused)
                .onAppear {
                    isListFocused = true
                }
                .onChange(of: browserModel.isRenamingFile) { isRenaming in
                    // Restore focus to list when exiting rename mode
                    if !isRenaming {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            isListFocused = true
                        }
                    }
                }
                .onChange(of: browserModel.currentDirectory) { _ in
                    // Also scroll to top when using the "up" navigation button
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        if let firstItem = browserModel.items.first {
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

struct NavigationHeader: View {
    @ObservedObject var browserModel: BrowserModel

    var body: some View {
        HStack {
            Button("↑") {
                browserModel.navigateUp()
            }
            .disabled(!browserModel.canNavigateUp)

            Text(browserModel.currentDirectoryName)
                .font(.headline)
                .lineLimit(1)
                .truncationMode(.middle)

            Spacer()

            Text("\(browserModel.supportedFileCount) items")
                .font(.caption)
                .foregroundColor(.secondary)
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
