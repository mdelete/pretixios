//
//  EventListTableViewController.swift
//  pretixios
//
//  Created by Marc Delling on 01.10.18.
//  Copyright © 2018 Silpion IT-Solutions GmbH. All rights reserved.
//

import UIKit
import CoreData

class EventListTableViewController: UITableViewController, NSFetchedResultsControllerDelegate {
    
    private var _fetchedResultsController: NSFetchedResultsController<Event>?
    private var selectedEventSlug : String?
    
    var fetchedResultsController: NSFetchedResultsController<Event> {
        if let fetchedResultsController = _fetchedResultsController {
            return fetchedResultsController
        } else {
            let fetchRequest: NSFetchRequest<Event> = Event.fetchRequest()
            
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
            
            let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
                                                                      managedObjectContext: SyncManager.sharedInstance.viewContext,
                                                                      sectionNameKeyPath: nil,
                                                                      cacheName: nil)
            fetchedResultsController.delegate = self
            
            _fetchedResultsController = fetchedResultsController
            return fetchedResultsController
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(refreshControlAction), for: UIControl.Event.valueChanged)
        
        self.definesPresentationContext = true;
        self.title = NSLocalizedString("Events", comment: "")
        
        self.fetchedResultsController.tryFetch()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if UserDefaults.standard.bool(forKey: "app_configured") == true {
            _fetchedResultsController = nil
            receiveSyncDoneNotification()
        }
        selectedEventSlug = UserDefaults.standard.string(forKey: "pretix_event_slug")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
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
        
        NetworkManager.sharedInstance.getPretixEvents()
    }
    
    // MARK: - Notifications
    
    @objc func receiveSyncUpdateNotification(notification: NSNotification) {
        if let _ = notification.object as? (Int,Int) {
            DispatchQueue.main.async {
                self.fetchedResultsController.tryFetch()
                self.tableView.reloadData()
            }
        }
    }
    
    @objc func receiveSyncDoneNotification() {
        NotificationCenter.default.removeObserver(self)
        DispatchQueue.main.async {
            self.refreshControl?.endRefreshing()
            self.fetchedResultsController.tryFetch()
            self.tableView.reloadData()
        }
    }
    
    // MARK: - Table View Delegates
    
    func configure(_ cell: UITableViewCell, at indexPath: IndexPath) {
        let event = self.fetchedResultsController.object(at: indexPath)
        cell.textLabel?.text = event.name
        if event.slug == selectedEventSlug {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
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
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
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
        let event = self.fetchedResultsController.object(at: indexPath)
        let checkinListTableViewController = CheckinListTableViewController()
        checkinListTableViewController.selectedEventSlug = event.slug
        self.navigationController?.pushViewController(checkinListTableViewController, animated: true)
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
        @unknown default:
            ()
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
        @unknown default:
            ()
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }
    
}
