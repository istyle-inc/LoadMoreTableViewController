import UIKit

public class ReadMoreCell: UITableViewCell {

    @IBOutlet weak var activityIndecator: UIActivityIndicatorView!

    override public func layoutSubviews() {
        super.layoutSubviews()

        activityIndecator.startAnimating()
    }
    
}
