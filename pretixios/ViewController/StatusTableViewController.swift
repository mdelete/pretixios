//
//  StatusTableViewController.swift
//  pretixios
//
//  Created by Marc Delling on 02.05.18.
//  Copyright © 2018 Silpion IT-Solutions GmbH. All rights reserved.
//

import UIKit

class StatusTableViewController: UITableViewController {

    public var order: Order?
    private let states : [PretixOrderResponse.Result.Status] = [.n,.p,.e,.c,.r]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return states.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        if let status = order?.status, let index = states.firstIndex(of: status), index == indexPath.row {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }
        cell.selectionStyle = .none
        let status = states[indexPath.row]
        switch(status) {
        case .n:
            cell.textLabel?.text = NSLocalizedString("Pending", comment: "")
        case .p:
            cell.textLabel?.text = NSLocalizedString("Paid", comment: "")
        case .e:
            cell.textLabel?.text = NSLocalizedString("Expired", comment: "")
        case .c:
            cell.textLabel?.text = NSLocalizedString("Canceled", comment: "")
        case .r:
            cell.textLabel?.text = NSLocalizedString("Refunded", comment: "")
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        order?.status = states[indexPath.row]
        tableView.reloadData()
    }
}
