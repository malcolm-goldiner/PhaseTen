//
//  Phase10BackingModels.swift
//  PhaseTen
//
//  Created by Malcolm Goldiner on 4/6/20.
//  Copyright © 2020 Malcolm Goldiner. All rights reserved.
//

import Foundation

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
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(name())
        hasher.combine(requirements())
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
    
    func valid(fromCards cards: [Phase10Card], combo: ValidatedCombo? = nil) -> (Bool, Phase10CardType?) {
        switch self {
        case .setOf(let count):
            let sorted = cards.sorted(by: { (a: Phase10Card , b: Phase10Card) in a.type.rawValue < b.type.rawValue }).filter { $0.type.value() > Phase10CardType.maxFaceCardValue}
            
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
            let sorted = Array(Set(cards)).sorted(by: { (a: Phase10Card , b: Phase10Card) in a.type.rawValue < b.type.rawValue }).filter { $0.type.value() > Phase10CardType.maxFaceCardValue}
            
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



class Phase10Player: Equatable, Hashable {
    
    static func == (lhs: Phase10Player, rhs: Phase10Player) -> Bool {
        return lhs.hand == rhs.hand && lhs.phase == rhs.phase
    }
    
    var name: String?
    
    var hand: [Phase10Card] = []
    
    var potentialSets: [Phase10Card] = []
    
    var phase: Phase? =  Phase10GameEngine.generalReqs.first
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(hand)
        hasher.combine(phase)
    }
}
