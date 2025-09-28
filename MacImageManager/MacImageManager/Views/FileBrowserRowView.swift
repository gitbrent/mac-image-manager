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

#Preview {
    FileBrowserRowView(item: BrowserModel.preview.items.first!)
        .environmentObject(BrowserModel.preview)
        .frame(width: 300)
}
