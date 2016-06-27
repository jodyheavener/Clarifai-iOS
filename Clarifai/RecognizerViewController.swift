//
//  RecognizerViewController.swift
//  Clarifai
//
//  Created by Jody Heavener on 2016-06-19.
//  Copyright © 2016 Jody Heavener. All rights reserved.
//

import UIKit

class RecognizerViewController: UIViewController {
    
    var selectedImage: UIImage?
    var inputURL: String?
    var clarifai: Clarifai!
    
    init(image: UIImage, clarifai client: Clarifai) {
        super.init(nibName: nil, bundle: nil)
        
        clarifai = client
        selectedImage = image
    }
    
    init(url: String, clarifai client: Clarifai) {
        super.init(nibName: nil, bundle: nil)
        
        clarifai = client
        inputURL = url
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.whiteColor()
        view.addSubview(imagePreviewView)
        view.addSubview(closeButton)
        view.addSubview(spacerView)
        view.addSubview(loadingLabel)
        view.addSubview(tagResultsList)
        
        view.setNeedsUpdateConstraints()
        
        if let image = selectedImage {
            imagePreviewView.image = image
            
            clarifai.tag(image, completion: { (results, error) in
                let tag = results?.tags![0]
                self.setupResultsView((tag?.labels)!)
            })
        }
        
        if let url = inputURL {
            let data = NSData(contentsOfURL: NSURL(string: url)!)
            if data != nil {
                imagePreviewView.image = UIImage(data:data!)
            }
            
            clarifai.tag(url, completion: { (results, error) in
                let tag = results?.tags![0]
                self.setupResultsView((tag?.labels)!)
            })
        }
    }
    
    lazy var imagePreviewView: UIImageView! = {
        let imageView = UIImageView()
        imageView.backgroundColor = UIColor.grayColor()
        imageView.frame = CGRectZero
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        return imageView
    }()
    
    lazy var closeButton: UIButton! = {
        let button = UIButton()
        button.frame = CGRectMake(0, 0, 40, 41)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(named: "Close Button"), forState: .Normal)
        button.addTarget(self, action: #selector(self.closeRecogizer), forControlEvents: .TouchUpInside)
        
        return button
    }()
    
