//
//  Feed.swift
//  Reader
//
//  Created by Douglas Frari on 2/5/20.
//  Copyright © 2020 Razeware LLC. All rights reserved.
//

import Cocoa

class Feed: NSObject {

  let name: String
  var children = [FeedItem]()
  
  init(name: String) {
    self.name = name
  }
  
  
  class func feedList(_ fileName: String) -> [Feed] {
   //1 Creates an empty Feed array.
   var feeds = [Feed]()
     
   //2 Tries to load an array of dictionaries from the file.
   if let feedList = NSArray(contentsOfFile: fileName) as? [NSDictionary] {
     //3 If this worked, loops through the entries.
     for feedItems in feedList {
       //4 The dictionary contains a key name that is used to inititalize Feed.
       let feed = Feed(name: feedItems.object(forKey: "name") as! String)
       //5 The key items contains another array of dictionaries.
       let items = feedItems.object(forKey: "items") as! [NSDictionary]
       //6 Loops through the dictionaries.
       for dict in items {
         //7 Initializes a FeedItem. This item is appended to the children array of the parent Feed.
         let item = FeedItem(dictionary: dict)
         feed.children.append(item)
       }
       //8 After the loop, every child for the Feed is added to the feeds array before the next Feed starts loading.
       feeds.append(feed)
     }
   }
     
   //9 Returns the feeds. If everything worked as expected, this array will contain 2 Feed objects.
   return feeds
  }

  
  
} // end Feed


