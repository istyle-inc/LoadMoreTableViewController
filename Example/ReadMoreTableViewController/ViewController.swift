//
//  ViewController.swift
//  ReadMoreTableViewController
//
//  Created by mishimay on 10/22/2015.
//  Copyright (c) 2015 mishimay. All rights reserved.
//

import UIKit
import ReadMoreTableViewController

class ViewController: ReadMoreTableViewController, ReadMoreTableViewControllerDataSource {

    private var titles = [String]()
    private var retryButtonShowCount = 0

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Clear", style: .Plain, target: self, action: "clear")
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Refresh", style: .Plain, target: self, action: "refresh")

        ReadMoreTableViewController.retryText = "Custom Retry Text"
        dataSource = self
        didSelectRow = { [weak self] row in
            if let title = self?.titles[row] {
                print("selected \(title)")
            }
        }
    }

    func clear() {
        titles = []
        refreshData(immediately: true)

        retryButtonShowCount = 0
    }

    func refresh() {
        titles = []
        refreshData(immediately: false)

        retryButtonShowCount = 0
    }

    // MARK: - ReadMoreTableViewControllerDataSource

    func nibNameForReadMoreTableViewController(readMoreTableViewController: ReadMoreTableViewController) -> String {
        return "SampleCell"
    }

    func numberOfDataInReadMoreTableViewController(readMoreTableViewController: ReadMoreTableViewController) -> Int {
        return titles.count
    }

    func readMoreTableViewController(readMoreTableViewController: ReadMoreTableViewController, fetchData completion: (data: [AnyObject], hasNext: Bool) -> ()) {
        let newTitles = Array(1...5).map { "sample\($0 + titles.count)" }

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(1 * Double(NSEC_PER_SEC))), dispatch_get_main_queue()) {

            // リトライボタン表示テスト
            guard self.titles.count < 20 * (self.retryButtonShowCount + 1) else {
                self.showRetryButton()
                self.retryButtonShowCount++
                return
            }

            completion(data: newTitles, hasNext: true)
        }
    }

    func readMoreTableViewController(readMoreTableViewController: ReadMoreTableViewController, addData data: [AnyObject]) {
        titles += data as! [String]
    }

    func readMoreTableViewController(readMoreTableViewController: ReadMoreTableViewController, configureCell cell: UITableViewCell, row: Int) -> UITableViewCell {
        cell.textLabel?.text = titles[row]
        return cell
    }

}
