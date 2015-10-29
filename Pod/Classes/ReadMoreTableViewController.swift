import UIKit

public class ReadMoreTableViewController: UITableViewController {

    private let mainCellIdentifier = "MainCell"
    private let readMoreCellIdentifier = "ReadMoreCell"

    private var hidesFooter = false
    private var mainCellCount = 0
    private var allCellCount: Int {
        return topCells.count + mainCellCount + (hidesFooter ? 0 : 1)
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
        tableView.estimatedRowHeight = 50
    }

    // MARK: - TableViewDataSource

    override public func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return allCellCount
    }

    override public func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if isTopCell(indexPath) {
            return topCells[indexPath.row]
        } else if isFooter(indexPath) {
            let cell = tableView.dequeueReusableCellWithIdentifier(readMoreCellIdentifier, forIndexPath: indexPath)
            cell.separatorInset = UIEdgeInsets(top: 0, left: CGFloat.max, bottom: 0, right: 0) // cf. http://stackoverflow.com/questions/8561774/hide-separator-line-on-one-uitableviewcell
            return cell
        } else {
            let cell = tableView.dequeueReusableCellWithIdentifier(mainCellIdentifier, forIndexPath: indexPath)
            return configureCellClosure(cell: cell, row: indexPath.row - topCells.count)
        }
    }

    // MARK: - TableViewDelegate

    override public func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        if isFooter(indexPath) {
            let currentCount = mainCellCount
            fetchReadCountClosure(currentCount: currentCount, completion: { [weak self] readCount, hasNext in
                if !hasNext {
                    self?.hidesFooter = true
                }
                self?.mainCellCount = currentCount + readCount
                self?.tableView.reloadData()
            })
        }
    }

    // MARK: - Public

    public func registerNib(nibName: String) {
        tableView.registerNib(UINib(nibName: nibName, bundle: nil), forCellReuseIdentifier: mainCellIdentifier)
    }

    public func clearData() {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(0.01 * Double(NSEC_PER_SEC))), dispatch_get_main_queue()) {
            self.tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 0), atScrollPosition: .Top, animated: false)
        }
        mainCellCount = 0
        hidesFooter = false
    }

    // MARK: - Private

    private func isTopCell(indexPath: NSIndexPath) -> Bool {
        return indexPath.row < topCells.count
    }

    private func isFooter(indexPath: NSIndexPath) -> Bool {
        return indexPath.row == topCells.count + mainCellCount
    }

}
