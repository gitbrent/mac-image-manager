//
//  BrowserModel+Preview.swift
//  MacImageManager
//
//  Created by Brent Ely on 9/23/25.
//

import Foundation

#if DEBUG
class PreviewBrowserModel: BrowserModel {
     var mockDirectories: Set<String> = []

    override func isDirectory(_ url: URL) -> Bool {
        //print("[DEBUG] isDirectory:", url)
        return mockDirectories.contains(url.lastPathComponent)
    }
}

extension BrowserModel {
    static var preview: BrowserModel {
        //let model = BrowserModel() // NOTE: Previews work (ContentView, PaneFileBrow)
        let model = PreviewBrowserModel()

        // Create URLs in the app's bundle that point to our preview assets
        if let bundleURL = Bundle.main.resourceURL {
            let previewURLs = [
                bundleURL.appendingPathComponent("preview1.png"),
                bundleURL.appendingPathComponent("preview2.png"),
                bundleURL.appendingPathComponent("PreviewFolder")
            ]
            model.items = previewURLs

            // Mark which items should be treated as directories
            model.mockDirectories = ["PreviewFolder"]
        }

        return model
    }
}
#endif
