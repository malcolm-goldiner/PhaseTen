//
//  Phase10BackingModels.swift
//  PhaseTen
//
//  Created by Malcolm Goldiner on 4/6/20.
//  Copyright © 2020 Malcolm Goldiner. All rights reserved.
//

import Foundation
import Combine

enum Phase: Equatable, Hashable {
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
    
    func description() -> String {
        guard let requirements = requirements() else {
            return ""
        }
        
        return requirements.reduce("") { $0 + "-" + $1.description() }
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(name())
        hasher.combine(requirements())
    }
    
    static func phase(from phase: Int) -> Phase? {
        guard let reqs = Phase10GameEngine.generalReqs[phase].requirements() else {
            return nil
        }
        
        switch phase {
        case 0:
            return .one(requirements: reqs)
        case 1:
            return .two(requirements: reqs)
        case 2:
            return .three(requirements: reqs)
        case 3:
            return .four(requirements: reqs)
        case 4:
            return .five(requirements: reqs)
        case 5:
            return .six(requirements: reqs)
        case 6:
            return .seven(requirements: reqs)
        case 7:
            return .eight(requirements: reqs)
        case 8:
            return .nine(requirements: reqs)
        case 9:
            return .ten(requirements: reqs)
        default:
            return nil
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

indirect enum ValidatedCombo: Equatable, Hashable {
    case setOf(count: Int)
    case runOf(count: Int)
    case numberOfColor(count: Int)
    case numberOf(count:Int, combos: ValidatedCombo)
    
    func description() -> String {
        switch self {
        case .setOf(let count):
            return "Set of \(count)"
        case .runOf(let count):
            return "Run of \(count)"
        case .numberOfColor(let count):
            return "\(count) of Color"
        case .numberOf(let count, let combo):
            return "\(count) of \(combo.description())"
        }
    }
    
    func valid(fromCards cards: [Phase10Card], combo: ValidatedCombo? = nil) -> (Bool, Phase10CardType?) {
        switch self {
        case .setOf(let count):
            let sorted = cards.sorted(by: { (a: Phase10Card , b: Phase10Card) in a.type.rawValue < b.type.rawValue }).filter { $0.type.value() < Phase10CardType.maxFaceCardValue}
            
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
        case .runOf(count: let count):
            let sorted = Array(Set(cards)).sorted(by: { (a: Phase10Card , b: Phase10Card) in a.type.rawValue < b.type.rawValue }).filter { $0.type.value() < Phase10CardType.maxFaceCardValue}
            var runningCount = 1
            var runner = 1
           
            for _ in 0..<(sorted.count - 1) {
                if sorted[runner].type.value() == sorted[runner - 1].type.value() + 1 {
                    runningCount += 1
                    runner += 1
                }
            }
            
            return (runningCount >= count, sorted[runner - 1].type)
        case.numberOfColor(let count):
            let uniqueColors = Array(Set(cards.map { $0.color }))
            return (uniqueColors.map { (color) in cards.filter { $0.color == color }.count }.contains(count), nil)
            
        case .numberOf(let count, let combo):
            var updatedCards = cards
            var result = false
            for _ in 0..<count {
                let overallLastResult = combo.valid(fromCards: updatedCards)
                result = overallLastResult.0
                
                if !result {
                    return (false, nil)
                }
                
                let lastType = overallLastResult.1
                updatedCards.removeAll(where: { $0.type == lastType })
            }
            
            return (result, nil)
        }
        
        return (false, nil)
    }
}



class Phase10Player: Phase10Model, Equatable, Hashable {
    
    enum Key: String {
        case name = "name"
        case hand = "hand"
        case phase = "phase"
        case game = "game"
        case index = "index"
    }
    
    static let recordType = "Player"
    
    static func == (lhs: Phase10Player, rhs: Phase10Player) -> Bool {
        return lhs.hand == rhs.hand && lhs.phase == rhs.phase
    }
    
    var name: String?
    
    var isGameOwner: Bool = false
    
    var index: Int
    
    @Published
    var hand: [Phase10Card] = []
    
    @Published
    var firstPotentialSet: [Phase10Card] = []
    
    @Published
    var secondPotentialSet: [Phase10Card] = [] 
    
    @Published
    var phase: Phase? =  Phase10GameEngine.generalReqs.first
    
    init(name: String, phase: Int, index: Int) {
        self.name = name
        self.phase = Phase.phase(from: phase)
        self.index = index
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(hand)
        hasher.combine(phase)
    }
    
    weak var game: Phase10GameEngine?
    
}

enum Phase10Action: Equatable {
    case discard(card: Phase10Card)
    case pickup(card: Phase10Card)
    
    static func forSameCard(lhs: Phase10Action, rhs: Phase10Action) -> Bool {
        if case .pickup(let cardA) = lhs, case .discard(let cardB) = rhs {
            return cardA == cardB
        } else  if case .pickup(let cardA) = lhs, case .pickup(let cardB) = rhs {
            return cardA == cardB
        } else if case .discard(let cardA) = lhs, case .discard(let cardB) = rhs {
            return cardA == cardB
        } else if case .discard(let cardA) = lhs, case .pickup(let cardB) = rhs {
            return cardA == cardB
        }
        
        return false
    }
}

struct Phase10Turn {
    var discardAction: Phase10Action?
    
    var pickupAction: Phase10Action?
    
    var isComplete : Bool {
        if let discardAction = discardAction,
            let pickupAction = pickupAction {
            return !Phase10Action.forSameCard(lhs: discardAction, rhs: pickupAction)
        }
        
        return false
    }
    
    mutating func addAction(_ action: Phase10Action) {
        if case .discard(_) = action {
            discardAction = action
        } else if case .pickup(_) = action {
            pickupAction = action
        }
    }
}
