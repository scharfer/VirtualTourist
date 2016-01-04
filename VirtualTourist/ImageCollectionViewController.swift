//
//  ImageCollectionViewController.swift
//  VirtualTourist
//
//  Created by Evan Scharfer on 12/17/15.
//  Copyright © 2015 Evan Scharfer. All rights reserved.
//

import UIKit
import CoreData

private let reuseIdentifier = "FlickrImage"

class ImageCollectionViewController: UICollectionViewController {
    
    let wsClient = FlickrWSClient.sharedInstance
    var selectedPin : Pin!
    var imageCount : Int = 0

    let fileManager = NSFileManager.defaultManager()
    
    @IBOutlet var viewFlow: UICollectionViewFlowLayout!
    
    
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated);
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let space : CGFloat = 3
        let diminision = (view.frame.size.width - (2 * space)) / 3.0
        
        // set the spacing
        viewFlow.minimumInteritemSpacing = space
        viewFlow.minimumLineSpacing = space
        viewFlow.itemSize = CGSizeMake(diminision,diminision)
        
        collectionView?.backgroundColor = UIColor.whiteColor()

        // Do any additional setup after loading the view.

    }


    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return imageCount
    }

    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as! FlickrCollectionViewCell
          
        // Configure the cell
        let photos = selectedPin.photos.allObjects
        let photo = photos[indexPath.row] as! Photo
        
        if let fileName = photo.fileName {
            if (fileManager.fileExistsAtPath(FlickrWSClient.sharedInstance.getFilePath(fileName))) {
                cell.mainImage.image = UIImage(contentsOfFile: wsClient.getFilePath(fileName))
            } else {
                FlickrWSClient.sharedInstance.downloadImage(photo, indexPath: indexPath, callBack: imageDownloaded)
            }
        } else {
            FlickrWSClient.sharedInstance.downloadImage(photo, indexPath: indexPath, callBack: imageDownloaded)
        }
        
        
        return cell
    }
    func imageDownloaded (indexPath: NSIndexPath?, photo: Photo?, error: NSError? ) {
        if let indexPath = indexPath {
            // image finished downloading update the collection
            dispatch_async(dispatch_get_main_queue(), {
                let newCell = self.collectionView?.cellForItemAtIndexPath(indexPath) as? FlickrCollectionViewCell
                if let newCell = newCell {
                    let path = self.wsClient.getFilePath((photo?.fileName)!)
                    newCell.mainImage.image = UIImage(contentsOfFile: path)
                    CoreDataStackManager.sharedInstance().saveContext()
                }
            })
        }
        
    }
    
    // remove photo on click
    override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {

        let photo = selectedPin.photos.allObjects[indexPath.row]
        
        // Remove the photo from the array
        selectedPin.photos.removeObject(photo)
        
        imageCount--
        
        // Remove the cell from the collection
        collectionView.reloadData()
        //collectionView.deleteItemsAtIndexPaths([indexPath])
        
        // Remove from file system
        //try! fileManager.removeItemAtPath(photo.filePath!!)
        if let photo = photo as? Photo {
            if let fileName = photo.fileName {
                // Remove from file system
                let filePath = wsClient.getFilePath(fileName)
                if fileManager.fileExistsAtPath(filePath) {
                    try! fileManager.removeItemAtPath(filePath)
                }
            }
        }

        // Remove the photo from the context
        sharedContext.deleteObject(photo as! NSManagedObject)
        
        CoreDataStackManager.sharedInstance().saveContext()
        
    }
    
    @IBAction func reloadPhotosFromFlikr(sender: AnyObject) {
        
        for photo in selectedPin.photos {
            if let photo = photo as? Photo {
                if let fileName = photo.fileName {
                    // Remove from file system
                    let filePath = wsClient.getFilePath(fileName)
                    if fileManager.fileExistsAtPath(filePath) {
                        try! fileManager.removeItemAtPath(filePath)
                    }
                }
            }
        
            
            // Remove the photo from the context
            sharedContext.deleteObject(photo as! NSManagedObject)

        }
        let items = collectionView?.numberOfItemsInSection(0)
        if let items = items {
            // reset back to loading image
            for index in 1...items {
                let indexPath = NSIndexPath(forItem: index-1, inSection: 0)
                let cell = collectionView?.cellForItemAtIndexPath(indexPath) as? FlickrCollectionViewCell
                if let cell = cell {
                    cell.mainImage.image = UIImage(named: "Loading Image")
                }
            }
        }
        
        // save the removal
        CoreDataStackManager.sharedInstance().saveContext()
        
        // reload the images
        wsClient.callFlickrForImages(selectedPin, pages: selectedPin.pages as Int, callBack: flickImageResults)
        
        
    }
   
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }
    
    func flickImageResults (result: AnyObject?, error: NSError? ) {
        if let error = error {
            // error
            print("There was an error: \(error)")
        } else {
            //print(result)
            let perPage = result!["photos"]??["perpage"] as? Int
            if let perPage = perPage {
                dispatch_async(dispatch_get_main_queue(), {
                    var photos = [Photo]()
                    for photo in result!["photos"]??["photo"] as! [AnyObject] {
                        let photo = Photo(photoUrl: photo["url_m"] as! String, fileName: nil, pin: self.selectedPin, context: self.sharedContext)
                        photos.append(photo)
                    }
                    
                    self.imageCount = photos.count
                    
                    CoreDataStackManager.sharedInstance().saveContext()
                    
                    self.collectionView!.reloadData()
                    
                })
            } else {
                // error
                print("There was an error: \(error)")
            }
            
            
        }
        
    }


   
}
