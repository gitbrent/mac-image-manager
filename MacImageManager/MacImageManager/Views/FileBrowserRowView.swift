//
//  FileBrowserRowView.swift
//  MacImageManager
//
//  Created by Brent Ely on 9/22/25.
//

import SwiftUI

struct FileBrowserRowView: View {
    let item: FileItem
    @EnvironmentObject var browserModel: BrowserModel

    var body: some View {
        HStack {
            Image(systemName: item.iconName)
                .font(.system(size: 24))
                .foregroundColor(item.isDirectory ? .blue : .orange)
                .frame(width: 32, height: 32)

            VStack(alignment: .leading) {
                Text(item.name)
                    .lineLimit(1)
                Text(item.url.path)
                    .lineLimit(1)
                    .foregroundColor(.gray)
            }

            Spacer()
        }
        .padding(.vertical, 2)
        .contextMenu {
            Button(item.isDirectory ? "Rename Folder" : "Rename File") {
                if item.isDirectory {
                    print("TODO: Rename directory functionality")
                    //browserModel.navigateInto(item: item)
                } else {
                    print("TODO: Rename file functionality")
                    // This could be a new method in your model or a simple action here
                }
            }
            // TODO: Add other menu items as needed
            Divider()

            Button("Rename") {
                print("TODO: Implement rename functionality")
            }

            Button("Get Info") {
                print("TODO: Implement get info functionality")
            }
        }
    }
}

/*
struct FileRowView_Previews: PreviewProvider {
    static var previews: some View {
        FileBrowserRowView(
            url: URL(fileURLWithPath: "/tmp/preview.png"),
            browserModel: BrowserModel.preview
        )
        .padding()
    }
}
*/
/*
#Preview {
    Group {
        // Preview an image row
        FileBrowserRowView(
            url: Bundle.main.resourceURL!.appendingPathComponent("preview1.png"),
            browserModel: BrowserModel.preview
        )

        // Preview a folder row
        FileBrowserRowView(
            url: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0],
            browserModel: BrowserModel.preview
        )
    }
    .padding()
}
*/

/// ====================

private struct FileBrowserRowViewPreviewContainer: View {
    @StateObject private var model = BrowserModel.preview

    var body: some View {
        VStack(spacing: 20) {
            // Preview a folder
            FileBrowserRowView(item: model.items.first { $0.isDirectory }!)

            // Preview an image
            FileBrowserRowView(item: model.items.first { model.isImageFile($0) }!)

            // Preview a document
            FileBrowserRowView(item: model.items.first { !$0.isDirectory && !model.isImageFile($0) }!)
        }
        .environmentObject(model)
        .padding()
    }
}

#Preview {
    FileBrowserRowViewPreviewContainer()
        .frame(width: 300)
}
