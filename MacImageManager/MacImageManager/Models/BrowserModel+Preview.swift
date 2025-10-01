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

        // Run async initialization in a synchronous context for previews
        Task { @MainActor in
            let now = Date()
            let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: now)!
            let lastWeek = Calendar.current.date(byAdding: .day, value: -7, to: now)!

            // Create items asynchronously
            async let archiveItem = FileItem(
                url: URL(fileURLWithPath: "/tmp/Archive"),
                name: "Archive",
                isDirectory: true,
                fileSize: 0,
                modificationDate: lastWeek,
                uti: .folder
            )
            async let photosItem = FileItem(
                url: URL(fileURLWithPath: "/tmp/Photos"),
                name: "Photos",
                isDirectory: true,
                fileSize: 0,
                modificationDate: now,
                uti: .folder
            )

            // Images with different formats
            async let animationItem = FileItem(
                url: URL(fileURLWithPath: "/tmp/animation.gif"),
                name: "animation.gif",
                isDirectory: false,
                fileSize: 500_000,
                modificationDate: lastWeek,
                uti: UTType.gif
            )

            async let vacationItem = FileItem(
                url: URL(fileURLWithPath: "/tmp/vacation.jpg"),
                name: "vacation.jpg",
                isDirectory: false,
                fileSize: 2_500_000,
                modificationDate: now,
                uti: .jpeg
             )

            async let lockItem = FileItem(
                url: URL(fileURLWithPath: "/tmp/lock.svg"),
                name: "lock.svg",
                isDirectory: false,
                fileSize: 200_000,
                modificationDate: yesterday,
                uti: .svg)

            async let screenshotItem = FileItem(
                url: URL(fileURLWithPath: "/tmp/screenshot.png"),
                name: "screenshot.png",
                isDirectory: false,
                fileSize: 1_200_000,
                modificationDate: yesterday,
                uti: .png)

            async let profileItem = FileItem(
                url: URL(fileURLWithPath: "/tmp/profile.heic"),
                name: "profile.heic",
                isDirectory: false,
                fileSize: 3_000_000,
                modificationDate: now,
                uti: .heic)

            async let ziplineItem = FileItem(
                url: URL(fileURLWithPath: "/tmp/zipline.mp4"),
                name: "zipline.mp4",
                isDirectory: false,
                fileSize: 55_100_000,
                modificationDate: now,
                uti: .mpeg4Movie)

            // Wait for all items to be created and add them to the model
            model.items = await [
                archiveItem,
                photosItem,
                animationItem,
                vacationItem,
                lockItem,
                screenshotItem,
                profileItem,
                ziplineItem
            ]
        }

        return model
    }
}
#endif
