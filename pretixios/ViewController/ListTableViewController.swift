//
//  ListTableViewController.swift
//  pretixios
//
//  Created by Marc Delling on 10.09.17.
//  Copyright © 2017 Silpion IT-Solutions GmbH. All rights reserved.
//

import UIKit
import CoreData

class ListTableViewController: UITableViewController, UISearchBarDelegate, UISearchResultsUpdating, NSFetchedResultsControllerDelegate, UIPopoverPresentationControllerDelegate {

    private let searchController = UISearchController(searchResultsController: nil)
    private var _fetchedResultsController: NSFetchedResultsController<Order>?
    
    weak var detailTableViewController: DetailTableViewController?
    
    private var syncfails = 0
    
    var fetchedResultsController: NSFetchedResultsController<Order> {
        if let fetchedResultsController = _fetchedResultsController {
            return fetchedResultsController
        } else {
            let fetchRequest: NSFetchRequest<Order> = Order.fetchRequest()
            
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "attendee_name", ascending: true, selector: #selector(NSString.caseInsensitiveCompare))]
            
            let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
                                                                      managedObjectContext: SyncManager.sharedInstance.viewContext,
                                                                      sectionNameKeyPath: "uppercaseFirstLetterOfName",
                                                                      cacheName: nil)
            fetchedResultsController.delegate = self
            
            _fetchedResultsController = fetchedResultsController
            return fetchedResultsController
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.register(AttendeeTableViewCell.self, forCellReuseIdentifier: "cell")
        self.tableView.rowHeight = 50
        
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(refreshControlAction), for: UIControl.Event.valueChanged)

        searchController.searchBar.placeholder = NSLocalizedString("Name / Company / Email", comment: "")
        searchController.searchBar.delegate = self
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        searchController.searchBar.searchBarStyle = .minimal
        
