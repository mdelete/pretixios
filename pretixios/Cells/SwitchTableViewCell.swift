//
//  SwitchTableViewCell.swift
//  pretixios
//
//  Created by Marc Delling on 06.08.18.
//  Copyright © 2018 Silpion IT-Solutions GmbH. All rights reserved.
//

import UIKit

class SwitchTableViewCell: UITableViewCell {

    let label = UILabel()
    let swytch = UISwitch()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    fileprivate func setup() {
        self.selectionStyle = .none
        
        //label.font = UIFont(name: "HelveticaNeue", size: 17.0)
        label.font = .preferredFont(forTextStyle: .body)
        label.textColor = UIColor.darkText
        label.adjustsFontForContentSizeCategory = true
        label.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.addSubview(label)
        
        swytch.isEnabled = false
        swytch.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.addSubview(swytch)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 14),
            swytch.leadingAnchor.constraint(equalTo: label.trailingAnchor, constant: 8),
            swytch.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor, constant: -14),
            
            label.widthAnchor.constraint(greaterThanOrEqualToConstant: 50),
            label.centerYAnchor.constraint(equalTo: self.contentView.centerYAnchor),
            
            swytch.centerYAnchor.constraint(equalTo: self.contentView.centerYAnchor)
        ])
    }

}
