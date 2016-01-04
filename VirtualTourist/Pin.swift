//
//  Pin.swift
//  VirtualTourist
//
//  Created by Evan Scharfer on 12/16/15.
//  Copyright © 2015 Evan Scharfer. All rights reserved.
//

import CoreData

class Pin : NSManagedObject {
    @NSManaged var latitude : NSNumber
    @NSManaged var longitude : NSNumber
    @NSManaged var photos: NSMutableSet
    @NSManaged var pages: NSNumber
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(latitude: Double, longitude: Double, context: NSManagedObjectContext) {
        let entity =  NSEntityDescription.entityForName("Pin", inManagedObjectContext: context)!
        
        // Now we can call an init method that we have inherited from NSManagedObject. Remember that
        // the Person class is a subclass of NSManagedObject. This inherited init method does the
        // work of "inserting" our object into the context that was passed in as a parameter
        super.init(entity: entity,insertIntoManagedObjectContext: context)

        
        self.latitude = latitude
        self.longitude = longitude
        pages = 1
        //photos = [Photo]()
    }
    
    
    
}
