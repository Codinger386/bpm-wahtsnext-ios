//
//  Database.swift
//  BPM Counter
//
//  Created by Benjamin Ludwig on 15.01.17.
//  Copyright © 2017 Benjamin Ludwig. All rights reserved.
//

import UIKit
import CloudKit

extension Notification.Name {
    
    static let trackDatabaseDidChange = Notification.Name("track-database-did-change")
}

public class TrackDatabase {
    
    static let identifier = "TrackDatabase"
    
    let container: CKContainer
    let privateDB: CKDatabase
    var sharedDBChangeToken: CKServerChangeToken?
    
    
    internal private(set) var tracks: [Track] = []
    internal private(set) var trackList: [Track] = []
    
    internal private(set) var downloadedTracks: [Track] = []
    
    public class var shared: TrackDatabase {
        struct Singleton {
            static let instance = TrackDatabase()
        }
        return Singleton.instance
    }
    
    init() {
        
        container = CKContainer.default()
        privateDB = container.privateCloudDatabase
        
        // Take tracks from local store
        self.tracks = loadLocalData()
        self.updateTrackList()
        
    }
    
    private func updateTrackList() {
        let undeletedTracks = tracks.filter({ track -> Bool in
            return !track.deleted
        })
        trackList =  undeletedTracks.sorted(by: { track1, track2 -> Bool in
            return track1.bpm < track2.bpm
        })
    }
    
    
    //MARK: - Handle local data
    
    func loadLocalData() -> [Track] {
        
        var loadedTracks: [Track] = []
        
        if let tracksFromDefaults = UserDefaults.standard.value(forKey: TrackDatabase.identifier) as? [[String: Any]] {
            for entry in tracksFromDefaults {
                if let loadedTrack = Track(dictionary: entry) {
                    loadedTracks.append(loadedTrack)
                }
            }
        }
        
        return loadedTracks
        
    }
    
    func saveLocalData() {
        
        DispatchQueue.global().async {
            var tracksToUD = [[String: Any]]()
            
            for track in self.tracks {
                tracksToUD.append(track.dictionary())
            }
            
            UserDefaults.standard.set(tracksToUD, forKey: TrackDatabase.identifier)
            UserDefaults.standard.synchronize()
        }
    }
    
    func addTrack(track: Track) {
        
        // 1. Add track to local list
        self.tracks.append(track)
        
        // 2. Save image to disk if set Image
        if let image = track.image {
            let timeStamp = NSDate.timeIntervalSinceReferenceDate
            let newImageName = "\(timeStamp).jpg"
            
            if let data = UIImageJPEGRepresentation(image, 1.0) {
                let fileURL = Utility.getCoverImagesDirectory().appendingPathComponent("\(newImageName)")
                do {
                    try data.write(to: fileURL)
                    track.imageName = newImageName
                } catch {
                    debugPrint("Error: \(error)")
                }
            }
        }
        
        updateTrackList()
        self.saveLocalData()
        
        // 3. Synchronize with cloud
        self.uploadToCloud()
    }
    
    func updateTrack(track: Track) {
        
        // Delete old image
        if let imageName = track.imageName {
            let fm = FileManager.default
            do {
                try fm.removeItem(at: Utility.getCoverImagesDirectory().appendingPathComponent(imageName, isDirectory: false))
            } catch {
                debugPrint("Error: \(error)")
            }
        }
        
        // Save image
        if let image = track.image {
            let timeStamp = NSDate.timeIntervalSinceReferenceDate
            let newImageName = "\(timeStamp).jpg"
            
            if let data = UIImageJPEGRepresentation(image, 1.0) {
                let fileURL = Utility.getCoverImagesDirectory().appendingPathComponent("\(newImageName)")
                do {
                    try data.write(to: fileURL)
                    track.imageName = newImageName
                } catch {
                    debugPrint("Error: \(error)")
                }
            }
        }
        
        if track.cloudID != nil {
            track.updated = true
        }
        
        saveLocalData()
        updateTrackList()
        
        // 3. Synchronize with cloud
        self.uploadToCloud()
        
    }
    
    func deleteTrack(track: Track) {
        
        // 1. Remove from local store and delete image if no cloud entry available
        if track.cloudID == nil {
            if let index = tracks.index(where: { theTrack -> Bool in
                theTrack === track
            }) {
                
                if let imageName = track.imageName {
                    let fm = FileManager.default
                    do {
                        try fm.removeItem(at: URL(fileURLWithPath: imageName))
                    } catch {
                        debugPrint("Error: \(error)")
                    }
                }
                
                tracks.remove(at: index)
                self.updateTrackList()
                self.saveLocalData()
            }
        } else {
            
            track.deleted = true
            self.updateTrackList()
            self.saveLocalData()
            
            // Synchronize with cloud
            self.uploadToCloud()
        }
    }
    
    
    //MARK: - Handle Cloud Data
    
