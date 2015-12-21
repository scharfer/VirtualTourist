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
        
        if let filePath = photo.filePath {
            if (fileManager.fileExistsAtPath(filePath)) {
                cell.mainImage.image = UIImage(contentsOfFile: filePath)
            } else {
                FlickrWSClient.sharedInstance().downloadImage(photo, indexPath: indexPath, callBack: imageDownloaded)
            }
        } else {
            FlickrWSClient.sharedInstance().downloadImage(photo, indexPath: indexPath, callBack: imageDownloaded)
        }
        
        
        return cell
    }
    func imageDownloaded (indexPath: NSIndexPath?, photo: Photo?, error: NSError? ) {
        if let indexPath = indexPath {
            // image finished downloading update the collection
            dispatch_async(dispatch_get_main_queue(), {
                let newCell = self.collectionView?.cellForItemAtIndexPath(indexPath) as? FlickrCollectionViewCell
                if let newCell = newCell {
                    newCell.mainImage.image = UIImage(contentsOfFile: (photo?.filePath)!)
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
        
        // Remove the cell from the collection
        collectionView.reloadData()
        //collectionView.deleteItemsAtIndexPaths([indexPath])
        
        // Remove from file system
        try! fileManager.removeItemAtPath(photo.filePath!!)

        // Remove the photo from the context
        sharedContext.deleteObject(photo as! NSManagedObject)
        
        CoreDataStackManager.sharedInstance().saveContext()
        
    }
    
    @IBAction func reloadPhotosFromFlikr(sender: AnyObject) {
        
        for photo in selectedPin.photos {
            
            // Remove from file system
            if let filePath = photo.filePath! {
                if fileManager.fileExistsAtPath(filePath) {
                    try! fileManager.removeItemAtPath(filePath)
                }
            }
            
            // Remove the photo from the context
            sharedContext.deleteObject(photo as! NSManagedObject)

        }
        // remove all the old images
        selectedPin.photos.removeAllObjects()
        
        // save the removal
        CoreDataStackManager.sharedInstance().saveContext()
        
        // reload the images
        FlickrWSClient.sharedInstance().callFlickrForImages(selectedPin, callBack: flickImageResults)
        
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
                        let photo = Photo(photoUrl: photo["url_m"] as! String, filePath: nil, pin: self.selectedPin, context: self.sharedContext)
                        photos.append(photo)
                    }
                    
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
