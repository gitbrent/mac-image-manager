//
//  FileBrowserRowView.swift
//  MacImageManager
//
//  Created by Brent Ely on 9/22/25.
//

import SwiftUI

struct FileBrowserRowView: View {
    let url: URL
    @EnvironmentObject var browserModel: BrowserModel

    var body: some View {
        HStack {
            Image(systemName: browserModel.isDirectory(url) ? "folder.fill" : "photo")
                .font(.system(size: 24))
                .foregroundColor(browserModel.isDirectory(url) ? .blue : .orange)
                .frame(width: 32, height: 32)

            VStack(alignment: .leading) {
                Text(url.lastPathComponent)
                    .lineLimit(1)
                Text(url.path)
                    .lineLimit(1)
                    .foregroundColor(.gray)
            }

            Spacer()
        }
        .padding(.vertical, 2)
        .contextMenu {
            Button(browserModel.isDirectory(url) ? "Rename Folder" : "Rename Image") {
                if browserModel.isDirectory(url) {
                    print("TODO: Rename directory functionality")
                    //browserModel.navigateInto(directory: url)
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
        FileBrowserRowView(url: model.items.first!)
            .environmentObject(model)
    }
}

#Preview {
    FileBrowserRowViewPreviewContainer()
        .frame(width: 300, height: 400)
}
