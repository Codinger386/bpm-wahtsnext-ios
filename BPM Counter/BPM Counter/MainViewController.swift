//
//  ViewController.swift
//  BPM Counter
//
//  Created by Benjamin Ludwig on 14.01.17.
//  Copyright © 2017 Benjamin Ludwig. All rights reserved.
//

import UIKit
import QuartzCore

let AppDidDownloadCloudDataTheFirstTime = "app-did-download-cloud-data-the-first-time"

class MainViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, TouchViewDelegate {
    
    @IBOutlet weak var addTrack: UIBarButtonItem!
    @IBOutlet weak var tapView: TouchView!
    @IBOutlet weak var bottomContainer: UIView!
    @IBOutlet weak var bpmLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var explenationLayer: UIView!
    
    private var tabViewColor = #colorLiteral(red: 0.1480975116, green: 0.1506076389, blue: 0.1506076389, alpha: 1)
    private var tabViewHighlightColor = #colorLiteral(red: 0.1967678326, green: 0.2001028807, blue: 0.2001028807, alpha: 1)
    
    private var imageCache: [String:UIImage] = [:]
    
    private var lastTap: Double = 0
    private var taps: [Double] = []
    private var detectedBPM: Double = 0 {
        didSet {
            self.bpmLabel.text = String(format: "%.2f", detectedBPM)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        SSRateOnAppStorePopup.shared.present(fromViewController: self)
        
        self.title = "Tracks"
        
        self.tapView.backgroundColor = tabViewColor
        
        if UserDefaults.standard.bool(forKey: "explanationShown") == true {
            self.explenationLayer.isHidden = true
        } else {
            let tap = UITapGestureRecognizer(target: self, action: #selector(self.hideExplanation))
            self.explenationLayer.addGestureRecognizer(tap)
        }
        
        self.bpmLabel.text = "0.00"
        
        tapView.delegate = self
        tapView.layer.cornerRadius = 10
        
        let bgView = UIView(frame: CGRect(x: 0, y: 0, width: 1, height: 1))
        bgView.backgroundColor = UIColor.clear
        tableView.backgroundView = bgView
        tableView.backgroundColor = UIColor.clear
        
        let swipe = UISwipeGestureRecognizer(target: self, action: #selector(self.swipeLeft))
        swipe.direction = .left
        swipe.cancelsTouchesInView = false
        tapView.addGestureRecognizer(swipe)
        
//        let test = Track(artist: "Taktloss", title: "Penis", bpm: 90.354)
//        TrackDatabase.shared.add(track: test)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.dataBaseDidUpdate), name: .trackDatabaseDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.applicationDidBecomeActive), name: .UIApplicationDidBecomeActive, object: nil)
        
        self.tableView.reloadData()
        self.refreshData()
    }
    
    func hideExplanation(recognizer: UITapGestureRecognizer) {
        UIView.animate(withDuration: 0.4, animations: {
            self.explenationLayer.alpha = 0
        }) { finished in
            self.explenationLayer.isHidden = true
            self.view.sendSubview(toBack: self.explenationLayer)
            self.explenationLayer.removeGestureRecognizer(recognizer)
            UserDefaults.standard.set(true, forKey: "explanationShown")
            UserDefaults.standard.synchronize()
        }
    }
    
    func applicationDidBecomeActive(notification: Notification) {
        // Yeah doing the refresh
        self.refreshData()
    }
    
    func refreshData() {
        
        // Download only one time everything!
        if !UserDefaults.standard.bool(forKey: AppDidDownloadCloudDataTheFirstTime) {
            
            if !Reachability.isConnectedToNetwork() {
                let alert = UIAlertController(title: "Warning", message: "There is no internet connection. If you are running this app for the first time and you have already saved some tracks in the cloud, they won't be available until you have an internet connection.", preferredStyle: .alert)
                
                let okAction = UIAlertAction(title: "Got It!", style: .cancel, handler: { action in
                    
                })
                
                alert.addAction(okAction)
                self.present(alert, animated: true, completion: nil)
                
                return
            }
            
            TrackDatabase.shared.updateFromCloud(completion: { error in
                if error != nil {
                    debugPrint("Error: \(error)")
                    
                    if let code = error?.code {
                        debugPrint("code: \(code)")
                        if code == 9 {
                            
                            let alert = UIAlertController(title: "Warning", message: "iCloud seems to be disabled. That means that your tracks won't be saved in the cloud and previously saved tracks cannot be downloaded to your device. Please use the settings app to enable iCloud or continue without a cloud backup (if you delete the app, all your data will be gone!).", preferredStyle: .alert)
                            
                            let okAction = UIAlertAction(title: "Got It!", style: .cancel, handler: { action in
                                
                            })
                            
                            alert.addAction(okAction)
                            self.present(alert, animated: true, completion: nil)
                        }
                    }
                    
                } else {
                    UserDefaults.standard.set(true, forKey: AppDidDownloadCloudDataTheFirstTime)
                    UserDefaults.standard.synchronize()
                    self.tableView.reloadData()
                }
            })
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        tableView.reloadData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func adddTrack(_ sender: Any) {
        
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "CreateTrackViewController") as! CreateTrackViewController
        vc.detectedBPM = detectedBPM
        self.navigationController?.pushViewController(vc, animated: true)
        
    }
    
    internal func swipeLeft(tab: UISwipeGestureRecognizer) {
        debugPrint("swipe")
        
        detectedBPM = 0
        taps = []
        lastTap = 0
    }
    
    func dataBaseDidUpdate(notification: Notification) {
        self.tableView.reloadData()
    }
    
    func jumpToBPM() {
        
        let allTracks = TrackDatabase.shared.trackList
        
        var minimumDifference = Double.infinity
        
        for track in allTracks {
            let newDifference = abs(detectedBPM - track.bpm)
            debugPrint("minimumDifference \(minimumDifference) newDifference \(newDifference)")
            if newDifference > minimumDifference {
                if let index = allTracks.index(where: { theTrack -> Bool in
                    theTrack === track
                }) {
                    tableView.scrollToRow(at: IndexPath(row: index, section: 0), at: .middle, animated: true)
                }
                
                break
                
            } else {
                minimumDifference = newDifference
            }
            
            if allTracks.last === track {
                tableView.scrollToRow(at: IndexPath(row: allTracks.count - 1, section: 0), at: .middle, animated: true)
            }
        }
    }
    
    //MARK: - UITableViewDelegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let track = TrackDatabase.shared.trackList[indexPath.row]
        
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "CreateTrackViewController") as! CreateTrackViewController
        vc.track = track
        self.navigationController?.pushViewController(vc, animated: true)
        
    }
    
    
    //MARK: - UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return TrackDatabase.shared.trackList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "TrackCell") as! TrackCell
        
        let track = TrackDatabase.shared.trackList[indexPath.row]
        
        cell.titleLabel.text = track.title
        cell.artistLabel.text = track.artist
        cell.bpmLabel.text = String(format: "%.2f", track.bpm)
        cell.selectionStyle = .none
        
        //cell.coverImageView.layer.minificationFilter = kCAFilterTrilinear
        
        if let image = track.image {
            cell.coverImageView.image = image
            cell.coverImageView.layer.masksToBounds = true
            cell.coverImageView.layer.cornerRadius = 4.0
        } else {
            cell.coverImageView.image = UIImage(named: "default-image")
        }
        
        return cell
        
    }
    
    
    //MARK: - TouchViewDelegate
    
    func touchViewTouchBegan(touchView: TouchView) {
        
//        UIView.animate(withDuration: 0.1, animations: {
//            self.bpmLabel.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
//        }, completion: {
//            finished in
//            UIView.animate(withDuration: 0.1, animations: {
//                self.bpmLabel.transform = CGAffineTransform.identity
//            })
//        })
        
        touchView.backgroundColor = tabViewHighlightColor
        
        let currentTime = CACurrentMediaTime()
        
        debugPrint("tap, currentTime: \(currentTime)")
        
        if lastTap == 0 {
            lastTap = currentTime
            return
        }
        
        let difference = currentTime - lastTap
        lastTap = currentTime
        
        taps.append(difference)
        
        if taps.count > 2 {
            
            let sum = taps.reduce(0, +)
            let average = sum / Double(taps.count)
            detectedBPM = 60 / average
            
            jumpToBPM()
            
            debugPrint("sum: \(sum) average: \(average) detectedBPM: \(detectedBPM)")
        }
    }
    
    func touchViewTouchEnded(touchView: TouchView) {
        touchView.backgroundColor = tabViewColor
    }


}

