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

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 1: Navigation header
            NavigationHeader(browserModel: browserModel)
            // 2: divider
            Divider()
            // 3: File list
            List(browserModel.items, id: \.id, selection: $selectedImage) { item in
                FileBrowserRowView(item: item)
                    .environmentObject(browserModel)
                    .tag(item)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if item.isDirectory {
                            browserModel.navigateInto(item: item)
                        } else {
                            selectedImage = item
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

            Text("\(browserModel.imageCount) images")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}

private struct PaneFileBrowserPreviewContainer: View {
    @StateObject private var model = BrowserModel.preview
    @State private var selectedImage: FileItem?

    var body: some View {
        PaneFileBrowserView(selectedImage: $selectedImage)
            .environmentObject(model)
    }
}

#Preview {
    PaneFileBrowserPreviewContainer()
        .frame(width: 300, height: 400)
}
