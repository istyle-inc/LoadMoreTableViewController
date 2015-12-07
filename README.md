# ReadMoreTableViewController

[![CI Status](http://img.shields.io/travis/mishimay/ReadMoreTableViewController.svg?style=flat)](https://travis-ci.org/mishimay/ReadMoreTableViewController)
[![Version](https://img.shields.io/cocoapods/v/ReadMoreTableViewController.svg?style=flat)](http://cocoapods.org/pods/ReadMoreTableViewController)
[![License](https://img.shields.io/cocoapods/l/ReadMoreTableViewController.svg?style=flat)](http://cocoapods.org/pods/ReadMoreTableViewController)
[![Platform](https://img.shields.io/cocoapods/p/ReadMoreTableViewController.svg?style=flat)](http://cocoapods.org/pods/ReadMoreTableViewController)

## Usage

### データの表示

ReadMoreTableViewControllerを利用するには以下の設定を行う必要がある。

#### Cellの用意

追加読み込みするCellを `registerNib()` したり、Storyboard上に用意する。
その際、プロパティ `public var cellReuseIdentifier` にCellのIdentifierを合わせる必要がある。
CellはAutoLayoutを使用すれば自動でCellの高さが可変する。

#### クロージャの設定

- `public var fetchSourceObjects: (completion: (sourceObjects: [AnyObject], hasNext: Bool) -> ()) -> ()`
    - このクロージャ内で新しいデータをフェッチする。
    - completionクロージャを呼び出すことで以下の情報を返す。
        - 新たに取得したデータ(`sourceObjects`)。
        - 次の読み込みがあるかどうか(`hasNext`)。
    - e.g.

```swift
    readMoreTableViewController.fetchSourceObjects = { [weak self] completion in
        Follow.fetchFollow(currentCount, result: { result in
            switch result {
            case .Success(let users):
                completion(sourceObjects: users, hasNext: true)
            case .Failure(_):
                readMoreTableViewController.showRetryButton()
            }
        })
    }
```

- `public var configureCell: (cell: UITableViewCell, row: Int) -> UITableViewCell`
    - cellの設定をする。
    - e.g.

```swift
    readMoreTableViewController.configureCell = { [weak self] cell, row in
        if let cell = cell as? FollowCell {
            let user = readMoreTableViewController.sourceObjects[row] as? User
            cell.title.text = user?.name
        }
        return cell
    }
```

- `public var topCells: UITableViewCell` (オプション)
    - TableViewの上部に、追加読み込みするcellとは別のcellを表示する。
    - e.g.

```swift
    readMoreTableViewController.topCells = [HeaderCell.instantiate()]
```

### データを最初から再読み込みする

- `public func refreshData(immediately immediately: Bool)`
    - immediately: true
        - tableViewを空にし、Activity Indicator をトップに配置してデータ取得処理を走らせる。
    - immediately: false
        - 1件目からのデータを取得した後にtableViewを更新する。
        - `UIRefreshControl` を使う際に、ReadMoreTableViewControllerの Activity Indicator を表示させないために用意。

### データ管理

取得したデータは `public var sourceObjects = [AnyObject]()` の配列に入る。

### その他設定

- `public func showRetryButton()`
    - Activity Indicator をリトライボタンに変える。

- `public static var retryText: String?`
    - リトライボタンの文言を指定。

- `public static var retryImage: UIImage?``
    - リトライボタンの画像を指定。

- `public var didSelectRow: (Int -> ())?`
    - cellが選択されたときの処理を記述。

## Requirements

## Installation

ReadMoreTableViewController is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "ReadMoreTableViewController"
```

## Author

mishimay, mishimay@istyle.co.jp

## License

ReadMoreTableViewController is available under the MIT license. See the LICENSE file for more info.
