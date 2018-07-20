//
//  LabelTableViewCell.swift
//  pretixios
//
//  Created by Marc Delling on 18.09.17.
//  Copyright © 2017 Silpion IT-Solutions GmbH. All rights reserved.
//

import UIKit

class LabelTableViewCell: UITableViewCell {
    
    let label = UILabel()
    let valueLabel = UILabel()
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    fileprivate func setup() {
        self.selectionStyle = UITableViewCellSelectionStyle.default
        self.accessoryType = .disclosureIndicator
        
        label.font = UIFont(name: "HelveticaNeue", size: 17.0)
        label.textColor = UIColor.darkText
        label.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.addSubview(label)
        
        valueLabel.font = UIFont(name: "HelveticaNeue", size: 17.0)
        valueLabel.textColor = UIColor.lightGray
        valueLabel.adjustsFontSizeToFitWidth = true
        valueLabel.textAlignment = .right
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.addSubview(valueLabel)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 14),
            valueLabel.leadingAnchor.constraint(equalTo: label.trailingAnchor, constant: 8),
            valueLabel.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor, constant: -14),
            
            label.widthAnchor.constraint(greaterThanOrEqualToConstant: 50),
            label.centerYAnchor.constraint(equalTo: self.contentView.centerYAnchor),
            
            valueLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 100),
            valueLabel.centerYAnchor.constraint(equalTo: self.contentView.centerYAnchor)
        ])
    }

    
}
