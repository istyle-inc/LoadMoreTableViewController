import Foundation

public protocol ReadMoreTableViewControllerDataSource: class {

    func readMoreTableViewController(readMoreTableViewController: ReadMoreTableViewController, fetchData completion: (data: [AnyObject], hasNext: Bool) -> ())
    func readMoreTableViewController(readMoreTableViewController: ReadMoreTableViewController, configureCell cell: UITableViewCell, row: Int) -> UITableViewCell

}
