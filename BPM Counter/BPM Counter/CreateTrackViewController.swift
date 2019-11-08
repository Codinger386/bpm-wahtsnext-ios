//
//  CreateTrackViewController.swift
//  BPM Counter
//
//  Created by Benjamin Ludwig on 15.01.17.
//  Copyright © 2017 Benjamin Ludwig. All rights reserved.
//

import UIKit

class CreateTrackViewController: UIViewController, UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    var track: Track?
    var detectedBPM: Double?
    
    internal var selectedImage: UIImage?
    
    @IBOutlet weak var artistTextField: UITextField!
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var bpmTextField: UITextField!
    @IBOutlet weak var imageButton: UIButton!
    @IBOutlet weak var imageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imageView.layer.cornerRadius = 8.0
        imageView.layer.masksToBounds = true
        
        if let track = self.track {
            
            self.title = "Edit Track"
            
            self.artistTextField.text = track.artist
            self.titleTextField.text = track.title
            self.bpmTextField.text = String(format: "%.2f", track.bpm)
            
            if let image = track.image {
                imageView.image = image
            } else {
                imageView.image = UIImage(named: "no-cover")
                imageView.layer.borderColor = UIColor.white.cgColor
                imageView.layer.borderWidth = 1
            }
            
        } else {
            
            self.title = "Add Track"
            
            self.navigationItem.rightBarButtonItem = nil
            
            imageView.image = UIImage(named: "no-cover")
            imageView.layer.borderColor = UIColor.white.cgColor
            imageView.layer.borderWidth = 1
            
            self.artistTextField.attributedPlaceholder = NSAttributedString(string: "Artist",
                                                                            attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): #colorLiteral(red: 0.5902686686, green: 0.5952289095, blue: 0.5952289095, alpha: 1) ]))
            self.titleTextField.attributedPlaceholder = NSAttributedString(string: "Title",
                                                                           attributes: convertToOptionalNSAttributedStringKeyDictionary([convertFromNSAttributedStringKey(NSAttributedString.Key.foregroundColor): #colorLiteral(red: 0.5902686686, green: 0.5952289095, blue: 0.5952289095, alpha: 1) ]))
            if let bpm = detectedBPM {
                self.bpmTextField.text = String(format: "%.2f", bpm)
            } else {
                self.bpmTextField.text = "0.00"
            }
        }
    }
    
    @IBAction func imageButton(_ sender: Any) {
        
        let alert = UIAlertController(title: "Set Cover", message: "", preferredStyle: .actionSheet)
        
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            let selectPhotoAction = UIAlertAction(title: "Take Pic", style: .default) { action in
                let picker = UIImagePickerController()
                picker.sourceType = .camera
                picker.cameraCaptureMode = .photo
                picker.cameraFlashMode = .off
                picker.allowsEditing = false
                picker.delegate = self
                self.present(picker, animated: true, completion: nil)
            }
            alert.addAction(selectPhotoAction)
        }
        
        
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            let selectPhotoAction = UIAlertAction(title: "Select Pic", style: .default) { action in
                let picker = UIImagePickerController()
                picker.sourceType = .photoLibrary
                picker.allowsEditing = false
                picker.delegate = self
                self.present(picker, animated: true, completion: nil)
            }
            alert.addAction(selectPhotoAction)
        }
        
        
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { action in
            
        }
        alert.addAction(cancelAction)
        
        self.present(alert, animated: true, completion: nil)
        
    }
    
    func showFailAlert() {
        
        let alert = UIAlertController(title: "Fail", message: "Artist and title can't be empty and BPM needs to be above zero.", preferredStyle: .alert)
        
        let okButton = UIAlertAction(title: "Got It!", style: .default) { action in
            
        }
        alert.addAction(okButton)
        
        self.present(alert, animated: true, completion: nil)
        
    }
    
    @IBAction func save(_ sender: Any) {
        
        var bpmText = self.bpmTextField.text == nil ? "0" : self.bpmTextField.text!
        bpmText = bpmText.replacingOccurrences(of: ",", with: ".")
        
        if let bpm = Double(bpmText),
            bpm > 0 {
        } else {
            showFailAlert()
            return
        }
        
        if self.artistTextField.text == nil || self.artistTextField.text == "" {
            showFailAlert()
            return
        }
        
        if self.titleTextField.text == nil || self.titleTextField.text == "" {
            showFailAlert()
            return
        }
        
        if let track = track {
            
            track.artist = self.artistTextField.text!
            track.title = self.titleTextField.text!
            track.bpm = Double(self.bpmTextField.text!)!
            
            if let image = selectedImage {
                track.image = image
            }
            
            TrackDatabase.shared.updateTrack(track: track)
            
            _ = self.navigationController?.popViewController(animated: true)
            
        } else {
            
            let track = Track(artist: self.artistTextField.text!, title: self.titleTextField.text!, bpm: Double(bpmText)!, image: selectedImage)
            
            TrackDatabase.shared.addTrack(track: track)
            
            _ = self.navigationController?.popViewController(animated: true)
        }
    }
    
    @IBAction func deleteTrack(_ sender: Any) {
        
        let alert = UIAlertController(title: "What?", message: "Do ya really want to delete this track?", preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: "Yo", style: .destructive) { action in
            
            TrackDatabase.shared.deleteTrack(track: self.track!)
            
            _ = self.navigationController?.popViewController(animated: true)
        }
        
        alert.addAction(okAction)
        
        let cancelAction = UIAlertAction(title: "Nope", style: .cancel) { action in
            
        }
        
        alert.addAction(cancelAction)
        
        self.present(alert, animated: true, completion: nil)
    }
    
    
    //MARK: - UITextFieldDelegate
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    
    //MARK: - UIImagePickerControllerDelegate
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
// Local variable inserted by Swift 4.2 migrator.
let info = convertFromUIImagePickerControllerInfoKeyDictionary(info)

        
        if let pickedImage = info[convertFromUIImagePickerControllerInfoKey(UIImagePickerController.InfoKey.originalImage)] as? UIImage {
            
            // crop and resize
            let resizedImage = pickedImage.resizedImage(minEdgeLength: 200)
            
            // set as iamge
            selectedImage = resizedImage
            imageView.image = resizedImage
            
            imageView.layer.borderColor = UIColor.clear.cgColor
            imageView.layer.borderWidth = 0
        }
        
        picker.dismiss(animated: true, completion: nil)
    }
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIImagePickerControllerInfoKeyDictionary(_ input: [UIImagePickerController.InfoKey: Any]) -> [String: Any] {
	return Dictionary(uniqueKeysWithValues: input.map {key, value in (key.rawValue, value)})
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToOptionalNSAttributedStringKeyDictionary(_ input: [String: Any]?) -> [NSAttributedString.Key: Any]? {
	guard let input = input else { return nil }
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (NSAttributedString.Key(rawValue: key), value)})
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromNSAttributedStringKey(_ input: NSAttributedString.Key) -> String {
	return input.rawValue
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromUIImagePickerControllerInfoKey(_ input: UIImagePickerController.InfoKey) -> String {
	return input.rawValue
}
