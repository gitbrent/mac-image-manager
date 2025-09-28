//
//  BrowserModel+Preview.swift
//  MacImageManager
//
//  Created by Brent Ely on 9/23/25.
//

import Foundation
import UniformTypeIdentifiers

#if DEBUG
extension BrowserModel {
    static var preview: BrowserModel {
        let model = BrowserModel()
        let now = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: now)!
        let lastWeek = Calendar.current.date(byAdding: .day, value: -7, to: now)!

        model.items = [
            // Folders
            FileItem(url: URL(fileURLWithPath: "/tmp/Photos"), name: "Photos", iconName: "folder.fill", isDirectory: true, fileSize: 0, modificationDate: now, uti: .folder, isAnimatedGif: false, isVideo: false),
            FileItem(url: URL(fileURLWithPath: "/tmp/Archive"), name: "Archive", iconName: "folder.fill", isDirectory: true, fileSize: 0, modificationDate: lastWeek, uti: .folder, isAnimatedGif: false, isVideo: false),

            // Images with different formats
            FileItem(url: URL(fileURLWithPath: "/tmp/vacation.jpg"), name: "vacation.jpg", iconName: "photo", isDirectory: false, fileSize: 2_500_000, modificationDate: now, uti: .jpeg, isAnimatedGif: false, isVideo: false),
            FileItem(url: URL(fileURLWithPath: "/tmp/screenshot.png"), name: "screenshot.png", iconName: "photo", isDirectory: false, fileSize: 1_200_000, modificationDate: yesterday, uti: .png, isAnimatedGif: false, isVideo: false),
            FileItem(url: URL(fileURLWithPath: "/tmp/animation.gif"), name: "animation.gif", iconName: "photo", isDirectory: false, fileSize: 500_000, modificationDate: lastWeek, uti: .gif, isAnimatedGif: true, isVideo: false),
            FileItem(url: URL(fileURLWithPath: "/tmp/profile.heic"), name: "profile.heic", iconName: "photo", isDirectory: false, fileSize: 3_000_000, modificationDate: now, uti: .heic, isAnimatedGif: false, isVideo: false),
            FileItem(url: URL(fileURLWithPath: "/tmp/zipline.mp4"), name: "zipline.mp4", iconName: "film", isDirectory: false, fileSize: 55_100_000, modificationDate: now, uti: .mpeg4Movie, isAnimatedGif: false, isVideo: true),

            // Non-image files for testing filtering
            FileItem(url: URL(fileURLWithPath: "/tmp/document.pdf"), name: "document.pdf", iconName: "doc", isDirectory: false, fileSize: 150_000, modificationDate: yesterday, uti: .pdf, isAnimatedGif: false, isVideo: false),
            FileItem(url: URL(fileURLWithPath: "/tmp/notes.txt"), name: "notes.txt", iconName: "doc", isDirectory: false, fileSize: 1_024, modificationDate: now, uti: .text, isAnimatedGif: false, isVideo: false),
            FileItem(url: URL(fileURLWithPath: "/tmp/code.js"), name: "code.js", iconName: "doc", isDirectory: false, fileSize: 10_240, modificationDate: yesterday, uti: .javaScript, isAnimatedGif: false, isVideo: false),
        ]

        return model
    }
}
#endif
