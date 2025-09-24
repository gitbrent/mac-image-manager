//
//  DirectoryBrowserModel+Preview.swift
//  MacImageManager
//
//  Created by Brent Ely on 9/23/25.
//

import Foundation

#if DEBUG
extension BrowserModel {
    static var preview: BrowserModel {
        let model = BrowserModel()

        // Create URLs in the app's bundle that point to our preview assets
        if let bundleURL = Bundle.main.resourceURL {
            let previewURLs = [
                bundleURL.appendingPathComponent("preview1.png"),
                bundleURL.appendingPathComponent("preview2.png")
            ]
            model.items = previewURLs
        }

        return model
    }
}
#endif
