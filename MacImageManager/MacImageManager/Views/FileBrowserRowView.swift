//
//  FileBrowserRowView.swift
//  MacImageManager
//
//  Created by Brent Ely on 9/22/25.
//

import SwiftUI

struct FileBrowserRowView: View {
    let url: URL
    let browserModel: DirectoryBrowserModel
    
    var body: some View {
        HStack {
            Image(systemName: browserModel.isDirectory(url) ? "folder.fill" : "photo")
                .foregroundColor(browserModel.isDirectory(url) ? .blue : .orange)
                .frame(width: 16)
            
            Text(url.lastPathComponent)
                .lineLimit(1)
            
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
    }}

struct FileRowView_Previews: PreviewProvider {
    static var previews: some View {
        FileBrowserRowView(
            url: URL(string: "file:///Users/brentely/Documents/eosim_image.png")!,
            browserModel: DirectoryBrowserModel.forPreview()
        )
        .padding()
    }
}

#Preview("File Row") {
    FileBrowserRowView(
        url: URL(string: "file:///Users/brentely/Documents/eosim_image.png")!,
        browserModel: DirectoryBrowserModel.forPreview()
    )
}
