//
//  ViewController.swift
//  ReadMoreTableViewController
//
//  Created by mishimay on 10/22/2015.
//  Copyright (c) 2015 mishimay. All rights reserved.
//

import UIKit
import ReadMoreTableViewController

class ViewController: ReadMoreTableViewController {

    private var retryButtonShowCount = 0

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Clear", style: .Plain, target: self, action: "clear")
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Refresh", style: .Plain, target: self, action: "refresh")

        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: "refresh", forControlEvents: .ValueChanged)

        tableView.registerNib(UINib(nibName: "SampleCell", bundle: nil), forCellReuseIdentifier: cellIdentifier)

        ReadMoreTableViewController.retryText = "Custom Retry Text"
        fetchSourceObjects = { [weak self] completion in
            let newTitles = Array(1...5).map { "sample\($0 + (self?.sourceObjects.count ?? 0))" }

            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(1 * Double(NSEC_PER_SEC))), dispatch_get_main_queue()) {
                self?.refreshControl?.performSelector("endRefreshing", withObject: nil, afterDelay: 0.05) // cf. http://stackoverflow.com/questions/28560068/uirefreshcontrol-endrefreshing-is-not-smooth

                // リトライボタン表示テスト
                guard self?.sourceObjects.count < 20 * ((self?.retryButtonShowCount ?? 0) + 1) else {
                    self?.showRetryButton()
                    self?.retryButtonShowCount++
                    return
                }

                completion(sourceObjects: newTitles, hasNext: true)
            }
        }
        configureCell = { [weak self] cell, row in
            cell.textLabel?.text = self?.sourceObjects[row] as? String
            cell.detailTextLabel?.text = NSDate().description
            return cell
        }
        didSelectRow = { [weak self] row in
            if let title = self?.sourceObjects[row] as? String {
                print("selected \(title)")
            }
        }
    }

    func clear() {
        refreshData(immediately: true)

        retryButtonShowCount = 0
    }

    func refresh() {
        refreshData(immediately: false)

        retryButtonShowCount = 0
    }

}
