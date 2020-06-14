//
//  Phase10GameEngine.swift
//  PhaseTen
//
//  Created by Malcolm Goldiner on 4/4/20.
//  Copyright © 2020 Malcolm Goldiner. All rights reserved.
//

import Foundation
import Combine

class Phase10GameEngine: Phase10Model {
    
    static let shared = Phase10GameEngine()
    
    static let recordType = "Phase10Game"
    
    enum Key: String {
        case discardPile = "discardPile"
        case players = "players"
        case turnIndex = "turnIndex"
        case hasWinner = "hasWinner"
    }
    
    private static let handSize = 10
    
    private static let maxPlayers = 6
    
    static let generalReqs: [Phase] = [
        .one(requirements:[.numberOf(count: 2, combos: .setOf(count: 3))]),
        .two(requirements: [.setOf(count: 3), .runOf(count: 4)]),
        .three(requirements: [.setOf(count: 4), .runOf(count: 4)]),
        .four(requirements: [.runOf(count: 7)]),
        .five(requirements: [.runOf(count: 8)]),
        .six(requirements: [.runOf(count: 9)]),
        .seven(requirements: [.numberOf(count: 2, combos: .setOf(count: 4))]),
        .eight(requirements: [.numberOfColor(count: 7)]),
        .nine(requirements: [.setOf(count: 5), .setOf(count: 2)]),
        .ten(requirements: [.setOf(count: 5), .setOf(count: 3)])
    ]
    
    @Published
    var deck = Phase10Deck()
    
    @Published
    var discardPile = [Phase10Card]()
    
    @Published
    var players = [Phase10Player]()
    
    @Published
    var scoresByPlayer = [Phase10Player: Int]()
    
    @Published
    var winningPlayer: Phase10Player?
    
    @Published
    var turnIndex: Int = 0
    
    var currentTurn: Phase10Turn?
    
    override init() {
        super.init()
        
        players.forEach { player in
            beginRoundForPlayer(player)
        }
        
        if let flippedCard = deck.cards.first {
            deck.cards.remove(at: 0)
            discardPile.append(flippedCard)
        }
    }
    
    func movePlayerToNextPhase(_ player: Phase10Player) {
        if let phase = player.phase {
            switch phase {
            case .nine(_):
                print("GAME OVER")
                
                for (player, score) in scoresByPlayer {
                    print("\(String(describing: player.name)): \(score)")
                }
            default:
                if let index = Phase10GameEngine.generalReqs.firstIndex(where: { $0 == phase }) {
                    player.phase = Phase10GameEngine.generalReqs[index + 1]
                }
            }
        }
    }
    
    func addActionToTurn(_ action: Phase10Action) {
        if currentTurn == nil {
            currentTurn = Phase10Turn()
        }
        
        currentTurn?.addAction(action)
        
        if currentTurn?.isComplete == true {
            turnIndex += 1
            currentTurn = nil
        }
    }
    
    func beginNewRound() {
        for player in players {
            discardPile.insert(contentsOf: player.hand, at: 0)
            player.hand = []
            beginRoundForPlayer(player)
            
            if player != winningPlayer {
                // not here
                scoresByPlayer[player, default: 0] += player.hand.reduce(0) { $0 + $1.type.rawValue }
            }
        }
    }
    
    func addPlayer() {
        guard players.count < Phase10GameEngine.maxPlayers - 1 else {
            print("Can't add anymore players")
            return
        }
        
        let newPlayer = Phase10Player()
        players.append(newPlayer)
        beginRoundForPlayer(newPlayer)
    }
    
    private func beginRoundForPlayer(_ player: Phase10Player) {
        if player.phase == nil {
            player.phase = Phase10GameEngine.generalReqs.first
        }
        
        player.hand.append(contentsOf: deck.cards[0...9])
        deck.cards.removeSubrange(0...9)
    }
    
    func isPhaseCleared(for player: Phase10Player,
                        playedCards: [[Phase10Card]]) -> Bool {
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
            
            for index in 0..<requirements.count {
                print(requirements[index].description())
                switch requirements[index] {
                case .numberOf(_, _) where requirements.count == 1:
                    result = requirements[index].valid(fromCards: playedCards.reduce([], +)).0
                default:
                    result = requirements[index].valid(fromCards: playedCards[index]).0
                }
            }
        default:
            result =  false
        }
        
        return result
    }
    
    func validatePhase(for player: Phase10Player, playedCards: [[Phase10Card]]) -> Bool {
        let result = isPhaseCleared(for: player, playedCards: playedCards)
        if result {
            movePlayerToNextPhase(player)
            discardPile.append(contentsOf: playedCards.first!)
            discardPile.append(contentsOf: playedCards.last!)
            winningPlayer = player
        }
        
        return result
    }
    
}
