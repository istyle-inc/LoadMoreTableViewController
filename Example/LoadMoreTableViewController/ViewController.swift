//
//  ViewController.swift
//  LoadMoreTableViewController
//
//  Created by mishimay on 10/22/2015.
//  Copyright (c) 2015 istyle Inc. All rights reserved.
//

import UIKit
import LoadMoreTableViewController

func delay(_ delay: TimeInterval, block: @escaping () -> ()) {
    DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
        block()
    }
}

class ViewController: LoadMoreTableViewController {

    private var count = 0

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Clear", style: .plain, target: self, action: #selector(clear))
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Refresh", style: .plain, target: self, action: #selector(refresh))

        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(refresh), for: .valueChanged)

        tableView.register(UINib(nibName: "SampleCell", bundle: nil), forCellReuseIdentifier: cellReuseIdentifier)
        tableView.register(UINib(nibName: "AdCell", bundle: nil), forCellReuseIdentifier: "Ad")

        LoadMoreTableViewController.retryText = "Custom Retry Text"
        fetchCellReuseIdentifier = { [weak self] row in
            return self?.sourceObjects[row] is NSNull ? "Ad" : nil
        }
        fetchSourceObjects = { [weak self] completion in
            var newNumbers = [Int]()
            for _ in 0..<5 {
                self?.count += 1
                newNumbers.append(self?.count ?? 0)
            }

            delay(1) { // Pretend to fetch data

                // Test retry button
                let showRetryButton = newNumbers.filter { $0 % 20 == 0 }.count > 0
                if showRetryButton {
                    delay(0.1) {
                        self?.showRetryButton()
                    }
                }

                let refreshing = self?.refreshControl?.isRefreshing == true
                if refreshing {
                    self?.refreshControl?.endRefreshing()
                }

                delay(refreshing ? 0.3 : 0) {
                    completion(newNumbers.map { "sample \($0)" } + [NSNull()], true)
                }
            }
        }
        configureCell = { [weak self] cell, row in
            if cell.reuseIdentifier == self?.cellReuseIdentifier {
                cell.textLabel?.text = self?.sourceObjects[row] as? String
                cell.detailTextLabel?.text = NSDate().description
            }
            return cell
        }
        didSelectRow = { [weak self] row in
            if let title = self?.sourceObjects[row] as? String {
                print("did select \(title)")
            }
        }
    }

    @objc func clear() {
        count = 0
        refreshData(immediately: true)
    }

    @objc func refresh() {
        count = 0
        refreshData(immediately: false)
    }

}
