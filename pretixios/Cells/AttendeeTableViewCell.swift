//
//  GuestTableViewCell.swift
//  pretixios
//
//  Created by Marc Delling on 17.09.17.
//  Copyright © 2017 Silpion IT-Solutions GmbH. All rights reserved.
//

import UIKit

class AttendeeTableViewCell : UITableViewCell {
    
    let nameLabel = UILabel()
    let stateLabel = UILabel()
    let auxiliaryLabel = UILabel()
    let sourceView = UIView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    fileprivate func setup() {
        
        self.selectionStyle = .default
        
        sourceView.backgroundColor = UIColor.clear
        sourceView.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.addSubview(sourceView)
        
        //nameLabel.font = UIFont(name: "HelveticaNeue", size: 17.0)
        nameLabel.font = .preferredFont(forTextStyle: .body)
        nameLabel.textColor = UIColor.darkText
        nameLabel.adjustsFontForContentSizeCategory = true
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.addSubview(nameLabel)
        
        //stateLabel.font = UIFont(name: "HelveticaNeue", size: 11.0)
        stateLabel.font = .preferredFont(forTextStyle: .callout)
        stateLabel.textColor = UIColor.lightBlue
        stateLabel.textAlignment = .right
        stateLabel.adjustsFontForContentSizeCategory = true
        stateLabel.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.addSubview(stateLabel)
        
        //auxiliaryLabel.font = UIFont(name: "HelveticaNeue", size: 11.0)
        auxiliaryLabel.font = .preferredFont(forTextStyle: .callout)
        auxiliaryLabel.textColor = UIColor.lightGray
        auxiliaryLabel.adjustsFontForContentSizeCategory = true
        auxiliaryLabel.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.addSubview(auxiliaryLabel)
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        NSLayoutConstraint.activate([
            
            sourceView.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 10),
            sourceView.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: 8),
            sourceView.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor, constant: -8),
            sourceView.widthAnchor.constraint(equalToConstant: 3),
            
            nameLabel.topAnchor.constraint(equalTo: self.contentView.topAnchor, constant: 5),
            nameLabel.leadingAnchor.constraint(equalTo: sourceView.trailingAnchor, constant: 8),
            nameLabel.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor, constant: -5),
            
            auxiliaryLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 2),
            auxiliaryLabel.leadingAnchor.constraint(equalTo: sourceView.trailingAnchor, constant: 8),
            
            stateLabel.leadingAnchor.constraint(equalTo: auxiliaryLabel.trailingAnchor, constant: 2),
            stateLabel.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor, constant: -5),
            stateLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 2),
            stateLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 50)
            
        ])
    }

}
