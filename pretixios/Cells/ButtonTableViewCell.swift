//
//  ButtonTableViewCell.swift
//  pretixios
//
//  Created by Marc Delling on 20.09.17.
//  Copyright © 2017 Silpion IT-Solutions GmbH. All rights reserved.
//

import UIKit

protocol ButtonCellDelegate {
    func buttonTableViewCell(_ cell: ButtonTableViewCell, action: UIButton)
}

class ButtonTableViewCell: UITableViewCell {

    let button = UIButton(type: UIButton.ButtonType.system)
    var delegate : ButtonCellDelegate?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    var title : String? {
        get {
            return button.titleLabel?.text
        }
        set {
            button.setTitle(newValue, for: .normal)
        }
    }
    
    fileprivate func setup() {
        self.selectionStyle = .none

        let color = UIColor.lightBlue
        
        //button.titleLabel?.font = UIFont(name: "HelveticaNeue", size: 16.0)
        button.titleLabel?.font = .preferredFont(forTextStyle: .body)
        button.titleLabel?.textAlignment = .center
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.setTitleColor(color, for: .normal)
        button.setTitleColor(color, for: .selected)
        button.setTitleColor(color, for: .highlighted)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(buttonAction), for: .touchUpInside)
        
        self.contentView.addSubview(button)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    
        NSLayoutConstraint.activate([
            button.centerXAnchor.constraint(equalTo: self.contentView.centerXAnchor),
            //button.heightAnchor.constraint(equalToConstant: 44.5),
            button.heightAnchor.constraint(greaterThanOrEqualToConstant: 43.5),
            button.topAnchor.constraint(equalTo: self.contentView.topAnchor),
            button.bottomAnchor.constraint(lessThanOrEqualTo: self.contentView.bottomAnchor),
            button.widthAnchor.constraint(equalTo: self.contentView.widthAnchor, multiplier: 0.8)
        ])
        
    }

    @objc fileprivate func buttonAction() {
        delegate?.buttonTableViewCell(self, action: self.button)
    }
}
