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
    private let mainCellIdentifier = "MainCell"
    private let readMoreCellIdentifier = "ReadMoreCell"

    private var cellHeights = [NSIndexPath: CGFloat]()

    private var hidesFooter = false
    private var showsRetryButton = false
    private var isRequesting = false

    public weak var dataSource: ReadMoreTableViewControllerDataSource?
    public var topCells = [UITableViewCell]() {
        didSet {
            tableView.reloadData()
        }
    }
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
            return dataSource?.numberOfDataInReadMoreTableViewController(self) ?? 0
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
            let cell: UITableViewCell
            if let reusableCell = tableView.dequeueReusableCellWithIdentifier(mainCellIdentifier) {
                cell = reusableCell
            } else {
                if let nibName = dataSource?.nibNameForReadMoreTableViewController(self) {
                    tableView.registerNib(UINib(nibName: nibName, bundle: nil), forCellReuseIdentifier: mainCellIdentifier)
                }
                cell = tableView.dequeueReusableCellWithIdentifier(mainCellIdentifier, forIndexPath: indexPath)
            }
            return  dataSource?.readMoreTableViewController(self, configureCell: cell, row: indexPath.row) ?? cell
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

    /**
     It will show an activity indicator on the top then fetch the data.
     */
    public func clearData() {
        showsRetryButton = false
        tableView.reloadData()
        updateFooter(true)
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(0.01 * Double(NSEC_PER_SEC))), dispatch_get_main_queue()) {
            if let readMoreSection = self.sectionTypes.indexOf(.ReadMore) {
                if self.tableView(self.tableView, numberOfRowsInSection: readMoreSection) > 0  { // Prevent error "row (0) beyond bounds (0) for section (0)."
                    self.tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: 0, inSection: readMoreSection), atScrollPosition: .Top, animated: false)
                }
            }
        }
    }

    /**
     It will refresh the table view after fetching the data.
     */
    public func refresh() {
        showsRetryButton = false
        readMore(reload: true)
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

        let oldDataCount = dataSource?.numberOfDataInReadMoreTableViewController(self)

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            self.dataSource?.readMoreTableViewController(self) { [weak self] data, hasNext in
                guard let weakSelf = self else {
                    return
                }

                // Prevent data mismatch when cleared existing data while fetching new data
                if oldDataCount == self?.dataSource?.numberOfDataInReadMoreTableViewController(weakSelf) {
                    self?.dataSource?.readMoreTableViewController(weakSelf, addData: data)
                }

                dispatch_async(dispatch_get_main_queue()) {
                    UIView.setAnimationsEnabled(false)
                    if reload {
                        self?.tableView.reloadData()
                    } else if let mainSection = weakSelf.sectionTypes.indexOf(.Main) {
                        let newDataCount = weakSelf.dataSource?.numberOfDataInReadMoreTableViewController(weakSelf) ?? 0
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
