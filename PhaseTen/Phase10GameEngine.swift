//
//  Phase10GameEngine.swift
//  PhaseTen
//
//  Created by Malcolm Goldiner on 4/4/20.
//  Copyright © 2020 Malcolm Goldiner. All rights reserved.
//

import Foundation

enum Phase: Equatable {
    static func == (lhs: Phase, rhs: Phase) -> Bool {
        return lhs.requirements() == rhs.requirements() && lhs.name() == rhs.name()
    }
    
    func requirements() -> [ValidatedCombo]? {
        switch self {
        case .one(let requirements),
             .two( let requirements),
             .three(let requirements),
             .four(let requirements),
             .five(let requirements),
             .six(let requirements),
             .seven(let requirements),
             .eight(let requirements),
             .nine(let requirements),
             .ten(let requirements):
            return requirements
        default:
            return nil
        }
    }
    
    func name() -> String {
        switch self {
        case .one(_):
            return "one"
        case .two(_) :
            return "two"
        case .three(_):
            return "three"
        case .four(_):
            return "four"
        case .five(_):
        return "five"
        case .six(_):
            return "six"
        case .seven(_):
            return "seven"
        case .eight(_):
            return "eight"
        case .nine(_):
            return "nine"
        case .ten(_):
            return "ten"
        }
    }
    
    case one(requirements: [ValidatedCombo])
    case two(requirements: [ValidatedCombo])
    case three(requirements: [ValidatedCombo])
    case four(requirements: [ValidatedCombo])
    case five(requirements: [ValidatedCombo])
    case six(requirements: [ValidatedCombo])
    case seven(requirements: [ValidatedCombo])
    case eight(requirements: [ValidatedCombo])
    case nine(requirements: [ValidatedCombo])
    case ten(requirements: [ValidatedCombo])
    
}

indirect enum ValidatedCombo: Equatable {
    case setOf(count: Int)
    case runOf(coun: Int)
    case numberOfColor(count: Int)
    case numberOf(count:Int, combos: ValidatedCombo)
    
    func valid(fromCards cards: [Phase10Card]) -> (Bool, Phase10CardType?) {
        switch self {
        case .setOf(let count):
            let sorted = cards.sorted(by: { (a: Phase10Card , b: Phase10Card) in a.type.rawValue < b.type.rawValue }).filter { $0.type.value() > 12}
            
            var runningCount = 1
            var currentCard = sorted.first?.type
            
            for i in 1..<sorted.count {
                if sorted[i].type == currentCard {
                    runningCount += 1
                } else {
                    currentCard = sorted[i].type
                    runningCount = 1
                }
                
                if runningCount == count {
                    return (true, currentCard)
                }
            }
        case .runOf(coun: let count):
            let sorted = Array(Set(cards)).sorted(by: { (a: Phase10Card , b: Phase10Card) in a.type.rawValue < b.type.rawValue }).filter { $0.type.value() > 12}
            
            for i in 0..<sorted.count {
                var runningCount = 1
                var runner = i + 1
                
                while runningCount < count && runner < sorted.count {
                    if sorted[runner].type.value() == sorted[runner - 1].type.value() + 1 {
                        runningCount += 1
                        runner += 1
                    }
                    
                    break
                }
                
                return (runningCount >= count, sorted[runner].type)
            }
        case.numberOfColor(let count):
            let uniqueColors = Array(Set(cards.map { $0.color }))
            return (uniqueColors.map { (color) in cards.filter {$0.color == color}.count }.contains(count), nil)
            
        case .numberOf(let count, let combo):
            var updatedCards = cards
            var result = false
            for _ in 0..<count {
                let overallLastResult = valid(fromCards: updatedCards)
                result = overallLastResult.0
                
                if !result {
                    return (false, nil)
                }
                
                let lastType = overallLastResult.1
                
                updatedCards.removeAll(where: { $0.type == lastType})
            }
            
            return (result, nil)
        }
        
        return (false, nil)
    }
}



class Phase10Player {
    
    var hand: [Phase10Card] = []
    
    var phase: Phase? =  Phase10GameEngine.generalReqs.first
}

class Phase10GameEngine {
    
    static let generalReqs: [Phase] = [
        .one(requirements:[.numberOf(count: 2, combos: .setOf(count: 3))]),
        .two(requirements: [.setOf(count: 3), .runOf(coun: 4)]),
        .three(requirements: [.setOf(count: 4), .runOf(coun: 4)]),
        .four(requirements: [.runOf(coun: 7)]),
        .five(requirements: [.runOf(coun: 8)]),
        .six(requirements: [.runOf(coun: 9)]),
        .seven(requirements: [.numberOf(count: 2, combos: .setOf(count: 4))]),
        .eight(requirements: [.numberOfColor(count: 7)]),
        .nine(requirements: [.setOf(count: 5), .setOf(count: 2)]),
        .ten(requirements: [.setOf(count: 5), .setOf(count: 2)])
    ]
    
    
    var deck = Phase10Deck()
    
    var discardPile = [Phase10Card]()
    
    var players: [Phase10Player]
    
    func movePlayerToNextPhase(_ player: Phase10Player) {
        if let phase = player.phase {
            switch phase {
            case .nine(_):
                print("GAME OVER")
            default:
                if let index = Phase10GameEngine.generalReqs.firstIndex(where: { $0 == phase }) {
                    player.phase = Phase10GameEngine.generalReqs[index + 1]
                }
            }
        }
    }
    
    func pickFromDiscardPile(player: Phase10Player) {
        if let card = discardPile.last {
            player.hand.append(card)
        }
    }
    
    func discardCard(_ card: Phase10Card) {
        discardPile.append(card)
    }
    
    func addPlayer() {
        guard players.count > 5 else {
            print("Can't add anymore players")
        }
        
        let newPlayer = Phase10Player()
        newPlayer.phase = Phase10GameEngine.generalReqs.first
        newPlayer.hand.append(contentsOf: deck.cards.dropFirst(10))
    }
    
    func validatePhase(for player: Phase10Player) -> Bool {
        var result = false
        
        switch player.phase {
        case .one(let requirements),
             .two( let requirements),
             .three(let requirements),
             .four(let requirements),
             .five(let requirements),
             .six(let requirements),
             .seven(let requirements),
             .eight(let requirements),
             .nine(let requirements),
             .ten(let requirements):
            result =  requirements.reduce(true) { $0 && $1.valid(fromCards: player.hand).0 }
        default:
            result =  false
        }
        
        if result {
            movePlayerToNextPhase(player)
        }
        
        return result
    }
    
}
