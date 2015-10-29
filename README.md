# ReadMoreTableViewController

[![CI Status](http://img.shields.io/travis/mishimay/ReadMoreTableViewController.svg?style=flat)](https://travis-ci.org/mishimay/ReadMoreTableViewController)
[![Version](https://img.shields.io/cocoapods/v/ReadMoreTableViewController.svg?style=flat)](http://cocoapods.org/pods/ReadMoreTableViewController)
[![License](https://img.shields.io/cocoapods/l/ReadMoreTableViewController.svg?style=flat)](http://cocoapods.org/pods/ReadMoreTableViewController)
[![Platform](https://img.shields.io/cocoapods/p/ReadMoreTableViewController.svg?style=flat)](http://cocoapods.org/pods/ReadMoreTableViewController)

## Usage

### データの表示

このクラスを利用する際には以下のメソッドの呼び出し/プロパティの設定を行う必要がある。

#### メソッド

- `public func registerNib(nibName: String)`
  - 表示するcellのxibファイル名を登録する。
  - e.g.

```swift
    readMoreTableViewController.registerNib("FollowCell")
```

#### プロパティ

- `public var configureCellClosure: (cell: UITableViewCell, row: Int) -> UITableViewCell`
  - cellの設定をする。
  - e.g.

```swift
    readMoreTableViewController.configureCellClosure = { [weak self] cell, row in
        if let cell = cell as? FollowCell {
            let user = self?.users[row]
            cell.title.text = user.name
        }
        return cell
    }
```

- `public var fetchReadCountClosure: (currentCount: Int, completion: (readCount: Int, hasNext: Bool) -> ()) -> ()`
  - このクロージャ内で新しいデータをフェッチする。
  - completionクロージャを呼び出すことで以下の情報を返す。
    - 新たに読み込むcellの数(`readCount`)。
    - また、その次の読み込みがあるかどうか(`hasNext`)。
  - e.g.

```swift
    readMoreTableViewController.fetchReadCountClosure = { [weak self] currentCount, completion in
        Follow.fetchFollow(currentCount, result: { result in
            switch result {
            case .Success(let users):
                self?.users += users
                completion(readCount: users.count, hasNext: true)
            case .Failure(_):
                break
            }
        })
    }
```

- `public var topCells: UITableViewCell`
  - TableViewの上部に、追加読み込みするcellとは別のcellを表示する。
  - e.g.

```swift
    readMoreTableViewController.topCells = [HeaderCell.instantiate()]
```

### データを最初から再読み込みする

```swift
    clearData()
```

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
