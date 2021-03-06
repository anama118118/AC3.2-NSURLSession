//
//  InstaCatFactory.swift
//  AC3.2-InstaCats-2
//
//  Created by Louis Tur on 10/11/16.
//  Copyright © 2016 C4Q. All rights reserved.
//

import UIKit


/// Used to create `[InstaCat]`
// More like a singleton usable app wide
class InstaCatFactory {
    
    //Need to call manager
    //Use it every time to use a singleton
    static let manager: InstaCatFactory = InstaCatFactory()
    public init() {} //no public initializer
    
    
    /// Attempts to make `[InstaCat]` from the `Data` contained in a local file
    /// - parameter filename: The name of the file containing json-formatted data, including its extension in the name
    /// - returns: An array of `InstaCat` if the file is located and has properly formatted data. `nil` otherwise.
    class func makeInstaCats(fileName: String) -> [InstaCat]? {
        
        // Everything from viewDidLoad in InstaCatTableViewController has just been moved here
        guard let instaCatsURL: URL = InstaCatFactory.manager.getResourceURL(from: fileName),
            let instaCatData: Data = InstaCatFactory.manager.getData(from: instaCatsURL),
            let instaCatsAll: [InstaCat] = InstaCatFactory.manager.getInstaCats(from: instaCatData) else {
                return nil
        }
        
        return instaCatsAll
    }
    
    
    /// Gets the `URL` for a local file
    // The fileprivate change the scope of the file
    fileprivate func getResourceURL(from fileName: String) -> URL? {
        
        guard let dotRange = fileName.rangeOfCharacter(from: CharacterSet.init(charactersIn: ".")) else {
            return nil
        }
        
        let fileNameComponent: String = fileName.substring(to: dotRange.lowerBound)
        let fileExtensionComponent: String = fileName.substring(from: dotRange.upperBound)
        
        let fileURL: URL? = Bundle.main.url(forResource: fileNameComponent, withExtension: fileExtensionComponent)
        
        return fileURL
    }
    
    /// Gets the `Data` from the local file located at a specified `URL`
    fileprivate func getData(from url: URL) -> Data? {
        
        let fileData: Data? = try? Data(contentsOf: url)
        return fileData
    }
    
    
    // MARK: - Data Parsing
    /// Creates `[InstaCat]` from valid `Data`
    internal func getInstaCats(from jsonData: Data) -> [InstaCat]? {
        
        do {
            let instaCatJSONData: Any = try JSONSerialization.jsonObject(with: jsonData, options: [])
            
            // Cast from Any and check for the "cats" key
            guard let instaCatJSONCasted: [String : AnyObject] = instaCatJSONData as? [String : AnyObject],
                let instaCatArray: [AnyObject] = instaCatJSONCasted["cats"] as? [AnyObject] else {
                    return nil
            }
            
            var instaCats: [InstaCat] = []
            instaCatArray.forEach({ instaCatObject in
                guard let instaCatName: String = instaCatObject["name"] as? String,
                    let instaCatIDString: String = instaCatObject["cat_id"] as? String,
                    let instaCatInstagramURLString: String = instaCatObject["instagram"] as? String,
                    
                    // Some of these values need further casting
                    let instaCatID: Int = Int(instaCatIDString),
                    let instaCatInstagramURL: URL = URL(string: instaCatInstagramURLString) else {
                        return
                }
                
                // append to our temp array
                instaCats.append(InstaCat(name: instaCatName, id: instaCatID, instagramURL: instaCatInstagramURL))
            })
            
            return instaCats
        }
        catch let error as NSError {
            print("Error occurred while parsing data: \(error.localizedDescription)")
        }
        
        return  nil
    }
    
    //func getInstaCats(from apiEndpoint: String) -> [InstaCat]? {
    func getInstaCats(apiEndpoint: String, callback: @escaping ([InstaCat]?) -> Void){
        if let validInstaCatEndpoint: URL = URL(string: apiEndpoint) {
            
            // 1. URLSession/Configuration
            let session = URLSession(configuration: URLSessionConfiguration.default)
            
            // 2. dataTaskWithURL
            session.dataTask(with: validInstaCatEndpoint) { (data: Data?, response: URLResponse?, error: Error?) in
                
                // 3. check for errors right away
                if error != nil {
                    print("Error encountered!: \(error!)")
                }
                
                // 4. printing out the data
                if let validData: Data = data {
                    print(validData)
                    
                    // 5. reuse our code to make some cats from Data
                    //let allTheCats: [InstaCat]? = InstaCatFactory.manager.getInstaCats(from: validData)
                    
                    // 6. if we're able to get non-nil [InstaCat], set our variable and reload the data
                    if let allTheCats: [InstaCat] = InstaCatFactory.manager.getInstaCats(from: validData) {
                        
                        print(allTheCats)
                        callback(allTheCats)
                        //print(self.instaCats)
                        // update the UI by wrapping the UI-updating code inside of a DispatchQueue closure
                        //self.instaCats = allTheCats
                        //DispatchQueue.main.async {
                        //self.tableView.reloadData()
                        //}
                    }
                }
                // 4a. ALSO THIS!
                }.resume()
            
        }
        //return nil
    }
    
    
}
