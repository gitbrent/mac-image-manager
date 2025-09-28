//
//  FileBrowserRowView.swift
//  MacImageManager
//
//  Created by Brent Ely on 9/22/25.
//

import SwiftUI

struct FileBrowserRowView: View {
    @EnvironmentObject var browserModel: BrowserModel
    let item: FileItem

    var body: some View {
        HStack {
            Image(systemName: item.iconName)
                .font(.system(size: 24))
                .foregroundColor(item.isDirectory ? .blue : .orange)
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
}

#Preview {
    FileBrowserRowView(item: BrowserModel.preview.items.first!)
        .environmentObject(BrowserModel.preview)
        .frame(width: 300)
}
