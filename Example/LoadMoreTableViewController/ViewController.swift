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

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Clear", style: .plain, target: self, action: #selector(clear))
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Refresh", style: .plain, target: self, action: #selector(refresh))

        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(refresh), for: .valueChanged)

        tableView.register(UINib(nibName: "SampleCell", bundle: nil), forCellReuseIdentifier: cellReuseIdentifier)

        LoadMoreTableViewController.retryText = "Custom Retry Text"
        fetchSourceObjects = { [weak self] completion in
            let newNumbers = Array(1...5).map { $0 + (self?.sourceObjects.count ?? 0) }

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
                    completion(newNumbers.map { "sample \($0)" }, true)
                }
            }
        }
        configureCell = { [weak self] cell, row in
            cell.textLabel?.text = self?.sourceObjects[row] as? String
            cell.detailTextLabel?.text = NSDate().description
            return cell
        }
        didSelectRow = { [weak self] row in
            if let title = self?.sourceObjects[row] as? String {
                print("did select \(title)")
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
