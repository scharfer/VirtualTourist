//
//  File.swift
//  VirtualTourist
//
//  Created by Evan Scharfer on 12/17/15.
//  Copyright © 2015 Evan Scharfer. All rights reserved.
//

import Foundation

class FlickrWSClient : NSObject {
    
    
    let BASE_URL = "https://api.flickr.com/services/rest/"
    let METHOD_NAME = "flickr.photos.search"
    let API_KEY = "ecc4e039c43488324795037aa3903e81"
    let BOUNDING_BOX_HALF_WIDTH = 1.0
    let BOUNDING_BOX_HALF_HEIGHT = 1.0
    let PER_PAGE = 20
    let LAT_MIN = -90.0
    let LAT_MAX = 90.0
    let LON_MIN = -180.0
    let LON_MAX = 180.0

    let fileManager = NSFileManager.defaultManager()
    
    /* Shared session */
    var session: NSURLSession
    
    override init() {
        session = NSURLSession.sharedSession()
        super.init()
    }
    
    func callFlickrForImages(pin : Pin, pages: Int, callBack : (result: AnyObject?, error: NSError? ) -> Void) {
        let randomIndex = arc4random() % UInt32(pages) + 1
        
        //print(randomIndex)
        
        let methodArguments = [
            "method": METHOD_NAME,
            "api_key": API_KEY,
            "per_page": PER_PAGE,
            "page": Int(randomIndex),
            "bbox": createBoundingBoxString(pin.longitude as Double, latitude: pin.latitude as Double),
            "safe_search": "1",
            "extras": "url_m",
            "format": "json",
            "nojsoncallback": "1"
        ]
        
        
        //print("getting flik images")
        makeWSRequest(BASE_URL, params: methodArguments as! [String : AnyObject], requestType: "GET", requestData: nil, headerAttrs: nil, callBack: callBack)

    }
    
    
    
    func makeWSRequest(url: String, params : [String : AnyObject]?, requestType : String, requestData: [String:AnyObject]?, headerAttrs: [String:String]?, callBack : (result: AnyObject?, error: NSError? ) -> Void) -> NSURLSessionDataTask {
        
        
        /* 2/3. Build the URL and configure the request */
        var urlString = url
        if let params = params {
            urlString += escapedParameters(params)
        }
        
        //print("url: \(urlString)")
        
        let url = NSURL(string: urlString)!
        let request = NSMutableURLRequest(URL: url)
        request.HTTPMethod = requestType
        
        if let requestData = requestData {
            request.addValue("application/json", forHTTPHeaderField: "Accept")
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            do {
                request.HTTPBody = try! NSJSONSerialization.dataWithJSONObject(requestData, options: .PrettyPrinted)
                //let test = try! NSJSONSerialization.JSONObjectWithData(request.HTTPBody!, options: .AllowFragments)
                //print("body: \(test)")
            }
        }
        
        if let headerAttrs = headerAttrs {
            for (key, value) in headerAttrs {
                request.addValue(value, forHTTPHeaderField: key)
                
            }
            //print("header: \(headerAttrs)")
        }
        
        /* 4. Make the request */
        let task = session.dataTaskWithRequest(request) { (data, response, error) in
            
            /* GUARD: Was there an error? */
            guard (error == nil) else {
                print("There was an error with your request: \(error)")
                callBack(result: nil, error: error)
                return
            }
            
            /* GUARD: Did we get a successful 2XX response? */
            guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode where statusCode >= 200 && statusCode <= 299 else {
                if let response = response as? NSHTTPURLResponse {
                    print("Your request returned an invalid response! Status code: \(response.statusCode)!")
                } else if let response = response {
                    print("Your request returned an invalid response! Response: \(response)!")
                } else {
                    print("Your request returned an invalid response!")
                }
                let error = NSError(domain: "WSCall", code: 100, userInfo: [NSLocalizedDescriptionKey:"Invalid Status Returned"])
                callBack(result: nil, error: error)
                return
            }
            
            /* GUARD: Was there any data returned? */
            guard let data = data else {
                print("No data was returned by the request!")
                let error = NSError(domain: "WSCall", code: 101, userInfo: [NSLocalizedDescriptionKey:"Server Issue! Please try again later."])
                callBack(result: nil, error: error)
                return
            }
            var parsedResult: AnyObject!
            do {
                parsedResult = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
            } catch {
                let userInfo = [NSLocalizedDescriptionKey : "Could not parse the data as JSON: '\(data)'"]
                callBack(result: nil, error: NSError(domain: "parseJSONWithCompletionHandler", code: 102, userInfo: userInfo))
            }
            
            callBack(result: parsedResult, error: nil)
            
        }
        
        /* 7. Start the request */
        task.resume()
        
        return task
        
    }
    
    func downloadImage(photo: Photo, indexPath: NSIndexPath, callBack : (indexPath: NSIndexPath?, photo: Photo?, error: NSError? ) -> Void) -> NSURLSessionDownloadTask {
        //print("getting image: " + photo.photoUrl)
        
        let request = NSURL(string: photo.photoUrl)
        
        let task = session.downloadTaskWithURL(request!) { (location, response, error) in
            
            /* GUARD: Was there an error? */
            guard (error == nil) else {
                print("There was an error with your request: \(error)")
                callBack(indexPath: nil, photo: nil, error: error)
                return
            }
  
            let dirPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as String
            let currentDateTime = NSDate()
            let formatter = NSDateFormatter()
            formatter.dateFormat = "ddMMyyyy-HHmmssSSS"
            // create the filename and add a uuid to make sure unique
            let photoName = NSUUID().UUIDString + formatter.stringFromDate(currentDateTime)+".jpg"
            let pathArray = [dirPath, photoName]
            let filePath = NSURL.fileURLWithPathComponents(pathArray)
            // move file to documents directory
            try! self.fileManager.moveItemAtURL(location!, toURL: filePath!)
            photo.fileName = photoName
            
            callBack(indexPath: indexPath, photo: photo, error: nil)
            
        }
        
        
        /* 7. Start the request */
        task.resume()
        
        return task
        
    }
    
    func createBoundingBoxString(longitude : Double, latitude: Double) -> String {
        
        /* Fix added to ensure box is bounded by minimum and maximums */
        let bottom_left_lon = max(longitude - BOUNDING_BOX_HALF_WIDTH, LON_MIN)
        let bottom_left_lat = max(latitude - BOUNDING_BOX_HALF_HEIGHT, LAT_MIN)
        let top_right_lon = min(longitude + BOUNDING_BOX_HALF_HEIGHT, LON_MAX)
        let top_right_lat = min(latitude + BOUNDING_BOX_HALF_HEIGHT, LAT_MAX)
        
        return "\(bottom_left_lon),\(bottom_left_lat),\(top_right_lon),\(top_right_lat)"
    }
    
    func escapedParameters(parameters: [String : AnyObject]) -> String {
        
        var urlVars = [String]()
        
        for (key, value) in parameters {
            
            /* Make sure that it is a string value */
            let stringValue = "\(value)"
            
            /* Escape it */
            let escapedValue = stringValue.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
            
            /* Append it */
            urlVars += [key + "=" + "\(escapedValue!)"]
            
        }
        
        return (!urlVars.isEmpty ? "?" : "") + urlVars.joinWithSeparator("&")
    }
    
    func getFilePath(fileName: String) -> String {
        let dirPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as String
        // create the filename and add a uuid to make sure unique
        let pathArray = [dirPath, fileName]
        let filePath = NSURL.fileURLWithPathComponents(pathArray)
        return filePath!.path!
    }

    
    static var sharedInstance = FlickrWSClient()


}