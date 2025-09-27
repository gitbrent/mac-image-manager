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
}
