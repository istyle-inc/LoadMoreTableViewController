# LoadMoreTableViewController

[![CI Status](http://img.shields.io/travis/mishimay/LoadMoreTableViewController.svg?style=flat)](https://travis-ci.org/mishimay/LoadMoreTableViewController)
[![Version](https://img.shields.io/cocoapods/v/LoadMoreTableViewController.svg?style=flat)](http://cocoapods.org/pods/LoadMoreTableViewController)
[![License](https://img.shields.io/cocoapods/l/LoadMoreTableViewController.svg?style=flat)](http://cocoapods.org/pods/LoadMoreTableViewController)
[![Platform](https://img.shields.io/cocoapods/p/LoadMoreTableViewController.svg?style=flat)](http://cocoapods.org/pods/LoadMoreTableViewController)

## Usage

### データの表示

LoadMoreTableViewControllerを利用するには以下の設定を行う必要がある。

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
    loadMoreTableViewController.fetchSourceObjects = { [weak self] completion in
        Follow.fetchFollow(currentCount, result: { result in
            switch result {
            case .Success(let users):
                completion(sourceObjects: users, hasNext: true)
            case .Failure(_):
                loadMoreTableViewController.showRetryButton()
            }
        })
    }
```

- `public var configureCell: (cell: UITableViewCell, row: Int) -> UITableViewCell`
    - cellの設定をする。
    - e.g.

```swift
    loadMoreTableViewController.configureCell = { [weak self] cell, row in
        if let cell = cell as? FollowCell {
            let user = loadMoreTableViewController.sourceObjects[row] as? User
            cell.title.text = user?.name
        }
        return cell
    }
```

- `public var topCells: UITableViewCell` (オプション)
    - TableViewの上部に、追加読み込みするcellとは別のcellを表示する。
    - e.g.

```swift
    loadMoreTableViewController.topCells = [HeaderCell.instantiate()]
```

### データを最初から再読み込みする

- `public func refreshData(immediately immediately: Bool)`
    - immediately: true
        - tableViewを空にし、Activity Indicator をトップに配置してデータ取得処理を走らせる。
    - immediately: false
        - 1件目からのデータを取得した後にtableViewを更新する。
        - `UIRefreshControl` を使う際に、LoadMoreTableViewControllerの Activity Indicator を表示させないために用意。

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

LoadMoreTableViewController is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "LoadMoreTableViewController"
```

## Author

mishimay, mishimay@istyle.co.jp

## License

LoadMoreTableViewController is available under the MIT license. See the LICENSE file for more info.
