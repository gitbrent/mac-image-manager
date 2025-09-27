//
//  BrowserModel+Preview.swift
//  MacImageManager
//
//  Created by Brent Ely on 9/23/25.
//

import Foundation

#if DEBUG
extension BrowserModel {
    static var preview: BrowserModel {
        let model = BrowserModel()

        // Create a mix of different file types for testing
        let now = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: now)!
        let lastWeek = Calendar.current.date(byAdding: .day, value: -7, to: now)!

        model.items = [
            // Folders
            FileItem(url: URL(fileURLWithPath: "/tmp/Photos"), name: "Photos", iconName: "folder.fill", isDirectory: true, fileSize: 0, modificationDate: now),
            FileItem(url: URL(fileURLWithPath: "/tmp/Archive"), name: "Archive", iconName: "folder.fill", isDirectory: true, fileSize: 0, modificationDate: lastWeek),

            // Images with different formats
            FileItem(url: URL(fileURLWithPath: "/tmp/vacation.jpg"), name: "vacation.jpg", iconName: "photo", isDirectory: false, fileSize: 2_500_000, modificationDate: now),
            FileItem(url: URL(fileURLWithPath: "/tmp/screenshot.png"), name: "screenshot.png", iconName: "photo", isDirectory: false, fileSize: 1_200_000, modificationDate: yesterday),
            FileItem(url: URL(fileURLWithPath: "/tmp/animation.gif"), name: "animation.gif", iconName: "photo", isDirectory: false, fileSize: 500_000, modificationDate: lastWeek),
            FileItem(url: URL(fileURLWithPath: "/tmp/profile.heic"), name: "profile.heic", iconName: "photo", isDirectory: false, fileSize: 3_000_000, modificationDate: now),

            // Non-image files for testing filtering
            FileItem(url: URL(fileURLWithPath: "/tmp/document.pdf"), name: "document.pdf", iconName: "doc", isDirectory: false, fileSize: 150_000, modificationDate: yesterday),
            FileItem(url: URL(fileURLWithPath: "/tmp/notes.txt"), name: "notes.txt", iconName: "doc", isDirectory: false, fileSize: 1_024, modificationDate: now)
        ]

        return model
    }
}
#endif
