//
//  MainViewController.swift
//  Clarifai
//
//  Created by Jody Heavener on 2016-06-18.
//  Copyright © 2016 Jody Heavener. All rights reserved.
//

import UIKit

// Fill these in with your own API credentials
let clarifaiID = ""
let clarifaiSecret = ""

var clarifai: Clarifai?

class MainViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        clarifai = Clarifai(clientID: clarifaiID, clientSecret: clarifaiSecret)
        
        view.backgroundColor = UIColor.whiteColor()
        view.addSubview(logoImage)
        view.addSubview(cameraButton)
        view.addSubview(linkButton)
        
        view.setNeedsUpdateConstraints()
    }
    
    lazy var logoImage: UIImageView! = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "Logo")
        imageView.frame = CGRectMake(0, 0, 240, 104)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        return imageView
    }()
    
    lazy var cameraButton: UIButton! = {
        let button = UIButton()
        button.frame = CGRectMake(0, 0, 152, 152)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(named: "Camera Button"), forState: .Normal)
        button.addTarget(self, action: #selector(self.launchPickerActionSheet), forControlEvents: .TouchUpInside)
        
        return button
    }()
    
    lazy var linkButton: UIButton! = {
        let button = UIButton()
        button.frame = CGRectMake(0, 0, 152, 152)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(named: "Link Button"), forState: .Normal)
        button.addTarget(self, action: #selector(self.launchLinkInput), forControlEvents: .TouchUpInside)
        
        return button
    }()
    
    func launchPickerActionSheet() {
        let actionSheetController = UIAlertController(title: "Select Photo", message: nil, preferredStyle: .ActionSheet)
        
        let dismissActionSheet = UIAlertAction(title: "Cancel", style: .Cancel) { (action) in
            actionSheetController.dismissViewControllerAnimated(true, completion: nil)
        }
        
        let launchCameraPicker = UIAlertAction(title: "Take Photo", style: .Default) { (action) in
            let pickerController = UIImagePickerController()
            pickerController.delegate = self
            pickerController.sourceType = .Camera
            self.presentViewController(pickerController, animated: true, completion: nil)
        }
        
        let launchPhotoLibraryPicker = UIAlertAction(title: "Choose from Library", style: .Default) { (action) in
            let pickerController = UIImagePickerController()
            pickerController.delegate = self
            pickerController.sourceType = .PhotoLibrary
            self.presentViewController(pickerController, animated: true, completion: nil)
        }
        
        actionSheetController.addAction(dismissActionSheet)
        actionSheetController.addAction(launchCameraPicker)
        actionSheetController.addAction(launchPhotoLibraryPicker)
        
        presentViewController(actionSheetController, animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        picker.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingImage image: UIImage, editingInfo: [String : AnyObject]?) {
        picker.dismissViewControllerAnimated(true, completion: nil)
        
        let recognizerViewController = RecognizerViewController(image: image, clarifai: clarifai!)
        presentViewController(recognizerViewController, animated: true, completion: nil)
    }
    
    func launchLinkInput() {
        let alert = UIAlertController(title: "Recognize from URL", message: "Enter a valid image URL", preferredStyle: .Alert)
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: { (action) in
            alert.dismissViewControllerAnimated(true, completion: nil)
        }))
            
        alert.addAction(UIAlertAction(title: "Submit", style: .Default) { (action) in
            let textField = alert.textFields![0]
            let recognizerViewController = RecognizerViewController(url: textField.text!, clarifai: clarifai!)
            self.presentViewController(recognizerViewController, animated: true, completion: nil)
        })
        
        alert.addTextFieldWithConfigurationHandler { (textField) in
            textField.placeholder = "Image URL"
        }
        
        presentViewController(alert, animated: true, completion: nil)
    }
    
    override func updateViewConstraints() {
        NSLayoutConstraint(item: logoImage, attribute: .CenterX, relatedBy: .Equal, toItem: view, attribute: .CenterX, multiplier: 1, constant: 0).active = true
        NSLayoutConstraint(item: logoImage, attribute: .Top, relatedBy: .Equal, toItem: view, attribute: .Top, multiplier: 1, constant: 80).active = true
        
        NSLayoutConstraint(item: linkButton, attribute: .CenterX, relatedBy: .Equal, toItem: view, attribute: .CenterX, multiplier: 1, constant: 0).active = true
        NSLayoutConstraint(item: linkButton, attribute: .Bottom, relatedBy: .Equal, toItem: view, attribute: .Bottom, multiplier: 1, constant: -80).active = true
        
        NSLayoutConstraint(item: cameraButton, attribute: .CenterX, relatedBy: .Equal, toItem: view, attribute: .CenterX, multiplier: 1, constant: 0).active = true
        NSLayoutConstraint(item: cameraButton, attribute: .Bottom, relatedBy: .Equal, toItem: linkButton, attribute: .Top, multiplier: 1, constant: -30).active = true
        
        super.updateViewConstraints()
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