        if #available(iOS 11.0, *), UIDevice.current.userInterfaceIdiom != .pad {
            navigationItem.searchController = searchController
            navigationItem.hidesSearchBarWhenScrolling = false
            searchController.hidesNavigationBarDuringPresentation = true
        } else {
            self.navigationController?.navigationBar.isTranslucent = false
            tableView.tableHeaderView = self.searchController.searchBar
            searchController.hidesNavigationBarDuringPresentation = false
            searchController.searchBar.sizeToFit()
        }
        
        self.definesPresentationContext = true;
        
        self.fetchedResultsController.tryFetch()
        self.setTitleWithGuests()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if UserDefaults.standard.bool(forKey: "app_configured") == true {
            _fetchedResultsController = nil
            receiveSyncDoneNotification()
        }
    }
    
    private func setTitleWithGuests() {
        let string = NSMutableAttributedString()
        string.append(NSMutableAttributedString(string: NSLocalizedString("Attendees\n", comment: ""), attributes: [NSAttributedString.Key.font: UIFont(name: "HelveticaNeue-Bold", size: 18.0)!]))
        
        if UserDefaults.standard.bool(forKey: "app_configured") == true {
            let total = Stats.fetchCount(for: "Order", predicate: NSPredicate(value: true), with: SyncManager.sharedInstance.viewContext)
            let checkins = Stats.fetchCount(for: "Order", predicate: NSPredicate(format: "checkin != NULL"), with: SyncManager.sharedInstance.viewContext)
            let format = String(format: NSLocalizedString("%d total, %d checkins", comment: ""), total, checkins)
            string.append(NSMutableAttributedString(string: format, attributes: [NSAttributedString.Key.font: UIFont(name: "HelveticaNeue-Thin", size: 9.0)!, NSAttributedString.Key.foregroundColor: UIColor.darkGray]))
            setTableViewPlaceholder(isEmpty: false)
        } else {
            string.append(NSMutableAttributedString(string: NSLocalizedString("No configuration", comment: ""), attributes: [NSAttributedString.Key.font: UIFont(name: "HelveticaNeue-Thin", size: 10.0)!, NSAttributedString.Key.foregroundColor: UIColor.darkGray]))
            setTableViewPlaceholder(isEmpty: true)
        }
        
        let navigationBarTitleLabel = UILabel()
        navigationBarTitleLabel.numberOfLines = 2
        navigationBarTitleLabel.textAlignment = .center
        navigationBarTitleLabel.attributedText = string
        navigationBarTitleLabel.sizeToFit()
        self.navigationItem.titleView = navigationBarTitleLabel
    }
    
    private func setTableViewPlaceholder(isEmpty: Bool) {
        if isEmpty {
            let messageLabel = UILabel(frame: CGRect(x: 0, y: 0, width: self.view.bounds.size.width, height: self.view.bounds.size.height))
            messageLabel.text = NSLocalizedString("This list is empty.\nMaybe you need to configure the app first using the scanner or pull down to refresh.", comment: "")
            messageLabel.textColor = UIColor.black
            messageLabel.numberOfLines = 0;
            messageLabel.textAlignment = NSTextAlignment.center;
            messageLabel.font = UIFont(name: "HelveticaNeue-Thin", size: 20)
            messageLabel.sizeToFit()
            self.tableView.backgroundView = messageLabel;
            self.tableView.separatorStyle = UITableViewCell.SeparatorStyle.none
        } else {
            self.tableView.separatorStyle = UITableViewCell.SeparatorStyle.singleLine
            self.tableView.backgroundView = nil
        }
    }
    
    // MARK: - Actions
    
    @objc func refreshControlAction() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(receiveSyncUpdateNotification(notification:)),
                                               name: NSNotification.Name(rawValue: "syncUpdate"),
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(receiveSyncDoneNotification),
                                               name: NSNotification.Name(rawValue: "syncDone"),
                                               object: nil)
        
        NetworkManager.sharedInstance.getPretixOrders()
        SyncManager.sharedInstance.resyncRedeemed()
    }
    
    // MARK: - Notifications
    
    @objc func receiveSyncUpdateNotification(notification: NSNotification) {
        if let a = notification.object as? (Int,Int) {
            DispatchQueue.main.async {
                print("Updating \(a.0) of \(a.1)")
                self.fetchedResultsController.tryFetch()
                self.tableView.reloadData()
                self.setTitleWithGuests()
            }
        }
    }
    
    @objc func receiveSyncDoneNotification() {
        NotificationCenter.default.removeObserver(self)
        DispatchQueue.main.async {
            self.refreshControl?.endRefreshing()
            self.fetchedResultsController.tryFetch()
            self.syncfails = Stats.fetchCount(for: "Order", predicate: NSPredicate(format: "synced == -1"), with: SyncManager.sharedInstance.viewContext)
            self.tableView.reloadData()
            self.setTitleWithGuests()
        }
    }
    
    // MARK: - Popover Delegates
  
    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.fullScreen
    }
    
    func presentationController(_ controller: UIPresentationController, viewControllerForAdaptivePresentationStyle style: UIModalPresentationStyle) -> UIViewController? {
        let navigationController = UINavigationController(rootViewController: controller.presentedViewController)
        let done = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(dismissPopover))
        navigationController.topViewController?.navigationItem.rightBarButtonItem = done
        return navigationController
    }
    
    @objc func dismissPopover() {
        self.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Table View Delegates
    
    func configure(_ cell: AttendeeTableViewCell, at indexPath: IndexPath) {
        let order = self.fetchedResultsController.object(at: indexPath)
        
        cell.nameLabel.text = order.attendee_name
        cell.auxiliaryLabel.text = order.company
            
        switch(order.status) {
        case .n:
            cell.stateLabel.text = NSLocalizedString("Pending", comment: "")
        case .p:
            cell.stateLabel.text = NSLocalizedString("Paid", comment: "")
        case .e:
            cell.stateLabel.text = NSLocalizedString("Expired", comment: "")
        case .c:
            cell.stateLabel.text = NSLocalizedString("Canceled", comment: "")
        case .r:
            cell.stateLabel.text = NSLocalizedString("Refunded", comment: "")
        }
        
        if let checkedin = order.checkin {
            cell.stateLabel.text = checkedin.shortTimeString()
        }
        
        if order.checkin_attention {
            cell.sourceView.backgroundColor = UIColor(red: 255 / 255.0, green: 99 / 255.0, blue: 132 / 255.0, alpha: 1) // Speaker
        } else if (order.synced == -1) {
            cell.sourceView.backgroundColor = UIColor.pretixYellowColor
        } else {
            cell.sourceView.backgroundColor = UIColor.clear
        }

    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            return 22
        } else {
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == 0 && syncfails > 0 {
            let headerView = UILabel(frame: CGRect(x: 0, y: 0, width: tableView.frame.size.width, height: 22))
            headerView.backgroundColor = UIColor.lightBlue
            if syncfails == 1 {
                headerView.text = String(format: NSLocalizedString("%d Checkin not synced. Pull to retry.", comment: ""), syncfails)
            } else {
                headerView.text = String(format: NSLocalizedString("%d Checkins not synced. Pull to retry.", comment: ""), syncfails)
            }
            headerView.textColor = UIColor.white
            headerView.textAlignment = .center
            headerView.font = UIFont(name: "Helvetica", size: 10)
            return headerView
        } else {
            return nil
        }
    }
    
    override func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return self.fetchedResultsController.sectionIndexTitles
    }
    
    override func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        return self.fetchedResultsController.section(forSectionIndexTitle: title, at: index)
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let sectionInfo = self.fetchedResultsController.sections?[section]
        return sectionInfo?.name
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! AttendeeTableViewCell
        configure(cell, at: indexPath)
        return cell
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        guard let sections = fetchedResultsController.sections else {
            return 0
        }
        return sections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let sections = fetchedResultsController.sections, section < sections.count else {
            return 0
        }
        return sections[section].numberOfObjects
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if UIDevice.current.userInterfaceIdiom == .pad {
            self.detailTableViewController?.order = self.fetchedResultsController.object(at: indexPath)
        } else {
            let detailViewController = DetailTableViewController()
            detailViewController.order = self.fetchedResultsController.object(at: indexPath)
            self.navigationController?.pushViewController(detailViewController, animated: true)
        }
    }

    // MARK: - Search Delegates
    
    func updateSearchResults(for searchController: UISearchController) {
        
        if let s = searchController.searchBar.text, s.count > 0 {
            let predicate = NSPredicate(format: "attendee_name contains[cd] %@ OR attendee_email contains[cd] %@ OR company contains[cd] %@", s, s, s)
            self.fetchedResultsController.fetchRequest.predicate = predicate
        } else {
            self.fetchedResultsController.fetchRequest.predicate = NSPredicate(value: true)
        }
        
        self.fetchedResultsController.tryFetch()
        tableView.reloadData()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        if var searchText = searchController.searchBar.text, searchText.hasPrefix("@") {
            searchText.remove(at: searchText.startIndex)
            fetchedResultsController.fetchRequest.predicate = NSPredicate(format: "%@", searchText) // NSInvalidArgumentException has to be caught in obj-c
            fetchedResultsController.tryFetch()
            tableView.reloadData()
        }
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        fetchedResultsController.fetchRequest.predicate = NSPredicate(value: true)
        fetchedResultsController.tryFetch()
        tableView.reloadData()
    }
    
    // MARK: - FetchedResultsController Delegates
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        switch type {
        case .insert:
            tableView.insertSections(IndexSet(integer: sectionIndex), with: .fade)
        case .delete:
            tableView.deleteSections(IndexSet(integer: sectionIndex), with: .fade)
        case .move:
            break
        case .update:
            break
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            if let newIndexPath = newIndexPath {
                tableView.insertRows(at: [newIndexPath], with: .fade)
            }
        case .delete:
            if let indexPath = indexPath {
                tableView.deleteRows(at: [indexPath], with: .fade)
            }
        case .update:
            if let indexPath = indexPath, let cell = tableView.cellForRow(at: indexPath) as? AttendeeTableViewCell {
                configure(cell, at: indexPath)
            }
        case .move:
            if let indexPath = indexPath, let newIndexPath = newIndexPath {
                tableView.moveRow(at: indexPath, to: newIndexPath)
            }
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }

}

