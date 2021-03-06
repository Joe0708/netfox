import Foundation
import UIKit
import MessageUI

fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l < r
    case (nil, _?):
        return true
    default:
        return false
    }
}

fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l > r
    default:
        return rhs < lhs
    }
}

enum NetFoxBodyType: Int{
    case request  = 0
    case response = 1
}

class RequestDetailViewController: NetfoxDetailsController, MFMailComposeViewControllerDelegate {
    
    var infoButton: UIButton = UIButton()
    var requestButton: UIButton = UIButton()
    var responseButton: UIButton = UIButton()
    
    private var copyAlert: UIAlertController?
    
    var infoView: UIScrollView = UIScrollView()
    var requestView: UIScrollView = UIScrollView()
    var responseView: UIScrollView = UIScrollView()
    
    var selectedModel: NFXHTTPModel = NFXHTTPModel()
    
    var bodyType: NetFoxBodyType = .response {
        didSet {
            bodyButtonPressed()
        }
    }
    
    private lazy var headerButtons: [UIButton] = {
        return [self.infoButton, self.requestButton, self.responseButton]
    }()
    
    private lazy var infoViews: [UIScrollView] = {
        return [self.infoView, self.requestView, self.responseView]
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Details"
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(actionButtonPressed(_:)))
        
        // Header buttons
        infoButton = createHeaderButton("Info", x: 0, selector: #selector(headerButtonPressed(_:)))
        requestButton = createHeaderButton("Request", x: self.infoButton.frame.maxX, selector: #selector(headerButtonPressed(_:)))
        responseButton = createHeaderButton("Response", x: self.requestButton.frame.maxX, selector: #selector(headerButtonPressed(_:)))
        
        // Info views
        infoView = createDetailsView(getInfoStringFromObject(self.selectedModel), forView: .info)
        requestView = createDetailsView(getRequestStringFromObject(self.selectedModel), forView: .request)
        responseView = createDetailsView(getResponseStringFromObject(self.selectedModel), forView: .response)
        
        // Swipe gestures
        let lswgr = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        lswgr.direction = UISwipeGestureRecognizerDirection.left
        self.view.addGestureRecognizer(lswgr)
        
        let rswgr = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        rswgr.direction = UISwipeGestureRecognizerDirection.right
        self.view.addGestureRecognizer(rswgr)
        
        headerButtonPressed(infoButton)
    }
    
    func createHeaderButton(_ title: String, x: CGFloat, selector: Selector) -> UIButton {
        let tempButton = UIButton()
        tempButton.frame = CGRect(x: x, y: 0, width: self.view.frame.width / 3, height: 44)
        tempButton.autoresizingMask = [.flexibleLeftMargin, .flexibleRightMargin, .flexibleWidth]
        tempButton.backgroundColor = UIColor(netHex: 0x9b958d)
        tempButton.setTitle(title, for: UIControlState())
        tempButton.setTitleColor(UIColor(netHex: 0x6d6d6d), for: UIControlState())
        tempButton.setTitleColor(UIColor(netHex: 0xf3f3f4), for: .selected)
        tempButton.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        tempButton.addTarget(self, action: selector, for: .touchUpInside)
        view.addSubview(tempButton)
        return tempButton
    }
    
    @objc fileprivate func copyLabel(lpgr: UILongPressGestureRecognizer) {
        guard let text = (lpgr.view as? UILabel)?.text,
            copyAlert == nil else { return }
        
        UIPasteboard.general.string = text
        
        let alert = UIAlertController(title: "Text Copied!", message: nil, preferredStyle: .alert)
        copyAlert = alert
        
        self.present(alert, animated: true) { [weak self] in
            guard let `self` = self else { return }
            
            Timer.scheduledTimer(timeInterval: 0.45,
                                 target: self,
                                 selector: #selector(RequestDetailViewController.dismissCopyAlert),
                                 userInfo: nil,
                                 repeats: false)
        }
    }
    
    @objc fileprivate func dismissCopyAlert() {
        copyAlert?.dismiss(animated: true) { [weak self] in self?.copyAlert = nil }
    }
    
    func createDetailsView(_ content: NSAttributedString, forView: EDetailsView) -> UIScrollView {
        var scrollView: UIScrollView
        scrollView = UIScrollView()
        scrollView.frame = CGRect(x: 0, y: 44, width: self.view.frame.width, height: self.view.frame.height - 44)
        scrollView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        scrollView.autoresizesSubviews = true
        scrollView.backgroundColor = UIColor.clear
        
        var textLabel: UILabel
        textLabel = UILabel()
        textLabel.frame = CGRect(x: 20, y: 20, width: scrollView.frame.width - 40, height: scrollView.frame.height - 20);
        textLabel.font = UIFont.systemFont(ofSize: 13)
        textLabel.textColor = UIColor.NFXGray44Color()
        textLabel.numberOfLines = 0
        textLabel.attributedText = content
        textLabel.sizeToFit()
        textLabel.isUserInteractionEnabled = true
        scrollView.addSubview(textLabel)
        
        let lpgr = UILongPressGestureRecognizer(target: self, action: #selector(copyLabel))
        textLabel.addGestureRecognizer(lpgr)
        
        var moreButton: UIButton
        moreButton = UIButton.init(frame: CGRect(x: 20, y: textLabel.frame.maxY + 10, width: scrollView.frame.width - 40, height: 40))
        moreButton.backgroundColor = UIColor.NFXGray44Color()
        
        if ((forView == EDetailsView.request) && (self.selectedModel.requestBodyLength > 1024)) {
            moreButton.setTitle("Show request body", for: UIControlState())
            moreButton.addTarget(self, action: #selector(requestBodyButtonPressed), for: .touchUpInside)
            scrollView.addSubview(moreButton)
            scrollView.contentSize = CGSize(width: textLabel.frame.width, height: moreButton.frame.maxY + 16)
            
        } else if ((forView == EDetailsView.response) && (self.selectedModel.responseBodyLength > 1024)) {
            moreButton.setTitle("Show response body", for: UIControlState())
            moreButton.addTarget(self, action: #selector(responseBodyButtonPressed), for: .touchUpInside)
            scrollView.addSubview(moreButton)
            scrollView.contentSize = CGSize(width: textLabel.frame.width, height: moreButton.frame.maxY + 16)
            
        } else {
            scrollView.contentSize = CGSize(width: textLabel.frame.width, height: textLabel.frame.maxY + 16)
        }
        view.addSubview(scrollView)
        return scrollView
    }
    
    func actionButtonPressed(_ sender: UIBarButtonItem) {
        let actionSheetController: UIAlertController = UIAlertController(title: "Share", message: nil, preferredStyle: .actionSheet)
        
        let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .cancel)
        actionSheetController.addAction(cancelAction)
        
        let simpleLog: UIAlertAction = UIAlertAction(title: "Simple log", style: .default) { [unowned self] action -> Void in
            self.sendMailWithBodies(false)
        }
        actionSheetController.addAction(simpleLog)
        
        let fullLogAction: UIAlertAction = UIAlertAction(title: "Full log", style: .default) { [unowned self] action -> Void in
            self.sendMailWithBodies(true)
        }
        actionSheetController.addAction(fullLogAction)
        actionSheetController.view.tintColor = .orange
        
        self.present(actionSheetController, animated: true, completion: nil)
    }
    
    func headerButtonPressed(_ btn: UIButton) {
        buttonPressed(btn)
    }
    
    func handleSwipe(_ gesture: UISwipeGestureRecognizer) {
        guard let currentButtonIdx = headerButtons.index(where: { $0.isSelected }) else { return }
        let numButtons = headerButtons.count
        
        switch gesture.direction {
        case UISwipeGestureRecognizerDirection.left:
            let nextIdx = currentButtonIdx + 1
            buttonPressed(headerButtons[nextIdx > numButtons - 1 ? 0 : nextIdx])
        case UISwipeGestureRecognizerDirection.right:
            let previousIdx = currentButtonIdx - 1
            buttonPressed(headerButtons[previousIdx < 0 ? numButtons - 1 : previousIdx])
        default: break
        }
    }
    
    func buttonPressed(_ sender: UIButton) {
        guard let selectedButtonIdx = self.headerButtons.index(of: sender) else { return }
        let infoViews = [self.infoView, self.requestView, self.responseView]
        
        UIView.animate(withDuration: 0.4,
                       delay: 0.0,
                       usingSpringWithDamping: 0.8,
                       initialSpringVelocity: 0.7,
                       options: .curveEaseInOut,
                       animations: { [unowned self] in
                        self.headerButtons.indices.forEach {
                            let button = self.headerButtons[$0]
                            let view = infoViews[$0]
                            
                            button.isSelected = button == sender
                            view.frame = CGRect(x: CGFloat(-selectedButtonIdx + $0) * view.frame.size.width,
                                                y: view.frame.origin.y,
                                                width: view.frame.size.width,
                                                height: view.frame.size.height)
                        }
            },
                       completion: nil)
    }
    
    func responseBodyButtonPressed() {
        bodyType = .response
    }
    
    func requestBodyButtonPressed() {
        bodyType = .request
    }
    
    func bodyButtonPressed() {
        
        if selectedModel.shortType == HTTPModelShortType.IMAGE.rawValue {
            let imageVC = ImageBrowserViewController()
            imageVC.setImageDataString(selectedModel.getResponseBody())
            navigationController?.pushViewController(imageVC, animated: true)
        } else {
            let bodyVC = TextBrowserViewController()
            bodyVC.bodyText = bodyType == .request ? selectedModel.getRequestBody() : selectedModel.getResponseBody()
            navigationController?.pushViewController(bodyVC, animated: true)
        }
    }
    
    func sendMailWithBodies(_ bodies: Bool) {
        guard MFMailComposeViewController.canSendMail() else { return }
        
        let mailComposer = MFMailComposeViewController()
        mailComposer.mailComposeDelegate = self
        
        var tempString: String
        tempString = String()
        
        
        tempString += "** INFO **\n"
        tempString += "\(getInfoStringFromObject(self.selectedModel).string)\n\n"
        
        tempString += "** REQUEST **\n"
        tempString += "\(getRequestStringFromObject(self.selectedModel).string)\n\n"
        
        tempString += "** RESPONSE **\n"
        tempString += "\(getResponseStringFromObject(self.selectedModel).string)\n\n"
        
        mailComposer.setSubject("\(self.selectedModel.requestURL!)")
        mailComposer.setMessageBody(tempString, isHTML: false)
        
        if bodies {
            let requestFilePath = self.selectedModel.getRequestBodyFilepath()
            if let requestFileData = try? Data(contentsOf: URL(fileURLWithPath: requestFilePath as String)) {
                mailComposer.addAttachmentData(requestFileData, mimeType: "text/plain", fileName: "request-body")
            }
            
            let responseFilePath = self.selectedModel.getResponseBodyFilepath()
            if let responseFileData = try? Data(contentsOf: URL(fileURLWithPath: responseFilePath as String)) {
                mailComposer.addAttachmentData(responseFileData, mimeType: "text/plain", fileName: "response-body")
            }
        }
        
        self.present(mailComposer, animated: true, completion: nil)
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        self.dismiss(animated: true, completion: nil)
    }
}
