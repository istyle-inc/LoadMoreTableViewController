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

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Clear", style: .Plain, target: self, action: "clear")

        configureCellClosure = { [weak self] cell, row in
            cell.textLabel?.text = self?.titles[row]
            return cell
        }
        fetchReadCountClosure = { [weak self] currentCount, completion in
            let newTitles = ["sample", "sample", "sample", "sample", "sample"]
            self?.titles += newTitles
            completion(readCount: newTitles.count, hasNext: true)
        }
        registerNib("SampleCell")
    }

    func clear() {
        clearData()
        titles = []
        tableView.reloadData()
        tableView.contentOffset = CGPoint(x: 0, y: 0)
    }

}
