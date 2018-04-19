/**
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

class ViewController: NSViewController {
  @IBOutlet var searchResultsController: NSArrayController!
  @IBOutlet weak var numberResultsComboBox: NSComboBox!
  @IBOutlet weak var collectionView: NSCollectionView!
  @IBOutlet weak var searchTextField: NSTextField!
  
  dynamic var loading = false
  
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    let itemPrototype = self.storyboard?.instantiateController(withIdentifier: "collectionViewItem") as! NSCollectionViewItem
    collectionView.itemPrototype = itemPrototype
  }
  
  @IBAction func searchClicked(_ sender: Any) {
    
    // 1 Check the text field; if it’s blank, don’t send that query to iTunes search API.
    if searchTextField.stringValue == "" {
      return
    }
    
    // 2 Get the value in the dropdown. This number is passed to the API and controls how many search results to return. There’s a number of preconfigured options in the dropdown, but you can also type in other numbers — 200 is the maximum
    guard let resultsNumber = Int(numberResultsComboBox.stringValue) else {return}
    
    // 3 Make a call to getSearchResults(_:results:langString:completionHandler:). This passes in the number of results from the combo box and the query string you typed into the text field. It returns, via a completion handler, either an array of Dictionary result objects or an NSError object if there’s a problem completing the query. Note that the method already handles the JSON parsing.
    loading = true
    
    iTunesRequestManager.getSearchResults(searchTextField.stringValue, results: resultsNumber, langString: "en_us", completionHandler: {results, error in
      
      // 4 Here you use some Swift-style array mapping to pass the dictionary into an initialization method that creates a Result object. When done, the itunesResults variable contains an array of Result objects.
      let itunesResults = results.map{ return Result(dictionary: $0)}
        
        // TODO deal with rank here later
        .enumerated().map({ index, element -> Result in
          element.rank = index + 1
          return element
        })
      
      // 5 Before you can set this new data on the searchResultsController, you need to make sure you’re on the main thread. Therefore you use DispatchQueue.main.async to get to the main queue. You haven’t set up any bindings, but once you have, altering the content property on the searchResultsController will update the NSTableView (and potentially other UI elements) on the current thread. Updating UI on a background thread is always a no-no.
      DispatchQueue.main.async {
        self.loading = false
        // 6 Finally you set the content property of the NSArrayController. The array controller has a number of different methods to add or remove objects it manages. Each time you search, you want to clear out the previous results and work with the results of the latest query. For now, print the content of searchResultsController to the console to verify that everything works as planned.
        self.searchResultsController.content = itunesResults
        print(self.searchResultsController.content!)
      }
    })
  }
  
  //1 tableViewSelectionDidChange(_:) fires every time the user selects a different row in the table.
  func tableViewSelectionDidChange(_ notification: NSNotification) {
    //2 The array controller property selectedObjects returns an array containing all the objects for the indexes of the rows selected in the table. In your case, the table will only permit a single selection, so this array always contains a single object. You store the object in the result object.
    guard let result = searchResultsController.selectedObjects.first as? Result else { return }
    //3 Finally, you call loadIcon(). This method downloads the image on a background thread and then updates the Result objects artworkImage property when the image downloads on the main thread.
    result.loadIcon()
    
    // This populates the screenshot images and creates the right number of views.
    result.loadScreenShots()
  }
  
}

extension ViewController: NSTextFieldDelegate {
  func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
    if commandSelector == #selector(insertNewline(_:)) {
      searchClicked(searchTextField)
    }
    return false
  }
}
