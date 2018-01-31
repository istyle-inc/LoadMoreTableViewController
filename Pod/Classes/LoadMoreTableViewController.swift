import UIKit

open class LoadMoreTableViewController: UITableViewController {

    private enum SectionType {
        case main
        case footer
    }

    public static var retryText: String?
    public static var retryImage: UIImage?

    private let sectionTypes: [SectionType] = [.main, .footer]
    private let footerCellReuseIdentifier = "FooterCell"

    private var cellHeights = [IndexPath: CGFloat]()

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

    open var cellReuseIdentifier = "Cell"
    open var sourceObjects = [Any]()

    public var fetchCellReuseIdentifier: (_ row: Int) -> String? = { _ in return nil }
    public var fetchSourceObjects: (_ completion: @escaping (_ sourceObjects: [Any], _ hasNext: Bool) -> ()) -> () = { _ in }
    public var configureCell: (_ cell: UITableViewCell, _ row: Int) -> UITableViewCell = { (_, _) in return UITableViewCell() }

    public var didSelectRow: ((Int) -> ())?

    // MARK: - Lifecycle

    open override func viewDidLoad() {
        super.viewDidLoad()

        tableView.tableFooterView = UIView() // cf. http://stackoverflow.com/questions/1369831/eliminate-extra-separators-below-uitableview-in-iphone-sdk

        tableView.register(UINib(nibName: "FooterCell", bundle: Bundle(for: FooterCell.self)), forCellReuseIdentifier: footerCellReuseIdentifier)
    }

    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if let indexPath = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: indexPath, animated: animated)
        }
    }

    // MARK: - TableViewDataSource

    open override func numberOfSections(in tableView: UITableView) -> Int {
        return sectionTypes.count
    }

    open override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionType = sectionTypes[section]
        switch sectionType {
        case .main:
            return sourceObjects.count
        case .footer:
            return (hidesFooter ? 0 : 1)
        }
    }

    open override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let sectionType = sectionTypes[indexPath.section]
        switch sectionType {
        case .main:
            let identifier = fetchCellReuseIdentifier(indexPath.row) ?? cellReuseIdentifier
            let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath)
            if indexPath.row < sourceObjects.count {
                return configureCell(cell, indexPath.row)
            } else {
                return cell
            }

        case .footer:
            let cell = tableView.dequeueReusableCell(withIdentifier: footerCellReuseIdentifier, for: indexPath) as! FooterCell
            cell.backgroundColor = .clear
            cell.separatorInset = UIEdgeInsets(top: 0, left: CGFloat.greatestFiniteMagnitude, bottom: 0, right: 0) // cf. http://stackoverflow.com/questions/8561774/hide-separator-line-on-one-uitableviewcell
            cell.showsRetryButton = showsRetryButton
            cell.retryButtonTapped = { [weak self] in
                self?.loadMore()
                self?.showsRetryButton = false
                cell.showsRetryButton = false
            }
            if let retryText = LoadMoreTableViewController.retryText {
                cell.retryButton.setTitle(retryText, for: .normal)
            }
            if let retryImage = LoadMoreTableViewController.retryImage {
                cell.retryButton.setImage(retryImage, for: .normal)
            }
            return cell
        }
    }

    // MARK: - TableViewDelegate

    open override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cellHeights[indexPath] = cell.frame.height

        if sectionTypes[indexPath.section] == .footer && !showsRetryButton {
            loadMore()
        }
    }

    // cf. http://stackoverflow.com/questions/26917728/ios-uitableviewautomaticdimension-rowheight-poor-performance-jumping
    open override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }

    open override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {

        // cf. http://stackoverflow.com/questions/19355182/sdnestedtable-expand-does-not-work-on-ios-7
        if let cachedHeight = cellHeights[IndexPath(row: indexPath.row, section: indexPath.section)] {
            return cachedHeight
        } else {
            return 50
        }
    }

    open override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        didSelectRow?(indexPath.row)
    }

    // MARK: - ScrollViewDelegate

    open override func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        isScrolling = true
    }

    open override func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            isScrolling = false
        }
    }

    open override func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        isScrolling = false
    }

    // MARK: - Public

    /// - Parameters:
    ///     - immediately:
    ///         - true: It will show an activity indicator on the top then fetch the data.
    ///         - false: It will refresh the table view after fetching the data.
    open func refreshData(immediately: Bool) {
        sourceObjects.removeAll()
        showsRetryButton = false

        // To refresh the table view when it is scrolling
        if immediately {
            isScrolling = false
        }

        DispatchQueue.main.async {
            if immediately {
                self.tableView.reloadData()
                self.updateFooter(show: true)
            } else {
                self.loadMore(reload: true)
            }
        }
    }

    public func showRetryButton() {
        isRequesting = false
        showsRetryButton = true
        updateFooter(show: true)
    }

    // MARK: - Private

    private func loadMore(reload: Bool = false) {
        guard !isRequesting else {
            return
        }
        isRequesting = true

        let oldDataCount = sourceObjects.count

        DispatchQueue.global().async {
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

    private func updateTable(reload: Bool, hasNext: Bool) {
        DispatchQueue.main.async {
            UIView.setAnimationsEnabled(false)
            if let mainSection = self.sectionTypes.index(of: .main) {
                let newDataCount = self.sourceObjects.count
                let currentDataCount = self.tableView.numberOfRows(inSection: mainSection)
                if currentDataCount < newDataCount {
                    self.tableView.insertRows(
                        at: Array(currentDataCount..<newDataCount).map { IndexPath(row: $0, section: mainSection) },
                        with: .none)
                } else {
                    self.tableView.deleteRows(
                        at: Array(newDataCount..<currentDataCount).map { IndexPath(row: $0, section: mainSection) },
                        with: .none)
                }

                if reload {
                    self.tableView.reloadRows(
                        at: Array(0..<newDataCount).map { IndexPath(row: $0, section: mainSection) },
                        with: .none)
                }
            }
            UIView.setAnimationsEnabled(true)

            if !hasNext {
                self.updateFooter(show: false)
            } else {
                // To call willDisplayCell delegate to read cells
                self.updateFooter(show: true)
            }
        }
    }

    private func updateFooter(show: Bool) {
        guard pendingProcess == nil else {
            return
        }

        guard let footerSection = sectionTypes.index(of: .footer) else {
            return
        }

        DispatchQueue.main.async {
            if show && self.hidesFooter {
                self.hidesFooter = false
                self.tableView.insertRows(at: [IndexPath(row: 0, section: footerSection)], with: .none)

            } else if !show && !self.hidesFooter {
                self.hidesFooter = true
                self.tableView.deleteRows(at: [IndexPath(row: 0, section: footerSection)], with: .none)

            } else if show && !self.hidesFooter {
                self.tableView.reloadData()
            }
        }
    }

}
