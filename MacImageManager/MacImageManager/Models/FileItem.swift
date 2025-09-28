//
//  FileItem.swift
//  MacImageManager
//
//  Created by Brent Ely on 9/27/25.
//

import Foundation
import UniformTypeIdentifiers

// TODO: add `fileType` (e.g., GIF, Image, Video)

struct FileItem: Identifiable, Hashable {
    let id = UUID()
    let url: URL
    let name: String
    let iconName: String
    let isDirectory: Bool
    let fileSize: Int
    let modificationDate: Date

    var formattedFileSize: String {
        if fileSize < 1024 {
            return "\(fileSize) B"
        }
        let kb = Double(fileSize) / 1024.0
        if kb < 1024 {
            return String(format: "%.1f KB", kb)
        }
        let mb = kb / 1024.0
        if mb < 1024 {
            return String(format: "%.1f MB", mb)
        }
        let gb = mb / 1024.0
        return String(format: "%.2f GB", gb)
    }
}
