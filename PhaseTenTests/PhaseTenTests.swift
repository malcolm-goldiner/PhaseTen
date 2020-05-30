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
    
    override class func setUp() {
        Phase10GameEngine.shared.addPlayer()
    }
    
    func testValidatePhase(with cards: [[Phase10Card]]) {
        guard let testPlayer = engine.players.first else {
            XCTFail()
            return
        }
        
        XCTAssertTrue(engine.isPhaseCleared(for: testPlayer, playedCards: cards))
    }
    
    func testMovePhaseOne() {
        let cardsOne = [Phase10Card(.three, color: .green),
                        Phase10Card(.three, color: .red),
                        Phase10Card(.three, color: .orange)]
        
        let cardsTwo = [Phase10Card(.four, color: .green),
                        Phase10Card(.four, color: .red),
                        Phase10Card(.four, color: .blue)]
        
        testValidatePhase(with: [cardsOne, cardsTwo])
        
    }
    
    func testMovePhaseTwo() {
        let cardsOne = [Phase10Card(.three, color: .green),
                        Phase10Card(.three, color: .red),
                        Phase10Card(.three, color: .orange)]
        
        let cardsTwo = [Phase10Card(.one, color: .green),
                        Phase10Card(.two, color: .red),
                        Phase10Card(.three, color: .red),
                        Phase10Card(.four, color: .blue)]
        
        engine.players.first?.phase = Phase10GameEngine.generalReqs[1]
        
        testValidatePhase(with: [cardsOne, cardsTwo])
    }
    
    func testMovePhaseThree() {
        let cardsOne = [Phase10Card(.three, color: .green),
                        Phase10Card(.three, color: .red),
                        Phase10Card(.three, color: .orange),
                        Phase10Card(.three, color: .blue)]
        
        let cardsTwo = [Phase10Card(.one, color: .green),
                        Phase10Card(.two, color: .red),
                        Phase10Card(.three, color: .red),
                        Phase10Card(.four, color: .blue)]
        
        engine.players.first?.phase = Phase10GameEngine.generalReqs[2]
        
        testValidatePhase(with: [cardsOne, cardsTwo])
    }
    
    func testMovePhaseFour() {
        let cardsOne = [Phase10Card(.one, color: .green),
                        Phase10Card(.two, color: .red),
                        Phase10Card(.three, color: .red),
                        Phase10Card(.four, color: .blue),
                        Phase10Card(.five, color: .blue),
                        Phase10Card(.six, color: .red),
                        Phase10Card(.seven, color: .green)]
        
        engine.players.first?.phase = Phase10GameEngine.generalReqs[3]
        
        testValidatePhase(with: [cardsOne])
    }
    
    func testMovePhaseFive() {
        let cardsOne = [Phase10Card(.one, color: .green),
                        Phase10Card(.two, color: .red),
                        Phase10Card(.three, color: .red),
                        Phase10Card(.four, color: .blue),
                        Phase10Card(.five, color: .blue),
                        Phase10Card(.six, color: .red),
                        Phase10Card(.seven, color: .green),
                        Phase10Card(.eight, color: .red)]
        
        engine.players.first?.phase = Phase10GameEngine.generalReqs[4]
        
        testValidatePhase(with: [cardsOne])
    }
    
    func testMovePhaseSix() {
        let cardsOne = [Phase10Card(.one, color: .green),
                        Phase10Card(.two, color: .red),
                        Phase10Card(.three, color: .red),
                        Phase10Card(.four, color: .blue),
                        Phase10Card(.five, color: .blue),
                        Phase10Card(.six, color: .red),
                        Phase10Card(.seven, color: .green),
                        Phase10Card(.eight, color: .red),
                        Phase10Card(.nine, color: .blue)]
        
        engine.players.first?.phase = Phase10GameEngine.generalReqs[5]
        
        testValidatePhase(with: [cardsOne])
    }
    
    func testMovePhaseSeven() {
        let cardsOne = [Phase10Card(.three, color: .green),
                        Phase10Card(.three, color: .red),
                        Phase10Card(.three, color: .orange),
                        Phase10Card(.three, color: .red)]
        
        let cardsTwo = [Phase10Card(.four, color: .green),
                        Phase10Card(.four, color: .red),
                        Phase10Card(.four, color: .blue),
                        Phase10Card(.four, color: .green)]
        
        engine.players.first?.phase = Phase10GameEngine.generalReqs[6]
        
        testValidatePhase(with: [cardsOne, cardsTwo])
        
    }
    
    func testMovePhaseEight() {
        let cardsOne = [Phase10Card(.one, color: .green),
                        Phase10Card(.two, color: .green),
                        Phase10Card(.three, color: .green),
                        Phase10Card(.four, color: .green),
                        Phase10Card(.five, color: .green),
                        Phase10Card(.six, color: .green),
                        Phase10Card(.seven, color: .green)]
        
        engine.players.first?.phase = Phase10GameEngine.generalReqs[7]
        
        testValidatePhase(with: [cardsOne])
    }
    
    func testMovePhaseNine() {
        let cardsOne = [Phase10Card(.three, color: .green),
                        Phase10Card(.three, color: .red),
                        Phase10Card(.three, color: .orange),
                        Phase10Card(.three, color: .red),
                        Phase10Card(.three, color: .green)]
        
        let cardsTwo = [Phase10Card(.four, color: .green),
                        Phase10Card(.four, color: .red)]
        
        engine.players.first?.phase = Phase10GameEngine.generalReqs[8]
        
        testValidatePhase(with: [cardsOne, cardsTwo])
    }
    
    func testMovePhaseTeh() {
        let cardsOne = [Phase10Card(.three, color: .green),
                        Phase10Card(.three, color: .red),
                        Phase10Card(.three, color: .orange),
                        Phase10Card(.three, color: .red),
                        Phase10Card(.three, color: .green)]
        
        let cardsTwo = [Phase10Card(.four, color: .green),
                        Phase10Card(.four, color: .red),
                        Phase10Card(.four, color: .blue)]
        
        engine.players.first?.phase = Phase10GameEngine.generalReqs[9]
        
        testValidatePhase(with: [cardsOne, cardsTwo])
    }
    
    
}
