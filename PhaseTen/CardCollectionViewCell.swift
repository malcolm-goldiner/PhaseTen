//
//  CardCollectionViewCell.swift
//  PhaseTen
//
//  Created by Malcolm Goldiner on 4/5/20.
//  Copyright © 2020 Malcolm Goldiner. All rights reserved.
//

import UIKit

class CardCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var cardTypeLabel: UILabel!
    
    var card: Phase10Card? {
        didSet {
            guard let card = card else {
                return 
            }
            
            cardTypeLabel.text = "\(card.type.value())"
            cardTypeLabel.textColor = .white
            
            backgroundColor = card.color
        }
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}