    func uploadToCloud() {
        
        for track in tracks {
            
            // Track exists in cloud
            if track.cloudID != nil {
                
                if track.deleted {
                    let operation = CKModifyRecordsOperation(recordsToSave: nil, recordIDsToDelete: [CKRecordID(recordName: track.cloudID!)])
                    operation.modifyRecordsCompletionBlock = { records, recordIDs, error in
                        if error != nil {
                            debugPrint("Error: \(error)")
                        } else {
                            if let index = self.tracks.index(where: { theTrack -> Bool in
                                theTrack === track
                            }) {
                                self.tracks.remove(at: index)
                                self.saveLocalData()
                            }
                        }
                    }
                    
                    operation.qualityOfService = .utility
                    privateDB.add(operation)
                }
                
                if track.updated {
                    
                    guard let trackRecord = track.record else { return }
                    
                    trackRecord["artist"] = track.artist as NSString
                    trackRecord["title"] = track.title as NSString
                    trackRecord["bpm"] = NSNumber(floatLiteral: track.bpm)
                    
                    if let imageName = track.imageName {
                        let fileURL = Utility.getCoverImagesDirectory().appendingPathComponent(imageName, isDirectory: false)
                        let asset = CKAsset(fileURL: fileURL)
                        trackRecord["image"] = asset
                    }
                    
                    let operation = CKModifyRecordsOperation(recordsToSave: [trackRecord], recordIDsToDelete: nil)
                    operation.modifyRecordsCompletionBlock = { records, recordIDs, error in
                        if error != nil {
                            debugPrint("Error: \(error)")
                        } else {
                            track.updated = false
                            self.saveLocalData()
                        }
                    }
                    
                    operation.qualityOfService = .utility
                    privateDB.add(operation)
                    
                }
                
            } else { // Track doesn't exist in cloud
                
                let cloudID = "\(Date.timeIntervalSinceReferenceDate)"
                let trackID = CKRecordID(recordName: cloudID)
                let trackRecord = CKRecord(recordType: "Track", recordID: trackID)
                trackRecord["artist"] = track.artist as NSString
                trackRecord["title"] = track.title as NSString
                trackRecord["bpm"] = NSNumber(floatLiteral: track.bpm)
                
                if let imageName = track.imageName {
                    let fileURL = Utility.getCoverImagesDirectory().appendingPathComponent(imageName, isDirectory: false)
                    let asset = CKAsset(fileURL: fileURL)
                    trackRecord["image"] = asset
                }
                
                // Check later if the track was saved!
                track.cloudID = cloudID
                
                let operation = CKModifyRecordsOperation(recordsToSave: [trackRecord], recordIDsToDelete: nil)
                operation.modifyRecordsCompletionBlock = { records, recordIDs, error in
                    if error != nil {
                        debugPrint("Error: \(error)")
                        track.cloudID = nil
                    }
                    self.saveLocalData()
                }
                
                operation.qualityOfService = .utility
                privateDB.add(operation)
            }
        }
    }
    
    func updateFromCloud(completion: @escaping (_ error: NSError?) -> ()) {
        
        self.uploadToCloud()
        
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: "Track", predicate: predicate)
        
        let operation = CKQueryOperation(query: query)
        
        self.downloadedTracks = []
        
        Utility.cleanCoverImagesDirectory()
        
        operation.recordFetchedBlock = { (record : CKRecord) -> Void in
            
            debugPrint("recordFetchedBlock")
            // Check if the record already exists locally:
            
            self.downloadedTracks.append(Track(record: record, database: self.privateDB))
            
//            for track in self.tracks {
//                if let cloudId = track.cloudID {
//                    if record.recordID.recordName == cloudId {
//                        
//                        // Update with cloud data
//                        track.update(withRecord: record, database: self.privateDB)
//                        return // stop here
//                    }
//                }
//            }
//            
//            self.tracks.append(Track(record: record, database: self.privateDB))
        }
        
