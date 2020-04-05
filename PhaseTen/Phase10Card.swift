//
//  Phase10Card.swift
//  PhaseTen
//
//  Created by Malcolm Goldiner on 4/2/20.
//  Copyright © 2020 Malcolm Goldiner. All rights reserved.
//

import UIKit

enum Phase10CardType: Int, CaseIterable {
    case one
    case two
    case three
    case four
    case five
    case six
    case seven
    case eight
    case nine
    case ten
    case eleven
    case twelve
    case skip
    case wild
    
    func value() -> Int {
        if rawValue < 12 {
            return rawValue + 1
        } else {
            return 20
        }
    }
}


class Phase10Card: Hashable, Equatable {
    
    static func == (lhs: Phase10Card, rhs: Phase10Card) -> Bool {
        return lhs.type == rhs.type && lhs.color == rhs.color
    }
    
    static let cardColors: [UIColor] = [.red, .blue, .yellow, .green]
    
    let type: Phase10CardType
    
    let color: UIColor?
    
    init(_ type: Phase10CardType, color: UIColor? = nil) {
        self.type = type
        self.color = color
    }
    
    func hash(into hasher: inout Hasher) {
      hasher.combine(type)
      hasher.combine(color)
    }
}

class Phase10Deck {
    
    let cards: [Phase10Card]
    
    init() {
        var buildingCards = [Phase10Card]()
        
        for type in Phase10CardType.allCases {
            switch type {
            case .wild:
                buildingCards.append(contentsOf: [Phase10Card(.wild), Phase10Card(.wild), Phase10Card(.wild), Phase10Card(.wild)])
            case .skip:
                buildingCards.append(contentsOf: [Phase10Card(.skip), Phase10Card(.skip)])
            default:
                for color in Phase10Card.cardColors {
                    buildingCards.append(contentsOf: [Phase10Card(type, color: color), Phase10Card(type, color: color)])
                }
            }
        }
        
        self.cards = buildingCards.shuffled()
    }
}
