import UIKit

public class FooterCell: UITableViewCell {

    @IBOutlet private weak var activityIndecator: UIActivityIndicatorView!
    @IBOutlet weak var retryButton: UIButton!

    var showsRetryButton = false {
        didSet {
            if showsRetryButton {
                activityIndecator.hidden = true
                retryButton.hidden = false
            } else {
                activityIndecator.hidden = false
                retryButton.hidden = true
            }
        }
    }
    var retryButtonTapped: (() -> ())?

    public override func awakeFromNib() {
        super.awakeFromNib()

        showsRetryButton = false
    }

    override public func layoutSubviews() {
        super.layoutSubviews()

        activityIndecator.startAnimating()
    }

    @IBAction func retryButtonTapped(sender: UIButton) {
        retryButtonTapped?()
    }

}