        operation.queryCompletionBlock = {cursor, error in
            
            debugPrint("queryCompletionBlock")
            
            guard error == nil else {
                
                DispatchQueue.main.async {
                    completion(error as NSError?)
                }
                return
            }
            
            self.tracks = self.downloadedTracks
            self.downloadedTracks = []
            self.saveLocalData()
            self.updateTrackList()
            
            DispatchQueue.main.async {
                completion(nil)
            }
        }
        
        operation.qualityOfService = .utility
        privateDB.add(operation)
        
        // Fetch all and sync with local data
        
        // TODO: Check if everything worked and mark tracks
        // -> deleted: remove locally including image
        // -> updated: remove flag
        // -> added: add cloudID
        
        
        //            if error != nil {
        //                debugPrint("Error: \(error)")
        //
        //                //TODO: Need to check all the data :(
        //
        //                self.tracks = self.loadLocalData()
        //                self.updateTrackList()
        //                completion(nil)
        //
        //            } else {
        //
        //                let predicate = NSPredicate(value: true)
        //                let query = CKQuery(recordType: "Track", predicate: predicate)
        //
        //                self.privateDB.perform(query, inZoneWith: nil) { [unowned self] results, error in
        //
        //                    guard error == nil else {
        //                        DispatchQueue.main.async {
        //                            completion(error as NSError?)
        //                        }
        //                        return
        //                    }
        //
        //                    var iCloudTracks: [Track] = []
        //
        //                    for record in results! {
        //                        let track = Track(record: record, database: self.privateDB)
        //                        iCloudTracks.append(track)
        //                    }
        //
        //                    DispatchQueue.main.async {
        //                        //Utility.cleanTempImagesDirectory()        don't do this, keep local images
        //                        self.tracks = iCloudTracks
        //                        self.updateTrackList()
        //                        self.saveLocalData()
        //                        completion(nil)
        //                    }
        //                }
        //            }
    }
    
    
    //MARK: - Change Subscription
    
    func subscribeToChanges() {
        
        let subscription = CKDatabaseSubscription(subscriptionID: "track-changes")
        
        let notificationInfo = CKNotificationInfo()
        notificationInfo.shouldSendContentAvailable = true
        subscription.notificationInfo = notificationInfo
        
        privateDB.save(subscription) { subscription, error in
            guard error == nil else {
                debugPrint("Error: \(error)")
                return
            }
            debugPrint("Subscribed to changes")
            
            UserDefaults.standard.set(true, forKey: "subscribedToChanges")
            UserDefaults.standard.synchronize()
        }
        
        
//        let operation = CKModifySubscriptionsOperation(subscriptionsToSave: [subscription],
//                                                       subscriptionIDsToDelete: [])
//        
//        operation.modifySubscriptionsCompletionBlock = { subscriptions, messages, error in
//            guard error == nil else {
//                debugPrint("Error: \(error)")
//                return
//            }
//            debugPrint("Subscribed to changes")
//            
//            UIApplication.shared.registerForRemoteNotifications()
//            
//            UserDefaults.standard.set(true, forKey: "subscribedToChanges")
//            UserDefaults.standard.synchronize()
//        }
//        
//        operation.qualityOfService = .utility
//        self.privateDB.add(operation)
        
    }
    
    func fetchSharedChanges(_ callback: @escaping () -> Void) {
        
        debugPrint("fetchSharedChanges")
        
        self.updateFromCloud { error in
            
            if error != nil {
                debugPrint("Error: \(error)")
            } else {
                self.updateTrackList()
                NotificationCenter.default.post(name: .trackDatabaseDidChange, object: nil)
            }
            
            callback()
        }
        //
        //        let changesOperation = CKFetchDatabaseChangesOperation(
        //            previousServerChangeToken: sharedDBChangeToken) // previously cached
        //
        //        changesOperation.fetchAllChanges = true
        //
        //        changesOperation.recordZoneWithIDChangedBlock = { zoneID in
        //        } // collect zone IDs
        //
        //        changesOperation.recordZoneWithIDWasDeletedBlock = { zoneID in
        //        } // delete local cache
        //
        //        changesOperation.changeTokenUpdatedBlock = { serverChangeToken in
        //        } // cache new token
        //
        //        changesOperation.fetchDatabaseChangesCompletionBlock = {
        //            newToken, more, error in
        //            // error handling here
        //            self.sharedDBChangeToken = newToken // cache new token
        //            self.fetchZoneChanges(callback) // using CKFetchRecordZoneChangesOperation
        //        }
        //        
        //        self.privateDB.add(changesOperation)
    }
    
    func fetchZoneChanges(_ callback: @escaping () -> Void) {
        
    }

}
