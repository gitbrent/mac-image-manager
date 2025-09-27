//
//  PaneFileBrowserView.swift
//  MacImageManager
//
//  Created by Brent Ely on 9/22/25.
//

import SwiftUI

struct PaneFileBrowserView: View {
    @EnvironmentObject var browserModel: BrowserModel
    @Binding var selectedImage: URL?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 1: Navigation header
            NavigationHeader(browserModel: browserModel)
            // 2: divider
            Divider()
            // 3: File list
            List(browserModel.items, id: \.self, selection: $selectedImage) { item in
                FileBrowserRowView(url: item)
                    .environmentObject(browserModel)
                    .tag(item)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if browserModel.isDirectory(item) {
                            browserModel.navigateInto(directory: item)
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

    var body: some View {
        PaneFileBrowserView(selectedImage: .constant(nil))
            .environmentObject(model)
    }
}

#Preview {
    PaneFileBrowserPreviewContainer()
        .environmentObject(BrowserModel.preview)
        .frame(width: 300, height: 400)
}
