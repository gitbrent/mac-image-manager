//
//  FileBrowserRowView.swift
//  MacImageManager
//
//  Created by Brent Ely on 9/22/25.
//

import SwiftUI
import UniformTypeIdentifiers

struct FileBrowserRowView: View {
    @EnvironmentObject var browserModel: BrowserModel
    let item: FileItem

    var body: some View {
        HStack {
            Image(systemName: item.iconName)
                .font(.system(size: 24))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(tint(for: item))
                .frame(width: 32, height: 32)

            VStack(alignment: .leading) {
                Text(item.name)
                    .lineLimit(1)
                Text(item.modificationDate.formatted(date: .abbreviated, time: .shortened))
                    .lineLimit(1)
                    .foregroundColor(.gray)
            }

            Spacer() // NOTE: push content left

            if !item.isDirectory {
                Text(item.formattedFileSize)
                    .frame(minWidth: 70, alignment: .trailing)
                    .foregroundColor(.gray)
                    .font(.system(size: 12))
            }
        }
        .padding(.vertical, 2)
        .contextMenu {
            Button(item.isDirectory ? "Rename Folder" : "Rename File") {
                if item.isDirectory {
                    print("FUTURE: Rename directory functionality")
                    //browserModel.navigateInto(item: item)
                } else {
                    print("FUTURE: Rename file functionality")
                    // This could be a new method in your model or a simple action here
                }
            }
            // FUTURE: Add other menu items as needed
            Divider()

            Button("Rename") {
                print("FUTURE: Implement rename functionality")
            }

            Button("Get Info") {
                print("FUTURE: Implement get info functionality")
            }
        }
    }
    
    private func tint(for item: FileItem) -> Color {
        if item.isDirectory { return .blue }
        guard let type = item.uti else { return .secondary }

        if type == .livePhoto { return .yellow }
        if type.conforms(to: .gif) { return .pink }
        if type == .svg { return .green }
        if type.conforms(to: .rawImage) { return .indigo }
        if type == .heic || type == .heif { return .orange }
        if type.conforms(to: .image) { return .teal }
        if type.conforms(to: .movie) { return .red }
        if type == .pdf { return .brown }
        if type.conforms(to: .archive) { return .brown }
        if type.conforms(to: .audio) { return .mint }
        if type.conforms(to: .json) { return .cyan }
        if type.conforms(to: .sourceCode) { return .gray }
        if type.conforms(to: .plainText) { return .gray }

        return .secondary
    }
}

#Preview {
    FileBrowserRowView(item: BrowserModel.preview.items.first!)
        .environmentObject(BrowserModel.preview)
        .frame(width: 300)
}
