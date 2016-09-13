# LoadMoreTableViewController

LoadMoreTableViewController is a TableViewController that helps you to show some data like fetched from a web API  successively.

<img src="screen.gif" width="354" height="550">

## Basic Usage

### Prepare a Cell

You need to prepare a cell that is displayed on a LoadMoreTableViewController.

- Xib file way

    1. Create a xib file then put a Table View Cell on it.
    1. Register the cell to the table of the LoadMoreTableViewController with using UITableView method `register(_:forCellReuseIdentifier:)`.
        - The cellReuseIdentifier should be the same as the LoadMoreTableViewController property `public var cellReuseIdentifier`.

- Storyboard way

    1. On a Storyboard, add a Table View Cell to a Table View Controller that inherits LoadMoreTableViewController.
    1. Set the Identifier of the Table View cell as it is the same as the LoadMoreTableViewController property `public var cellReuseIdentifier`.

The cell's identifier should be the same as the LoadMoreTableViewController property `public var cellReuseIdentifier` on the both ways.
The default value is `"Cell"` and it is configureable.

The cell should be designed with using Auto Layout.
The LoadMoreTableViewController is using Automatic Dimension feature of UITableView so it will adjust the cell height.

### Set Closures

- `public var fetchSourceObjects: (_ completion: @escaping (_ sourceObjects: [Any], _ hasNext: Bool) -> ()) -> ()`
    - Fetch the new data in this closure.
    - Call `completion` closure to return these information.
        - The fetched new objects (`sourceObjects`).
        - If the next loading exists (`hasNext`).

- `public var configureCell: (_ cell: UITableViewCell, _ row: Int) -> UITableViewCell`
    - Configure the cell and return it in this closure.
    - The cell type is the same as you prepared.

### Example

```swift
import LoadMoreTableViewController

class MyTableViewController: LoadMoreTableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.registerNib(UINib(nibName: "StandardCell", bundle: nil), forCellReuseIdentifier: cellReuseIdentifier)

        fetchSourceObjects = { [weak self] completion in
            self?.request(offset: sourceObjects.count) { products in
                completion(products, true)
            }
        }
        configureCell = { [weak self] cell, row in
            cell.textLabel?.text = (self?.sourceObjects[row] as? Product)?.title
            return cell
        }
    }

}
```

See also the example project.

## Additional Usage

### Data Source

The fetched data are stored to the array `public var sourceObjects: [Any]`.
You can directly access or manipulate this array.

### Refreshing Data

Use function `public func refreshData(immediately immediately: Bool)`.
- immediately: true
    - Immediately makes the tableView empty and starts fetching the data from the first.
    - The loading activity indicator shows on the top.
- immediately: false
    - Refreshes the tableView after fetching the data from the first.
    - This prevents the loading activity indicator is displayed on the top when UIRefreshControl is used.

### Other Settings

- `public func showRetryButton()`
    - Changes the loading activity indicator to retry button.
    - When retry button is tapped, next loading starts.

- `public static var retryText: String?`
    - Changes retry button text.

- `public static var retryImage: UIImage?`
    - Changes retry button image.

- `public var didSelectRow: ((Int) -> ())?`
    - Notifies what row is selected.

## Requirements

Swift 3.0

## Installation

```ruby
pod "LoadMoreTableViewController"
```

## Author

mishimay, mishimay@istyle.co.jp

## License

LoadMoreTableViewController is available under the MIT license. See the LICENSE file for more info.
