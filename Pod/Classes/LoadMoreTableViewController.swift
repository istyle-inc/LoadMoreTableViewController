import UIKit

public class LoadMoreTableViewController: UITableViewController {

    private enum SectionType {
        case Main
        case Footer
    }

    public static var retryText: String?
    public static var retryImage: UIImage?

    private let sectionTypes: [SectionType] = [.Main, .Footer]
    private let footerCellReuseIdentifier = "FooterCell"

    private var cellHeights = [NSIndexPath: CGFloat]()

    private var hidesFooter = false
    private var showsRetryButton = false
    private var isRequesting = false

    private var isScrolling = false {
        didSet {
            if !isScrolling && pendingProcess != nil {
                pendingProcess?()
                pendingProcess = nil
            }
        }
    }
    private var pendingProcess: (() -> ())?

    public var cellReuseIdentifier = "Cell"
    public var sourceObjects = [AnyObject]()

    public var fetchSourceObjects: (completion: (sourceObjects: [AnyObject], hasNext: Bool) -> ()) -> () = { _ in }
    public var configureCell: (cell: UITableViewCell, row: Int) -> UITableViewCell = { _ in return UITableViewCell() }

    public var didSelectRow: (Int -> ())?

    // MARK: - Lifecycle

    override public func viewDidLoad() {
        super.viewDidLoad()

        tableView.tableFooterView = UIView() // cf. http://stackoverflow.com/questions/1369831/eliminate-extra-separators-below-uitableview-in-iphone-sdk

        tableView.registerNib(UINib(nibName: "FooterCell", bundle: NSBundle(forClass: FooterCell.self)), forCellReuseIdentifier: footerCellReuseIdentifier)
    }

    public override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        if let indexPath = tableView.indexPathForSelectedRow {
            tableView.deselectRowAtIndexPath(indexPath, animated: animated)
        }
    }

    // MARK: - TableViewDataSource

    public override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return sectionTypes.count
    }

    public override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionType = sectionTypes[section]
        switch sectionType {
        case .Main:
            return sourceObjects.count
        case .Footer:
            return (hidesFooter ? 0 : 1)
        }
    }

    public override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let sectionType = sectionTypes[indexPath.section]
        switch sectionType {
        case .Main:
            let cell = tableView.dequeueReusableCellWithIdentifier(cellReuseIdentifier, forIndexPath: indexPath)
            if indexPath.row < sourceObjects.count {
                return configureCell(cell: cell, row: indexPath.row)
            } else {
                return cell
            }

        case .Footer:
            let cell = tableView.dequeueReusableCellWithIdentifier(footerCellReuseIdentifier, forIndexPath: indexPath) as! FooterCell
            cell.separatorInset = UIEdgeInsets(top: 0, left: CGFloat.max, bottom: 0, right: 0) // cf. http://stackoverflow.com/questions/8561774/hide-separator-line-on-one-uitableviewcell
            cell.showsRetryButton = showsRetryButton
            cell.retryButtonTapped = { [weak self] in
                self?.loadMore()
                self?.showsRetryButton = false
                cell.showsRetryButton = false
            }
            if let retryText = LoadMoreTableViewController.retryText {
                cell.retryButton.setTitle(retryText, forState: .Normal)
            }
            if let retryImage = LoadMoreTableViewController.retryImage {
                cell.retryButton.setImage(retryImage, forState: .Normal)
            }
            return cell
        }
    }

    // MARK: - TableViewDelegate

    public override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        cellHeights[indexPath] = cell.frame.height

        if sectionTypes[indexPath.section] == .Footer && !showsRetryButton {
            loadMore()
        }
    }

    // cf. http://stackoverflow.com/questions/26917728/ios-uitableviewautomaticdimension-rowheight-poor-performance-jumping
    public override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }

    public override func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if let cachedHeight = cellHeights[indexPath] {
            return cachedHeight
        } else {
            return 50
        }
    }

    public override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        didSelectRow?(indexPath.row)
    }

    // MARK: - ScrollViewDelegate

    public override func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        isScrolling = true
    }

    public override func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            isScrolling = false
        }
    }

    public override func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        isScrolling = false
    }

    // MARK: - Public

    /// - Parameters:
    ///     - immediately:
    ///         - true: It will show an activity indicator on the top then fetch the data.
    ///         - false: It will refresh the table view after fetching the data.
    public func refreshData(immediately immediately: Bool) {
        sourceObjects.removeAll()
        showsRetryButton = false

        dispatch_async(dispatch_get_main_queue()) {
            if immediately {
                self.tableView.reloadData()
                self.updateFooter(true)
            } else {
                self.loadMore(reload: true)
            }
        }
    }

    public func showRetryButton() {
        isRequesting = false
        showsRetryButton = true
        updateFooter(true)
    }

    // MARK: - Private

    private func loadMore(reload reload: Bool = false) {
        guard !isRequesting else {
            return
        }
        isRequesting = true

        let oldDataCount = sourceObjects.count

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            self.fetchSourceObjects() { [weak self] sourceObjects, hasNext in

                // Prevent data mismatch when cleared existing data while fetching new data
                if oldDataCount == self?.sourceObjects.count {
                    self?.sourceObjects += sourceObjects
                }

                if self?.isScrolling == true {
                    if self?.pendingProcess == nil {
                        self?.pendingProcess = {
                            self?.updateTable(reload: reload, hasNext: hasNext)
                        }
                    }
                } else {
                    self?.updateTable(reload: reload, hasNext: hasNext)
                }

                self?.isRequesting = false
            }
        }
    }

    private func updateTable(reload reload: Bool, hasNext: Bool) {
        dispatch_async(dispatch_get_main_queue()) {
            UIView.setAnimationsEnabled(false)
            if let mainSection = self.sectionTypes.indexOf(.Main) {
                let newDataCount = self.sourceObjects.count
                let currentDataCount = self.tableView.numberOfRowsInSection(mainSection)
                if currentDataCount < newDataCount {
                    self.tableView.insertRowsAtIndexPaths(
                        Array(currentDataCount..<newDataCount).map { NSIndexPath(forRow: $0, inSection: mainSection) },
                        withRowAnimation: .None)
                } else {
                    self.tableView.deleteRowsAtIndexPaths(
                        Array(newDataCount..<currentDataCount).map { NSIndexPath(forRow: $0, inSection: mainSection) },
                        withRowAnimation: .None)
                }

                if reload {
                    self.tableView.reloadRowsAtIndexPaths(
                        Array(0..<newDataCount).map { NSIndexPath(forRow: $0, inSection: mainSection) },
                        withRowAnimation: .None)
                }
            }
            UIView.setAnimationsEnabled(true)

            if !hasNext {
                self.updateFooter(false)
            } else {
                // To call willDisplayCell delegate to read cells
                self.updateFooter(true)
            }
        }
    }

    private func updateFooter(show: Bool) {
        guard pendingProcess == nil else {
            return
        }

        guard let footerSection = sectionTypes.indexOf(.Footer) else {
            return
        }

        dispatch_async(dispatch_get_main_queue()) {
            if show && self.hidesFooter {
                self.hidesFooter = false
                self.tableView.insertRowsAtIndexPaths([NSIndexPath(forRow: 0, inSection: footerSection)], withRowAnimation: .None)

            } else if !show && !self.hidesFooter {
                self.hidesFooter = true
                self.tableView.deleteRowsAtIndexPaths([NSIndexPath(forRow: 0, inSection: footerSection)], withRowAnimation: .None)

            } else if show && !self.hidesFooter {
                self.tableView.reloadData()
            }
        }
    }

}
