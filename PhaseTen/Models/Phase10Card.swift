//
//  Phase10Card.swift
//  PhaseTen
//
//  Created by Malcolm Goldiner on 4/2/20.
//  Copyright © 2020 Malcolm Goldiner. All rights reserved.
//

import UIKit
import CloudKit

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
    
    static let maxFaceCardValue = 12
    
    func value() -> Int {
        if rawValue < Phase10CardType.maxFaceCardValue {
            return rawValue + 1
        } else {
            // wild and skip have the same value
            return 20
        }
    }
    
    func displayValue() -> String {
          if rawValue < Phase10CardType.maxFaceCardValue {
              return "\(rawValue + 1)"
          } else if self == .wild {
              // wild and skip have the same value
              return "Wild"
          } else if self == .skip {
            return "Skip"
        }
        
        return ""
      }
}


class Phase10Card: Phase10Model, Hashable, Equatable {
    
    enum Key: String {
        case type = "type"
        case description = "description"
        case deck = "deck"
        case placeIndex = "placeIndex"
    }
    
    static func == (lhs: Phase10Card, rhs: Phase10Card) -> Bool {
        return lhs.type == rhs.type && lhs.color == rhs.color
    }
    
    static let cardColors: [UIColor] = [.red, .blue, .orange, .green]
    
    static let recordType = "Phase10Card"
    
    let type: Phase10CardType
    
    let color: UIColor?
    
    var placeIndex: Int?
    
    var description: String {
        var desc: String = ""
        
        if color == .red {
                desc += "red"
        } else if color == .blue {
            desc += "blue"
        } else if color == .orange {
            desc += "orange"
        } else if color == .green {
            desc += "green"
        } else {
            desc += "black"
        }
        
        desc += " \(type.rawValue)"
        
        return desc
    }
    
    init(_ type: Phase10CardType, color: UIColor? = nil, recordID: CKRecord.ID? = nil) {
        self.type = type
        self.color = color ?? .black // default for wild and skip
        
        super.init()
        self.recordID = recordID
    }
    
    func hash(into hasher: inout Hasher) {
      hasher.combine(type)
      hasher.combine(color)
    }
}

class Phase10Deck: Phase10Model {
    
    static let recordType = "Deck"
    
    enum Key: String {
        case cards = "cards"
        case game = "game"
    }
    
    weak var game: Phase10GameEngine?
    
    var cards: [Phase10Card]
    
    init(recordID: CKRecord.ID? = nil) {
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
        super.init()
        self.recordID = recordID
    }
}
