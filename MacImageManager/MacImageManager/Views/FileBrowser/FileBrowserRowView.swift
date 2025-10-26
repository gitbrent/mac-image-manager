//
//  FileBrowserRowView.swift
//  MacImageManager
//
//  Created by Brent Ely on 9/22/25.
//

import SwiftUI
import UniformTypeIdentifiers
import AppKit

struct FileBrowserRowView: View {
    @EnvironmentObject var browserModel: BrowserModel
    @FocusState private var isTextFieldFocused: Bool
    let item: FileItem

    var body: some View {
        HStack {
            Image(systemName: item.iconName)
                .font(.system(size: 24))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(item.tintColor)
                .frame(width: 32, height: 32)

            if browserModel.isRenamingFile && browserModel.selectedFile?.id == item.id {
                // Rename mode: just show centered TextField
                RenameTextField(
                    text: $browserModel.renamingText,
                    isTextFieldFocused: $isTextFieldFocused,
                    onSubmit: { browserModel.completeRename() },
                    onCancel: { browserModel.cancelRename() }
                )
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
            .keyboardShortcut(.return, modifiers: [])
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
}

struct RenameTextField: NSViewRepresentable {
    @Binding var text: String
    var isTextFieldFocused: FocusState<Bool>.Binding
    let onSubmit: () -> Void
    let onCancel: () -> Void

    func makeNSView(context: Context) -> NSTextField {
        let textField = NSTextField()
        textField.stringValue = text
        textField.delegate = context.coordinator
        textField.target = context.coordinator
        textField.action = #selector(Coordinator.textFieldAction)

        // Auto-select filename without extension
        DispatchQueue.main.async {
            textField.becomeFirstResponder()

            if let dotIndex = text.lastIndex(of: "."),
               dotIndex > text.startIndex {
                let filename = String(text[..<dotIndex])
                textField.currentEditor()?.selectedRange = NSRange(location: 0, length: filename.count)
            } else {
                textField.selectText(nil)
            }
        }

        return textField
    }

    func updateNSView(_ nsView: NSTextField, context: Context) {
        if nsView.stringValue != text {
            nsView.stringValue = text
        }

        if isTextFieldFocused.wrappedValue && nsView.window?.firstResponder != nsView.currentEditor() {
            nsView.becomeFirstResponder()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, NSTextFieldDelegate {
        let parent: RenameTextField

        init(_ parent: RenameTextField) {
            self.parent = parent
        }

        @objc func textFieldAction() {
            parent.onSubmit()
        }

        func controlTextDidChange(_ obj: Notification) {
            if let textField = obj.object as? NSTextField {
                parent.text = textField.stringValue
            }
        }

        func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            if commandSelector == #selector(NSResponder.cancelOperation(_:)) {
                parent.onCancel()
                return true
            }
            return false
        }
    }
}

#Preview {
    FileBrowserRowView(item: BrowserModel.preview.items.first!)
        .environmentObject(BrowserModel.preview)
        .frame(width: 300)
}
