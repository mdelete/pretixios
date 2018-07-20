//
//  GuestTableViewCell.swift
//  guests2
//
//  Created by Marc Delling on 17.09.17.
//  Copyright © 2017 Silpion IT-Solutions GmbH. All rights reserved.
//

import UIKit

class GuestTableViewCell : UITableViewCell {
    
    let nameLabel = UILabel()
    let stateLabel = UILabel()
    let auxiliaryLabel = UILabel()
    let sourceView = UIView()
    
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
        //contentView.backgroundColor = UIColor.cyan
        
        sourceView.backgroundColor = UIColor.clear
        sourceView.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.addSubview(sourceView)
        
        nameLabel.font = UIFont(name: "HelveticaNeue", size: 17.0)
        //nameLabel.backgroundColor = UIColor.yellow
        nameLabel.textColor = UIColor.darkText
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.addSubview(nameLabel)
        
        stateLabel.font = UIFont(name: "HelveticaNeue", size: 11.0)
        //stateLabel.backgroundColor = UIColor.red
        stateLabel.textColor = UIColor.lightBlue
        stateLabel.textAlignment = .right
        stateLabel.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.addSubview(stateLabel)
        
        auxiliaryLabel.font = UIFont(name: "HelveticaNeue", size: 11.0)
        //auxiliaryLabel.backgroundColor = UIColor.blue
        auxiliaryLabel.textColor = UIColor.lightGray
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
