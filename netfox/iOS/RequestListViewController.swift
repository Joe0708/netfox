import Foundation
import UIKit

class RequestListViewController: NFXListController, UITableViewDelegate, UITableViewDataSource, UISearchResultsUpdating, UISearchControllerDelegate {
    
    // MARK: UI
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.frame = self.view.frame
        tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        tableView.translatesAutoresizingMaskIntoConstraints = true
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = 55
        self.view.addSubview(tableView)
        
        tableView.register(RequestListCell.self, forCellReuseIdentifier: RequestListCell.description())
        return tableView
    }()

    private lazy var searchController: UISearchController = {
        let searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.delegate = self
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.dimsBackgroundDuringPresentation = false
        searchController.searchBar.autoresizingMask = [.flexibleWidth]
        searchController.searchBar.sizeToFit()
        searchController.searchBar.backgroundColor = UIColor.clear
        searchController.searchBar.searchBarStyle = .minimal
        searchController.view.backgroundColor = UIColor.clear
        return searchController
    }()
    
    private lazy var searchView: UIView = {
        let searchView = UIView()
        searchView.frame.size.height = self.view.frame.width
        searchView.autoresizingMask = [.flexibleWidth]
        searchView.autoresizesSubviews = true
        searchView.backgroundColor = UIColor.clear
        searchView.frame = self.searchController.searchBar.frame
        searchView.addSubview(self.searchController.searchBar)
        return searchView
    }()
    
    // MARK: View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        edgesForExtendedLayout = UIRectEdge()
        extendedLayoutIncludesOpaqueBars = false
        automaticallyAdjustsScrollViewInsets = false
        
        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(close)),
            UIBarButtonItem( image: UIImage.NFXSettings(), style: .plain, target: self, action: #selector(settingsButtonPressed))
        ]
        
        tableView.tableHeaderView = searchView
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(NFXListController.reloadTableViewData),
            name: NSNotification.Name(rawValue: "NFXReloadData"),
            object: nil)
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(RequestListViewController.deactivateSearchController),
            name: NSNotification.Name(rawValue: "NFXDeactivateSearch"),
            object: nil)        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadTableViewData()
    }
    
    func settingsButtonPressed() {
        var settingsController: NFXSettingsController_iOS
        settingsController = NFXSettingsController_iOS()
        self.navigationController?.pushViewController(settingsController, animated: true)
    }
    
    func close() {
        NFX.sharedInstance().hide()
    }
    
    // MARK: UISearchResultsUpdating
    
    func updateSearchResults(for searchController: UISearchController) {
        self.updateSearchResultsForSearchControllerWithString(searchController.searchBar.text!)
        reloadTableViewData()
    }
    
    func deactivateSearchController() {
        self.searchController.isActive = false
    }
    
    // MARK: UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let count = searchController.isActive ? filteredTableData.count : NFXHTTPModelManager.sharedInstance.getModels.count
        title = "Network (\(count) Requests)"
        return count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: RequestListCell.description(), for: indexPath) as! RequestListCell
        
        let obj = searchController.isActive ?
            filteredTableData[indexPath.row] :
            NFXHTTPModelManager.sharedInstance.getModels[indexPath.row]
        
        cell.configForObject(obj)
        
        cell.backgroundColor = indexPath.row % 2 == 0 ? #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0) : #colorLiteral(red: 0.9486700892, green: 0.9493889213, blue: 0.9487814307, alpha: 1)
        
        return cell
    }
    
    override func reloadTableViewData() {
        DispatchQueue.main.async {
            self.tableView.reloadData()
            self.tableView.setNeedsDisplay()
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        var detailsController : NFXDetailsController_iOS
        detailsController = NFXDetailsController_iOS()
        var model: NFXHTTPModel
        if (self.searchController.isActive) {
            model = self.filteredTableData[(indexPath as NSIndexPath).row]
        } else {
            model = NFXHTTPModelManager.sharedInstance.getModels[(indexPath as NSIndexPath).row]
        }
        detailsController.selectedModel(model)
        self.navigationController?.pushViewController(detailsController, animated: true)
        
    }
}
