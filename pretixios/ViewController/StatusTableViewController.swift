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
    private let states : [PretixOrderResponse.Result.Status] = [.n,.p,.e,.c,.r] // FIXME: allState swift 4.2
    
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
        if let status = order?.status, let index = states.index(of: status), index == indexPath.row {
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

class DonutChartImage : NSObject {
    
    var startAngle =  CGFloat(.pi / -2.0)
    var donutWidth = CGFloat(1.0)
    var labelColor = UIColor.black
    var labelFont = UIFont.preferredFont(forTextStyle: .body)
    var labelText : NSString?
    var values = [CGFloat]()
    var colors = [UIColor]()
    
    func drawImage(frame: CGRect, scale: CGFloat) -> UIImage? {
        assert(values.count > 0, "DonutChartImage // must assign values property which is an array of NSNumber")
        assert(colors.count > 0, "DonutChartImage // must assign colors property which is an array of UIColor")
        #if TARGET_OS_IOS
        return self.drawImagePreferringImageRenderer(frame, scale:scale);
        #else
        return self.drawImageForGeneral(frame, scale:scale);
        #endif
    }
    
    //MARK: - Draw Image(Private)
    
    #if TARGET_OS_IOS
    func drawImagePreferringImageRenderer(_ frame: CGRect, scale: CGFloat) -> UIImage {
        if UIGraphicsImageRenderer.class {
            let renderer = UIGraphicsImageRenderer(size: frame.size)
            return renderer.image { (context) in
                self.drawPathIn(frame:frame)
            }
        } else {
            return self.drawImageForGeneral(frame, scale:scale);
        }
    }
    #endif
    
    func drawImageForGeneral(_ frame: CGRect, scale: CGFloat) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(frame.size, false, scale);
        self.drawPathIn(frame: frame)
        let image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        return image;
    }
    
    //MARK: - Draw Paths(Private)
    
    func drawPathIn(frame: CGRect) {
        
        let totalValue = values.reduce(0, +)
        let center = CGPoint(x: frame.size.width / 2, y: frame.size.height / 2)
        let maxLength = min(frame.size.width, frame.size.height)
        let radius = maxLength / 2 - donutWidth / 2
        
        if let labelText = labelText {
            let labelAttributes = [NSAttributedStringKey.foregroundColor: labelColor, NSAttributedStringKey.font: labelFont]
            let size = labelText.boundingRect(with: CGSize(width: maxLength, height: CGFloat.greatestFiniteMagnitude), options: [NSStringDrawingOptions.usesLineFragmentOrigin, NSStringDrawingOptions.truncatesLastVisibleLine], attributes: labelAttributes, context: nil).size
            labelText.draw(at: CGPoint(x: center.x - size.width / 2, y: center.y - size.height / 2), withAttributes: labelAttributes)
        }
        
        for (index, value) in values.enumerated() {
            let normalizedValue = value / totalValue
            let strokeColor = colors[index]
            let endAngle = startAngle + CGFloat(.pi * 2.0) * normalizedValue
            let donutPath = UIBezierPath(arcCenter: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
            donutPath.lineWidth = donutWidth
            strokeColor.setStroke()
            donutPath.stroke()
            startAngle = endAngle
        }
    }
}
