//
//  Photo.swift
//  VirtualTourist
//
//  Created by Evan Scharfer on 12/18/15.
//  Copyright © 2015 Evan Scharfer. All rights reserved.
//

import CoreData

class Photo : NSManagedObject {

    @NSManaged var photoUrl : String
    @NSManaged var filePath : String?
    @NSManaged var pin: Pin
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(photoUrl: String, filePath: String?, pin: Pin, context: NSManagedObjectContext) {
        let entity =  NSEntityDescription.entityForName("Photo", inManagedObjectContext: context)!
        
        // Now we can call an init method that we have inherited from NSManagedObject. Remember that
        // the Person class is a subclass of NSManagedObject. This inherited init method does the
        // work of "inserting" our object into the context that was passed in as a parameter
        super.init(entity: entity,insertIntoManagedObjectContext: context)
        
        
        self.photoUrl = photoUrl
        self.filePath = filePath
        self.pin = pin
    }

}
