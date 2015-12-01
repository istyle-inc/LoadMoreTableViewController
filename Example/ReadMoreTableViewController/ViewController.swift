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

    private var titles = [String]()
    private var retryButtonShowCount = 0

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Clear", style: .Plain, target: self, action: "clear")

        configureCellClosure = { [weak self] cell, row in
            cell.textLabel?.text = self?.titles[row]
            return cell
        }
        fetchDataClosure = { [weak self] completion in
            let newTitles = Array(1...5).map{ "sample\($0 + (self?.titles.count ?? 0))" }

            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(1 * Double(NSEC_PER_SEC))), dispatch_get_main_queue()) {

                // リトライボタン表示テスト
                if let retryButtonShowCount = self?.retryButtonShowCount {
                    guard self?.titles.count < 20 * (retryButtonShowCount + 1) else {
                        self?.showRetryButton()
                        self?.retryButtonShowCount++
                        return
                    }
                }

                completion(data: newTitles, hasNext: true)
            }
        }
        addDataClosure = { [weak self] data in
            self?.titles += data as! [String]
        }
        dataCountClosure = { [weak self] in
            return self?.titles.count ?? 0
        }
        registerNib("SampleCell")

        didSelectRow = { [weak self] row in
            if let title = self?.titles[row] {
                print("selected \(title)")
            }
        }

        ReadMoreTableViewController.retryText = "Custom Retry Text"
    }

    func clear() {
        clearData()
        titles = []
        retryButtonShowCount = 0
        tableView.reloadData()
    }

}
