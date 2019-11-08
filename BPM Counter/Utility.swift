//
//  Utility.swift
//  BPM Counter
//
//  Created by Benjamin Ludwig on 16.01.17.
//  Copyright © 2017 Benjamin Ludwig. All rights reserved.
//

import UIKit

class Utility {
    
    class func getDocumentsDirectoryURL() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }
    
    class func getDocumentsDirectoryPath() -> String {
        return NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
    }
    
    class func getCoverImagesDirectory() -> URL {
        
        let fm = FileManager.default
        let tempImagesURL = getDocumentsDirectoryURL().appendingPathComponent("coverimages", isDirectory: true)
        do {
            if !fm.fileExists(atPath: tempImagesURL.path) {
                try fm.createDirectory(at: tempImagesURL, withIntermediateDirectories: true, attributes: nil)
            }
        } catch {
            debugPrint("Error: \(error)")
        }
        
        return tempImagesURL
        
    }
    
    class func cleanCoverImagesDirectory() {
        
        let url = getCoverImagesDirectory()
        let fileManager = FileManager.default
        let enumerator = fileManager.enumerator(at: getCoverImagesDirectory(), includingPropertiesForKeys: nil)
        while let file = enumerator?.nextObject() as? String {
            do {
                try fileManager.removeItem(at: url.appendingPathComponent(file, isDirectory: false))
            } catch {
                debugPrint("Error: \(error)")
            }
        }
    }
    
}

