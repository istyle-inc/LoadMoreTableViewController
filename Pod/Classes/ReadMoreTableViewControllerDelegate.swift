import Foundation

public protocol ReadMoreTableViewControllerDataSource: class {

    func nibNameForReadMoreTableViewController(readMoreTableViewController: ReadMoreTableViewController) -> String
    func numberOfDataInReadMoreTableViewController(readMoreTableViewController: ReadMoreTableViewController) -> Int
    func readMoreTableViewController(readMoreTableViewController: ReadMoreTableViewController, fetchData completion: (data: [AnyObject], hasNext: Bool) -> ())
    func readMoreTableViewController(readMoreTableViewController: ReadMoreTableViewController, addData data: [AnyObject])
    func readMoreTableViewController(readMoreTableViewController: ReadMoreTableViewController, configureCell cell: UITableViewCell, row: Int) -> UITableViewCell

}
