//
//  TextFieldTableViewCell.swift
//  pretixios
//
//  Created by Marc Delling on 18.09.17.
//  Copyright © 2017 Silpion IT-Solutions GmbH. All rights reserved.
//

import UIKit

enum TextFieldType {
    case standard
    case email
    case number
}

class TextFieldTableViewCell: UITableViewCell, UITextFieldDelegate {

    let label = UILabel()
    let textField = UITextField()
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    public var type: TextFieldType {
        set {
            switch(newValue) {
            case .email:
                textField.keyboardType = .emailAddress
                textField.autocorrectionType = .no;
                textField.autocapitalizationType = .none;
            case .number:
                textField.keyboardType = .numberPad
                textField.autocorrectionType = .no;
                textField.autocapitalizationType = .none;
            case .standard:
                textField.keyboardType = .default
                textField.autocorrectionType = .no;
                textField.autocapitalizationType = .words;
            }
        }
        get {
            return TextFieldType.standard
        }
    }
    
    fileprivate func setup() {
        self.selectionStyle = UITableViewCellSelectionStyle.none
        
        //label.font = UIFont(name: "HelveticaNeue", size: 17.0)
        label.font = .preferredFont(forTextStyle: .body)
        label.textColor = UIColor.darkText
        label.adjustsFontForContentSizeCategory = true
        label.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.addSubview(label)
        
        //textField.font = UIFont(name: "HelveticaNeue", size: 17.0)
        textField.font = .preferredFont(forTextStyle: .body)
        textField.textColor = UIColor(red: 0.275, green:0.376, blue:0.522, alpha:1.000)
        textField.textAlignment = .right
        textField.keyboardType = .default
        textField.autocorrectionType = .no;
        textField.autocapitalizationType = .words;
        textField.delegate = self
        textField.adjustsFontForContentSizeCategory = true
        textField.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.addSubview(textField)
        self.contentView.addGestureRecognizer(UIGestureRecognizer(target: self.textField, action: #selector(becomeFirstResponder)))
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor, constant: 14),
            textField.leadingAnchor.constraint(equalTo: label.trailingAnchor, constant: 8),
            textField.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor, constant: -8),

            label.widthAnchor.constraint(greaterThanOrEqualToConstant: 20),
            label.centerYAnchor.constraint(equalTo: self.contentView.centerYAnchor),
            
            textField.widthAnchor.constraint(greaterThanOrEqualToConstant: 100),
            textField.centerYAnchor.constraint(equalTo: self.contentView.centerYAnchor)
        ])
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.endEditing(true)
        return false
    }
}
