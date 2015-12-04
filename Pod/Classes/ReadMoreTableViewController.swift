import UIKit

public class ReadMoreTableViewController: UITableViewController {

    private enum SectionType {
        case Top
        case Main
        case ReadMore
    }

    public static var retryText: String?
    public static var retryImage: UIImage?

    private let sectionTypes: [SectionType] = [.Top, .Main, .ReadMore]
    private let readMoreCellIdentifier = "ReadMoreCell"

    private var cellHeights = [NSIndexPath: CGFloat]()

    private var hidesFooter = false
    private var showsRetryButton = false
    private var isRequesting = false

    public var cellIdentifier = "Cell"
    public var sourceObjects = [AnyObject]()
    public var topCells = [UITableViewCell]() {
        didSet {
            tableView.reloadData()
        }
    }

    public var fetchSourceObjects: (completion: (sourceObjects: [AnyObject], hasNext: Bool) -> ()) -> () = { _ in }
    public var configureCell: (cell: UITableViewCell, row: Int) -> UITableViewCell = { _ in return UITableViewCell() }

    public var didSelectRow: (Int -> ())?

    // MARK: - Lifecycle

    override public func viewDidLoad() {
        super.viewDidLoad()

        tableView.tableFooterView = UIView() // cf. http://stackoverflow.com/questions/1369831/eliminate-extra-separators-below-uitableview-in-iphone-sdk

        tableView.registerNib(UINib(nibName: "ReadMoreCell", bundle: NSBundle(forClass: ReadMoreCell.self)), forCellReuseIdentifier: readMoreCellIdentifier)

        tableView.rowHeight = UITableViewAutomaticDimension
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
        case .Top:
            return topCells.count
        case .Main:
            return sourceObjects.count
        case .ReadMore:
            return (hidesFooter ? 0 : 1)
        }
    }

    public override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let sectionType = sectionTypes[indexPath.section]
        switch sectionType {
        case .Top:
            return topCells[indexPath.row]

        case .Main:
            let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath)
            if indexPath.row < sourceObjects.count {
                return configureCell(cell: cell, row: indexPath.row)
            } else {
                return cell
            }

        case .ReadMore:
            let cell = tableView.dequeueReusableCellWithIdentifier(readMoreCellIdentifier, forIndexPath: indexPath) as! ReadMoreCell
            cell.separatorInset = UIEdgeInsets(top: 0, left: CGFloat.max, bottom: 0, right: 0) // cf. http://stackoverflow.com/questions/8561774/hide-separator-line-on-one-uitableviewcell
            cell.showsRetryButton = showsRetryButton
            cell.retryButtonTapped = { [weak self] in
                self?.readMore()
                self?.showsRetryButton = false
                cell.showsRetryButton = false
            }
            if let retryText = ReadMoreTableViewController.retryText {
                cell.retryButton.setTitle(retryText, forState: .Normal)
            }
            if let retryImage = ReadMoreTableViewController.retryImage {
                cell.retryButton.setImage(retryImage, forState: .Normal)
            }
            return cell
        }
    }

    // MARK: - TableViewDelegate

    public override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        cellHeights[indexPath] = cell.frame.height

        if sectionTypes[indexPath.section] == .ReadMore && !showsRetryButton {
            readMore()
        }
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

    // MARK: - Public

    /// - Parameters:
    ///     - immediately:
    ///         - true: It will show an activity indicator on the top then fetch the data.
    ///         - false: It will refresh the table view after fetching the data.
    public func refreshData(immediately immediately: Bool) {
        sourceObjects.removeAll()
        showsRetryButton = false
        if immediately {
            tableView.reloadData()
            updateFooter(true)
        } else {
            readMore(reload: true)
        }
    }

    public func showRetryButton() {
        isRequesting = false
        showsRetryButton = true
        tableView.reloadData()
    }

    // MARK: - Private

    private func readMore(reload reload: Bool = false) {
        guard !isRequesting else {
            return
        }
        isRequesting = true

        let oldDataCount = sourceObjects.count

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            self.fetchSourceObjects() { [weak self] sourceObjects, hasNext in
                guard let weakSelf = self else {
                    return
                }

                // Prevent data mismatch when cleared existing data while fetching new data
                if oldDataCount == self?.sourceObjects.count {
                    self?.sourceObjects += sourceObjects
                }

                dispatch_async(dispatch_get_main_queue()) {
                    UIView.setAnimationsEnabled(false)
                    if let mainSection = weakSelf.sectionTypes.indexOf(.Main) {
                        let newDataCount = weakSelf.sourceObjects.count
                        let currentDataCount = weakSelf.tableView.numberOfRowsInSection(mainSection)
                        if currentDataCount < newDataCount {
                            self?.tableView.insertRowsAtIndexPaths(
                                Array(currentDataCount..<newDataCount).map { NSIndexPath(forRow: $0, inSection: mainSection) },
                                withRowAnimation: .None)
                        } else {
                            self?.tableView.deleteRowsAtIndexPaths(
                                Array(newDataCount..<currentDataCount).map { NSIndexPath(forRow: $0, inSection: mainSection) },
                                withRowAnimation: .None)
                        }

                        if reload {
                            self?.tableView.reloadRowsAtIndexPaths(
                                Array(0..<newDataCount).map { NSIndexPath(forRow: $0, inSection: mainSection) },
                                withRowAnimation: .None)
                        }
                    }
                    UIView.setAnimationsEnabled(true)

                    if !hasNext {
                        self?.updateFooter(false)
                    } else {
                        // To call willDisplayCell delegate to read cells
                        self?.updateFooter(true)
                    }
                }

                self?.isRequesting = false
            }
        }
    }

    private func updateFooter(show: Bool) {
        guard let readMoreSection = sectionTypes.indexOf(.ReadMore) else {
            return
        }

        if show && hidesFooter {
            UIView.setAnimationsEnabled(false)
            hidesFooter = false
            tableView.insertRowsAtIndexPaths([NSIndexPath(forRow: 0, inSection: readMoreSection)], withRowAnimation: .Fade)
            UIView.setAnimationsEnabled(true)

        } else if !show && !hidesFooter {
            hidesFooter = true
            tableView.deleteRowsAtIndexPaths([NSIndexPath(forRow: 0, inSection: readMoreSection)], withRowAnimation: .Fade)

        } else if show && !hidesFooter {
            UIView.setAnimationsEnabled(false)
            tableView.reloadRowsAtIndexPaths([NSIndexPath(forRow: 0, inSection: readMoreSection)], withRowAnimation: .Fade)
            UIView.setAnimationsEnabled(true)
        }
    }

}
