import UIKit

public class ReadMoreTableViewController: UITableViewController {

    private let mainCellIdentifier = "MainCell"
    private let readMoreCellIdentifier = "ReadMoreCell"
    private let readMoreCellSection = 1

    private var cellHeights = [NSIndexPath: CGFloat]()

    private var hidesFooter = false
    private var showsRetryButton = false

    public var mainCellCount = 0
    private var allCellCount: Int {
        return topCells.count + mainCellCount
    }

    public var configureCellClosure: (cell: UITableViewCell, row: Int) -> UITableViewCell = { cell, row in return cell }
    public var fetchReadCountClosure: (currentCount: Int, completion: (readCount: Int, hasNext: Bool) -> ()) -> () = { currentCount, completion in completion(readCount: 0, hasNext: false) }
    public var topCells = [UITableViewCell]() {
        didSet {
            tableView.reloadData()
        }
    }

    // MARK: - Lifecycle

    override public func viewDidLoad() {
        super.viewDidLoad()

        tableView.tableFooterView = UIView() // cf. http://stackoverflow.com/questions/1369831/eliminate-extra-separators-below-uitableview-in-iphone-sdk
        tableView.registerNib(UINib(nibName: "ReadMoreCell", bundle: NSBundle(forClass: ReadMoreCell.self)), forCellReuseIdentifier: readMoreCellIdentifier)

        tableView.rowHeight = UITableViewAutomaticDimension
    }

    // MARK: - TableViewDataSource

    public override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }

    public override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == readMoreCellSection {
            return (hidesFooter ? 0 : 1)
        } else {
            return allCellCount
        }
    }

    public override func tableView(tableView: UITableView, estimatedHeightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if let cachedHeight = cellHeights[indexPath] {
            return cachedHeight
        } else {
            return 50
        }
    }

    public override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if isFooter(indexPath) {
            let cell = tableView.dequeueReusableCellWithIdentifier(readMoreCellIdentifier, forIndexPath: indexPath) as! ReadMoreCell
            cell.separatorInset = UIEdgeInsets(top: 0, left: CGFloat.max, bottom: 0, right: 0) // cf. http://stackoverflow.com/questions/8561774/hide-separator-line-on-one-uitableviewcell
            cell.showsRetryButton = showsRetryButton
            cell.retryButtonTapped = { [weak self] in
                self?.readMore()
                self?.showsRetryButton = false
                cell.showsRetryButton = false
            }
            return cell
        } else if isTopCell(indexPath) {
            return topCells[indexPath.row]
        } else {
            let cell = tableView.dequeueReusableCellWithIdentifier(mainCellIdentifier, forIndexPath: indexPath)
            return configureCellClosure(cell: cell, row: indexPath.row - topCells.count)
        }
    }

    // MARK: - TableViewDelegate

    public override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        cellHeights[indexPath] = cell.frame.height

        if isFooter(indexPath) && !showsRetryButton {
            readMore()
        }
    }

    // MARK: - Public

    public func registerNib(nibName: String) {
        tableView.registerNib(UINib(nibName: nibName, bundle: nil), forCellReuseIdentifier: mainCellIdentifier)
    }

    public func clearData() {
        mainCellCount = 0
        showsRetryButton = false
        tableView.reloadData()
        updateFooter(true)
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(0.01 * Double(NSEC_PER_SEC))), dispatch_get_main_queue()) {
            if self.tableView(self.tableView, numberOfRowsInSection: self.readMoreCellSection) > 0  { // Prevent error "row (0) beyond bounds (0) for section (0)."
                self.tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: 0, inSection: self.readMoreCellSection), atScrollPosition: .Top, animated: false)
            }
        }
    }

    public func showRetryButton() {
        showsRetryButton = true
        tableView.reloadSections(NSIndexSet(index: readMoreCellSection), withRowAnimation: .None)
    }

    // MARK: - Private

    private func readMore() {
        let currentCount = mainCellCount
        let currentAllCellCount = allCellCount

        self.fetchReadCountClosure(currentCount: currentCount, completion: { [weak self] readCount, hasNext in
            self?.mainCellCount = currentCount + readCount
            UIView.setAnimationsEnabled(false)
            self?.tableView.insertRowsAtIndexPaths(
                Array(currentAllCellCount..<currentAllCellCount + readCount).map{ NSIndexPath(forRow: $0, inSection: 0) },
                withRowAnimation: .None)
            UIView.setAnimationsEnabled(true)

            if !hasNext {
                self?.updateFooter(false)
            } else {
                // To call willDisplayCell delegate to read cells
                self?.updateFooter(true)
            }
        })
    }

    private func isTopCell(indexPath: NSIndexPath) -> Bool {
        return indexPath.row < topCells.count
    }

    private func isFooter(indexPath: NSIndexPath) -> Bool {
        return indexPath.section == readMoreCellSection
    }

    private func updateFooter(show: Bool) {
        if show && hidesFooter {
            UIView.setAnimationsEnabled(false)
            hidesFooter = false
            tableView.insertRowsAtIndexPaths([NSIndexPath(forRow: 0, inSection: readMoreCellSection)], withRowAnimation: .Fade)
            UIView.setAnimationsEnabled(true)

        } else if !show && !hidesFooter {
            hidesFooter = true
            tableView.deleteRowsAtIndexPaths([NSIndexPath(forRow: 0, inSection: readMoreCellSection)], withRowAnimation: .Fade)

        } else if show && !hidesFooter {
            UIView.setAnimationsEnabled(false)
            tableView.reloadRowsAtIndexPaths([NSIndexPath(forRow: 0, inSection: readMoreCellSection)], withRowAnimation: .Fade)
            UIView.setAnimationsEnabled(true)
        }
    }

}
