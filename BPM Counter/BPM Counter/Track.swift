//
//  Track.swift
//  BPM Counter
//
//  Created by Benjamin Ludwig on 15.01.17.
//  Copyright © 2017 Benjamin Ludwig. All rights reserved.
//

import UIKit
import CloudKit

class Track {
    
    // Set if already in cloud
    var record: CKRecord?
    weak var database: CKDatabase?
    
    var artist: String
    var title: String
    var bpm: Double
    var image: UIImage?
    var cloudID: String?
    var imageName: String?
    
    var deleted: Bool = false
    var updated: Bool = false
    
    init(artist: String, title: String, bpm: Double, image: UIImage?) {
        
        self.artist = artist
        self.title = title
        self.bpm = bpm
        self.image = image
        
    }
    
    init(record: CKRecord, database: CKDatabase) {
        
        self.record = record
        self.database = database
        
        self.cloudID = record.recordID.recordName
        
        self.artist = record["artist"] as! String
        self.title = record["title"] as! String
        self.bpm = record["bpm"] as! Double
        
        if let asset = self.record?["image"] as? CKAsset {
            let imageData: Data
            do {
                imageData = try Data(contentsOf: asset.fileURL!)
            } catch {
                debugPrint("Error: \(error)")
                return
            }
            
            // Copy image data to local dir
            let fm = FileManager.default
            let fileName = asset.fileURL!.lastPathComponent
            let localURL = Utility.getCoverImagesDirectory().appendingPathComponent(fileName, isDirectory: false)
            do {
                try fm.copyItem(at: asset.fileURL!, to: localURL)
            } catch {
                debugPrint("Error: \(error)")
                return
            }
            
            self.imageName = localURL.lastPathComponent
            debugPrint("localURL: \(asset.fileURL!)")
            self.image = UIImage(data: imageData)
        }
    }
    
    init?(dictionary: [String: Any]) {
        
        if let artist = dictionary["artist"] as? String {
            self.artist = artist
        } else {
            return nil
        }
        
        if let title = dictionary["title"] as? String {
            self.title = title
        } else {
            return nil
        }
        
        if let bpm = dictionary["bpm"] as? Double {
            self.bpm = bpm
        } else {
            return nil
        }
        
        if let imageName = dictionary["imageName"] as? String {
            
            self.imageName = imageName
            
            let imageData: Data
            do {
                imageData = try Data(contentsOf: Utility.getCoverImagesDirectory().appendingPathComponent(imageName, isDirectory: false))
                self.image = UIImage(data: imageData)
            } catch {
                debugPrint("Error: \(error)")
            }
        }
        
        if let cloudID = dictionary["cloudID"] as? String {
            self.cloudID = cloudID
        }
        
        if let deleted = dictionary["deleted"] as? Bool {
            self.deleted = deleted
        }
        
        if let updated = dictionary["updated"] as? Bool {
            self.updated = updated
        }
    }
    
    func dictionary() -> [String: Any] {
        
        var dict: [String: Any] = [:]
        
        dict["artist"] = artist
        dict["title"] = title
        dict["bpm"] = bpm
        
        if let imageName = self.imageName {
            dict["imageName"] = imageName
        }
        
        if let cloudID = self.cloudID {
            dict["cloudID"] = cloudID
        }
        
        dict["deleted"] = deleted
        dict["updated"] = updated
        
        return dict
        
    }
    
    func update(withRecord record: CKRecord, database: CKDatabase) {
        
        self.record = record
        self.database = database
        
        self.cloudID = record.recordID.recordName
        
        self.artist = record["artist"] as! String
        self.title = record["title"] as! String
        self.bpm = record["bpm"] as! Double
        
        if let asset = self.record?["image"] as? CKAsset {
            let imageData: Data
            do {
                imageData = try Data(contentsOf: asset.fileURL!)
            } catch {
                debugPrint("Error: \(error)")
                return
            }
            
            // Copy image data to local dir
            let fm = FileManager.default
            let fileName = asset.fileURL!.lastPathComponent
            let localURL = Utility.getCoverImagesDirectory().appendingPathComponent(fileName, isDirectory: false)
            do {
                try fm.copyItem(at: asset.fileURL!, to: localURL)
            } catch {
                debugPrint("Error: \(error)")
                return
            }
            
            self.imageName = localURL.lastPathComponent
            debugPrint("localURL: \(asset.fileURL!)")
            self.image = UIImage(data: imageData)
        }
    }
}