    lazy var spacerView: UIView! = {
        let view = UIView(frame: CGRectZero)
        view.backgroundColor = UIColor.clearColor()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    lazy var loadingLabel: UILabel! = {
        let label = PaddedLabel(top: 15, left: 65, bottom: 15, right: 35)
        label.text = "Analyzing..."
        label.font = UIFont.systemFontOfSize(18, weight: UIFontWeightMedium)
        label.textColor = UIColor(red:0.46, green:0.46, blue:0.46, alpha:1.0)
        label.backgroundColor = UIColor(red:0.96, green:0.96, blue:0.96, alpha:1.0)
        label.layer.cornerRadius = 25
        label.clipsToBounds = true
        label.translatesAutoresizingMaskIntoConstraints = false
        label.sizeToFit()
        
        let spinner = UIImageView(frame: CGRectMake(32, 16, 20, 20))
        spinner.image = UIImage(named: "Load Spinner")
        label.addSubview(spinner)

        self.rotateLoadSpinner(spinner)
        
        return label
    }()
    
    lazy var tagResultsList: TagResultsList! = {
        let list = TagResultsList()
        list.translatesAutoresizingMaskIntoConstraints = false
        return list
    }()
    
    func setupResultsView(results: Array<String>) {
        tagResultsList.resultItems = results
        tagResultsList.reloadData()
        tagResultsList.hidden = false
        loadingLabel.hidden = true
    }
    
    func rotateLoadSpinner(spinner: UIImageView) {
        UIView.animateWithDuration(0.5, delay: 0, options: .CurveEaseInOut, animations: {() -> Void in
            spinner.transform = CGAffineTransformRotate(spinner.transform, CGFloat(M_PI_2))
        }, completion: {(finished: Bool) -> Void in
            self.rotateLoadSpinner(spinner)
        })
    }
    
    func closeRecogizer() {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    override func updateViewConstraints() {
        NSLayoutConstraint(item: imagePreviewView, attribute: .Top, relatedBy: .Equal, toItem: view, attribute: .Top, multiplier: 1, constant: 0).active = true
        NSLayoutConstraint(item: imagePreviewView, attribute: .Width, relatedBy: .Equal, toItem: view, attribute: .Width, multiplier: 1, constant: 0).active = true
        NSLayoutConstraint(item: imagePreviewView, attribute: .Height, relatedBy: .Equal, toItem: view, attribute: .Width, multiplier: 1, constant: 0).active = true
        
        NSLayoutConstraint(item: closeButton, attribute: .Top, relatedBy: .Equal, toItem: view, attribute: .Top, multiplier: 1, constant: 20).active = true
        NSLayoutConstraint(item: closeButton, attribute: .Left, relatedBy: .Equal, toItem: view, attribute: .Left, multiplier: 1, constant: 20).active = true
        
        NSLayoutConstraint(item: spacerView, attribute: .Top, relatedBy: .Equal, toItem: imagePreviewView, attribute: .Bottom, multiplier: 1, constant: 0).active = true
        NSLayoutConstraint(item: spacerView, attribute: .Bottom, relatedBy: .Equal, toItem: view, attribute: .Bottom, multiplier: 1, constant: 0).active = true
        NSLayoutConstraint(item: spacerView, attribute: .Width, relatedBy: .Equal, toItem: view, attribute: .Width, multiplier: 1, constant: 0).active = true
        
        NSLayoutConstraint(item: loadingLabel, attribute: .CenterY, relatedBy: .Equal, toItem: spacerView, attribute: .CenterY, multiplier: 1, constant: 0).active = true
        NSLayoutConstraint(item: loadingLabel, attribute: .CenterX, relatedBy: .Equal, toItem: view, attribute: .CenterX, multiplier: 1, constant: 0).active = true
        
        NSLayoutConstraint(item: tagResultsList, attribute: .Top, relatedBy: .Equal, toItem: imagePreviewView, attribute: .Bottom, multiplier: 1, constant: 0).active = true
        NSLayoutConstraint(item: tagResultsList, attribute: .Bottom, relatedBy: .Equal, toItem: view, attribute: .Bottom, multiplier: 1, constant: 0).active = true
        NSLayoutConstraint(item: tagResultsList, attribute: .Width, relatedBy: .Equal, toItem: view, attribute: .Width, multiplier: 1, constant: 0).active = true
        
        super.updateViewConstraints()
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
}

class PaddedLabel: UILabel {
    
    var topInset: CGFloat!
    var leftInset: CGFloat!
    var bottomInset: CGFloat!
    var rightInset: CGFloat!
    
    init(top: CGFloat, left: CGFloat, bottom: CGFloat, right: CGFloat) {
        super.init(frame: CGRectZero)
        
        topInset = top
        leftInset = left
        bottomInset = bottom
        rightInset = right
    }
    
    override func drawTextInRect(rect: CGRect) {
        let insets = UIEdgeInsets(top: topInset, left: leftInset, bottom: bottomInset, right: rightInset)
        super.drawTextInRect(UIEdgeInsetsInsetRect(rect, insets))
    }
    
    override func intrinsicContentSize() -> CGSize {
        var intrinsicSuperViewContentSize = super.intrinsicContentSize()
        intrinsicSuperViewContentSize.height += topInset + bottomInset
        intrinsicSuperViewContentSize.width += leftInset + rightInset
        return intrinsicSuperViewContentSize
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

class TagResultsList: UITableView, UITableViewDataSource, UITableViewDelegate {
    
    var resultItems: Array<String> = []
    
    init() {
        super.init(frame: CGRectZero, style: .Plain)
        
        hidden = true
        separatorInset = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        self.registerClass(UITableViewCell.self, forCellReuseIdentifier: "cell")
        
        delegate = self
        dataSource = self
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 50
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return resultItems.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = self.dequeueReusableCellWithIdentifier("cell")! as UITableViewCell
        cell.textLabel?.text = resultItems[indexPath.row]
        
        return cell
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}