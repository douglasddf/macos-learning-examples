/*
 * Copyright (c) 2016 Razeware LLC
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

import Cocoa
import WebKit

// VISTO https://www.raywenderlich.com/1201-nsoutlineview-on-macos-tutorial

class ViewController: NSViewController {
  
  @IBOutlet weak var webView: WebView!
  @IBOutlet weak var outlineView: NSOutlineView!
  
  var feeds = [Feed]()
  let dateFormatter = DateFormatter()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    
    dateFormatter.dateStyle = .short
    
    if let filePath = Bundle.main.path(forResource: "Feeds", ofType: "plist") {
      feeds = Feed.feedList(filePath)
      print(feeds)
      outlineView.reloadData()
    }
  }
  
  
  @IBAction func doubleClickItem(_ sender: NSOutlineView) {
    print("-- doubleClickItem --")
    
    //1 Gets the clicked item.
    let item = sender.item(atRow: sender.clickedRow)
    
    //2 Checks whether this item is a Feed, which is the only item that can be expanded or collapsed.
    if item is Feed {
      //3 If the item is a Feed, asks the outline view if the item is expanded or collapsed, and calls the appropriate method.
      if sender.isItemExpanded(item) {
        sender.collapseItem(item)
      } else {
        sender.expandItem(item)
      }
    }
  }
  
  override func keyDown(with theEvent: NSEvent) {
    interpretKeyEvents([theEvent])
  }
  
  override func deleteBackward(_ sender: Any?) {
    //1
    let selectedRow = outlineView.selectedRow
    if selectedRow == -1 {
      return
    }
      
    //2
    outlineView.beginUpdates()
    
    //3
    if let item = outlineView.item(atRow: selectedRow) {
         
      //4
      if let item = item as? Feed {
        //5
        if let index = self.feeds.firstIndex( where: {$0.name == item.name} ) {
          //6
          self.feeds.remove(at: index)
          //7
          outlineView.removeItems(at: IndexSet(integer: selectedRow), inParent: nil, withAnimation: .slideLeft)
        }
      } else if let item = item as? FeedItem {
        //8
        for feed in self.feeds {
          //9
          if let index = feed.children.firstIndex( where: {$0.title == item.title} ) {
            feed.children.remove(at: index)
            outlineView.removeItems(at: IndexSet(integer: index), inParent: feed, withAnimation: .slideLeft)
          }
        }
      }
    }

    outlineView.endUpdates()
  }
  
  
} // end ViewController

extension ViewController: NSOutlineViewDataSource {
  
  func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
    
    //1 If item is a Feed, it returns the number of children.
    if let feed = item as? Feed {
      return feed.children.count
    }
    //2 Otherwise, it returns the number of feeds.
    return feeds.count
  }
  
  func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
    /*
     This checks whether item is a Feed; if so, it returns the FeedItem for the given index.
     Otherwise, it return a Feed. Again, item will be nil for the root object.
     */
    if let feed = item as? Feed {
      return feed.children[index]
    }
    
    return feeds[index]
  }
  
  func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
    /*
     One great feature of NSOutlineView is that it can collapse items. First, however,
     you have to tell it which items can be collapsed or expanded. Add the following:
     */
    if let feed = item as? Feed {
      return feed.children.count > 0
    }
    
    return false
  }
  
  
}


extension ViewController: NSOutlineViewDelegate {
  
  func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
    var view: NSTableCellView?
    
    //1 Checks if item is a Feed.
    if let feed = item as? Feed {
      
      if tableColumn?.identifier.rawValue == "DateColumn" {
        view = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "DateCell"), owner: self) as? NSTableCellView
        if let textField = view?.textField {
          textField.stringValue = ""
          textField.sizeToFit()
        }
      } else {
        //2 Gets a view for a Feed from the outline view. A normal NSTableViewCell contains a text field.
        view = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "FeedCell"), owner: self) as? NSTableCellView
        if let textField = view?.textField {
          //3 Sets the text field’s text to the feed’s name and calls sizeToFit(). This causes the text field to recalculate its frame so the contents fit inside.
          textField.stringValue = feed.name
          textField.sizeToFit()
        }
      }
      
    } else if let feedItem = item as? FeedItem {
      //1 if item is a FeedItem, you fill two columns: one for the title and another one for the publishingDate. You can differentiate the columns with their identifier.
      if tableColumn?.identifier.rawValue == "DateColumn" {
        //2 If the identifier is dateColumn, you request a DateCell.
        view = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "DateCell"), owner: self) as? NSTableCellView
        
        if let textField = view?.textField {
          //3 You use the date formatter to create a string from the publishingDate.
          textField.stringValue = dateFormatter.string(from: feedItem.publishingDate)
          textField.sizeToFit()
        }
      } else {
        //4 If it is not a dateColumn, you need a cell for a FeedItem.
        view = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "FeedItemCell"), owner: self) as? NSTableCellView
        if let textField = view?.textField {
          //5 You set the text to the title of the FeedItem.
          textField.stringValue = feedItem.title
          textField.sizeToFit()
        }
      }
    }
    
    return view
  }
  
  
  func outlineViewSelectionDidChange(_ notification: Notification) {
    //1 Checks if the notification object is an NSOutlineView. If not, return early.
    guard let outlineView = notification.object as? NSOutlineView else {
      return
    }
    //2 Gets the selected index and checks if the selected row contains a FeedItem or a Feed.
    let selectedIndex = outlineView.selectedRow
    if let feedItem = outlineView.item(atRow: selectedIndex) as? FeedItem {
      //3 If a FeedItem was selected, creates a NSURL from the url property of the Feed object.
      let url = URL(string: feedItem.url)
      //4 Checks whether this succeeded.
      if let url = url {
        //5 Finally, loads the page.
        self.webView.mainFrame.load(URLRequest(url: url))
      }
    }
  }
  
}
