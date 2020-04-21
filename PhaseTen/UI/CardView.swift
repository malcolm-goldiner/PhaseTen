//
//  CardView.swift
//  PhaseTen
//
//  Created by Malcolm Goldiner on 4/6/20.
//  Copyright © 2020 Malcolm Goldiner. All rights reserved.
//

import UIKit

class CardView: UIView {
    
    @IBOutlet weak var cardTypeLabel: UILabel!
    
    static let nibName = "CardCell"

    var card: Phase10Card? {
        willSet {
            guard newValue != card else {
                return
            }
            
            cardTypeLabel.text = newValue?.type.displayValue()
            cardTypeLabel.textColor = .white
            
            backgroundColor = newValue?.color
        }
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
}
