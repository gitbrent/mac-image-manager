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
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        HStack {
            Image(systemName: item.iconName)
                .font(.system(size: 24))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(tint(for: item))
                .frame(width: 32, height: 32)

            if browserModel.isRenamingFile && browserModel.selectedFile?.id == item.id {
                // Rename mode: just show centered TextField
                TextField("File name", text: $browserModel.renamingText)
                    .textFieldStyle(.roundedBorder)
                    .focused($isTextFieldFocused)
                    .onAppear {
                        // Auto-focus the text field
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            isTextFieldFocused = true
                        }
                    }
                    .onSubmit {
                        browserModel.completeRename()
                    }
                    .onExitCommand {
                        browserModel.cancelRename()
                    }
            } else {
                // Normal mode: show name, date, and file size
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
        }
        .padding(.vertical, 2)
        .contextMenu {
            Button(item.isDirectory ? "Rename Folder" : "Rename File") {
                // Set this item as selected and start renaming
                browserModel.selectedFile = item
                browserModel.startRenamingSelectedFile()
            }
            .keyboardShortcut("r", modifiers: .command)
            .disabled(item.isDirectory) // TODO: For now, disable directory renaming

            Button("Delete") {
                browserModel.selectedFile = item
                browserModel.deleteSelectedFile()
            }
            .keyboardShortcut(.delete)

            Divider()

            Button("Show in Finder") {
                browserModel.showSelectedFileInFinder()
            }
            .keyboardShortcut("r", modifiers: [.command, .shift])

            if item.mediaType == .video {
                Divider()

                Button("Play/Pause") {
                    browserModel.selectedFile = item
                    browserModel.toggleVideoPlayback()
                }
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
