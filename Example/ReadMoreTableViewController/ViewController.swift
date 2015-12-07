//
//  ViewController.swift
//  ReadMoreTableViewController
//
//  Created by mishimay on 10/22/2015.
//  Copyright (c) 2015 mishimay. All rights reserved.
//

import UIKit
import ReadMoreTableViewController

func delay(delay: NSTimeInterval, mainThread: Bool = true, block: () -> ()) {
    let time = dispatch_time(DISPATCH_TIME_NOW, Int64(delay * Double(NSEC_PER_SEC)))
    dispatch_after(time, dispatch_get_main_queue(), block)
}

class ViewController: ReadMoreTableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Clear", style: .Plain, target: self, action: "clear")
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Refresh", style: .Plain, target: self, action: "refresh")

        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: "refresh", forControlEvents: .ValueChanged)

        tableView.registerNib(UINib(nibName: "SampleCell", bundle: nil), forCellReuseIdentifier: cellIdentifier)

        ReadMoreTableViewController.retryText = "Custom Retry Text"
        fetchSourceObjects = { [weak self] completion in
            let newNumbers = Array(1...5).map { $0 + (self?.sourceObjects.count ?? 0) }

            delay(1) { // Pretend to fetch data
                self?.refreshControl?.performSelector("endRefreshing", withObject: nil, afterDelay: 0.05) // cf. http://stackoverflow.com/questions/28560068/uirefreshcontrol-endrefreshing-is-not-smooth

                // Test retry button
                let showRetryButton = newNumbers.filter { $0 % 20 == 0 }.count > 0
                if showRetryButton {
                    delay(0.1) {
                        self?.showRetryButton()
                    }
                }

                let newTitles = newNumbers.map { "sample\($0)" }
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
    }

    func refresh() {
        refreshData(immediately: false)
    }

}
