//
//  PhaseTenTests.swift
//  PhaseTenTests
//
//  Created by Malcolm Goldiner on 5/26/20.
//  Copyright © 2020 Malcolm Goldiner. All rights reserved.
//

import XCTest
@testable import PhaseTen

class PhaseTenTests: XCTestCase {
    
    let engine = Phase10GameEngine.shared
    
    override func setUp() {
        engine.beginNewRound()
        engine.addPlayer()
    }
    
    func testValidatePhase(with cards: [Phase10Card]) {
        guard let testPlayer = engine.players.first else {
            XCTFail()
            return
        }
        
        XCTAssertTrue(engine.validatePhase(for: testPlayer, playedCards: cards))
    }
    
    func testMovePhaseOne() {
        let cards = [Phase10Card(.three, color: .green),
                     Phase10Card(.three, color: .red),
                     Phase10Card(.three, color: .orange),
                     Phase10Card(.four, color: .green),
                     Phase10Card(.four, color: .red),
                     Phase10Card(.four, color: .blue)]
      
        testValidatePhase(with: cards)
        
    }
    
    func testMovePhaseTwo() {
        let cards = [Phase10Card(.three, color: .green),
                     Phase10Card(.three, color: .red),
                     Phase10Card(.three, color: .orange),
                     Phase10Card(.one, color: .green),
                     Phase10Card(.two, color: .red),
                     Phase10Card(.three, color: .red),
                     Phase10Card(.four, color: .blue)]
        
        engine.players.first?.phase = Phase10GameEngine.generalReqs[0]
        
        testValidatePhase(with: cards)
    }

}
