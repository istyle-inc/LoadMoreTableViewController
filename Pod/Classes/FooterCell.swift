import UIKit

public class FooterCell: UITableViewCell {

    @IBOutlet private weak var activityIndecator: UIActivityIndicatorView!
    @IBOutlet weak var retryButton: UIButton!

    var showsRetryButton = false {
        didSet {
            if showsRetryButton {
                activityIndecator.isHidden = true
                retryButton.isHidden = false
            } else {
                activityIndecator.isHidden = false
                retryButton.isHidden = true
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

    @IBAction func retryButtonTapped(_ sender: UIButton) {
        retryButtonTapped?()
    }

}
