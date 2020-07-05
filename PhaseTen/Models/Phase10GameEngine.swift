//
//  Phase10GameEngine.swift
//  PhaseTen
//
//  Created by Malcolm Goldiner on 4/4/20.
//  Copyright © 2020 Malcolm Goldiner. All rights reserved.
//

import Combine
import CloudKit

/// Manager of game state (decks, cards, scores) for up to 6 players governed by the official Phase10 Rules
class Phase10GameEngine: Phase10Model {
    
    // MARK: - Phase10Model
    
    /// String representing CloudKit Table name for the game entity
    static let recordType = "Phase10Game"
    
    // MARK: - Static Variables
    
    /// Shared Game Engine repesenting the CloudKit record entry for the current game
    static let shared = Phase10GameEngine()
    
    // MARK: - CloudKit Field Keys
    
    /// CloudKit field names contained within Phase10GameTable
    enum Key: String {
        case discardPile = "discardPile"
        case players = "players"
        case turnIndex = "turnIndex"
        case winningPlayerIndex = "winningPlayerIndex"
    }
    
    // MARK: - Constant Official Game Rules
    
    /// Default number of cards per Phase10 common rules
    private static let handSize = 10
    
    /// Max number of players per Phase10 common rules
    private static let maxPlayers = 6
    
    /// Most common Phases per Phase10 common rules
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
    
    // MARK: - Observed Public Game State Variables
    
    /// Main game deck of cards that all hands are dealt from
    @Published
    var deck = Phase10Deck()
    
    /// Discarded cards pile for all players, shown face up, starts game with the first card flipped
    @Published
    var discardPile = [Phase10Card]()
    
    /// Array of all players in this game
    @Published
    var players = [Phase10Player]()
    
    /// Players mapped to their score
    @Published
    var scoresByPlayer = [Phase10Player: Int]()
    
    /// Player who wins the game - expected to be nil until the game is over
    @Published
    var winningPlayer: Phase10Player?
    
    /// Integer representing the index in the players array of the player who's turn it is
    @Published
    var turnIndex: Int = 0
    
    /// Number of open CloudKit load requests
    @Published
    var openReqs = -1
    
    /// Number corresponding to invited players used and entered only on game owning device so that players cant be dealt in.
    @Published
    var expectedNumberOfPlayers: Int?
    
    // MARK: - Public Game State
    
    /// Phase10Turn keeping track of the cards picked up and discarded during this turn
    var currentTurn: Phase10Turn?
    
    /// Index in the Phase10Game's players array of the winning player
    var winningPlayerIndex: Int?
    
    /// The player corresponding to this current device and signed in iCloud Account
    var localPlayer: Phase10Player?
    
    // MARK: - Private Variables
    
    /// Only the GameOwner can deal everyone in, this returns turn when all players have joined and that message is recieved on the game owner's device.
    private var needToDeal: Bool = false {
        didSet {
            if needToDeal && Phase10GameEngineManager.shared.isGameOwner
            {
                players.forEach { [weak self] in
                    self?.beginRoundForPlayer($0)
                }
            }
        }
    }
    
    /// Card sorting function going by the placeIndex in the database (This should preserve order when decks are downloaded async)
    private let cardSort: (Phase10Card, Phase10Card) -> Bool = { (left, right) -> Bool in
        guard let leftPlace = left.placeIndex,
            let rightPlace = right.placeIndex else {
                return false
        }
        
        return leftPlace < rightPlace
    }
    
    /// Player sorting function going by the saved index in the database (this should preserve order when players are downloaded async)
    private let playerSort: (Phase10Player, Phase10Player) -> Bool = { (left, right) -> Bool in
        return left.index < right.index
    }
    
    // MARK: - Initailzers
    
    /// Initializes Game Engine and listens for all the cards and other plays to join and/or be downloaded from CloudKit before adding the first card to the discard pile from the deck and dealing in all players
    override init() {
        super.init()
        
        if Phase10GameEngineManager.shared.isGameOwner,
           discardPile.isEmpty,
           let flippedCard = deck.cards.first {
            deck.cards.remove(at: 0)
            discardPile.append(flippedCard)
        }
        
        let openReqSub = Subscribers.Assign(object: self, keyPath: \.needToDeal)
        $openReqs.combineLatest($expectedNumberOfPlayers).map { [weak self] (reqs, expectedPlayers) in reqs == 0 && expectedPlayers == self?.players.count }.subscribe(openReqSub)
    }
    
    // MARK: - Public Game Logic Functions
    
    /**
        Moves players in Phase 1...8 to the next phase, ends the game for a player on phase 9
     
        - Parameter player: the player who will be moved to the next Phase
     */
    func movePlayerToNextPhase(_ player: Phase10Player) {
        if let phase = player.phase {
            switch phase {
            case .nine(_):
                print("GAME OVER")
                
                for (player, score) in scoresByPlayer {
                    print("\(String(describing: player.name)): \(score)")
                }
                
                winningPlayer = player
            default:
                if let index = Phase10GameEngine.generalReqs.firstIndex(where: { $0 == phase }) {
                    player.phase = Phase10GameEngine.generalReqs[index + 1]
                }
            }
        }
    }
    
    /**
     Records either a pickup or discard action to the local players turn to keep track of whether they have completed their turn or not.
     
     - Parameter action: Phase10Action containing a card discard or pickup
     */
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
    
    /// Increments the scores of all players by the remaining cards in their hand, discards those cards, and calls out to deal in each player for the next round.
    func beginNewRound() {
        for player in players {
            if player != winningPlayer {
                // not here
                scoresByPlayer[player, default: 0] += player.hand.reduce(0) { $0 + $1.type.rawValue }
            }
            
            // probably need to shuffle the discard pile and deck
            discardPile.insert(contentsOf: player.hand, at: 0)
            player.hand = []
            beginRoundForPlayer(player)
        }
    }
    
    
    /// Adds the local player to the shared Phase10GameEngine's array of players if we are below the maximum number of players.
    ///  Sets as the game owner if the local devices iCloud account created the game.
    func addPlayer() {
        guard players.count < Phase10GameEngine.maxPlayers - 1 else {
            print("Can't add anymore players")
            return
        }
        
        // we may need to know whether all players are loaded here to see if this count index will be right
        // we should be able to get the users name from iCloud
        let newPlayer = Phase10Player(name: "default-name", phase: 0, index: Phase10GameEngineManager.shared.isGameOwner ? 0 : players.count)
        Phase10GameEngine.shared.localPlayer = newPlayer
        players.append(newPlayer)
    }
    
    // MARK: - Public Game Validation Functions
    
    /**
     Returns true if the input array of cards matches the requirement for the input player's current Phase
     
     - Parameters:
        - player: Phase10Player who played the input cards whose current Phase is being validated
        - playedCards: Arrays (should be 2) of Phase10Cards being checked against the requirements for the input player's current Phase.
     */
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
    
    /**
     Returns true when the input cards match the requirements for the input players current Phase10Phase according to the current game rules.
     If they do match, this player is moved to the next phase, or the game will end if this player has achieved Phase 10
     
     - Parameters:
        - player: Phase10Player who played the input cards
        - playedCards: Array of Phase10Cards to be checked against the requirements for the input player's current Phase
     */
    func validatePhase(for player: Phase10Player, playedCards: [[Phase10Card]]) -> Bool {
        let result = isPhaseCleared(for: player, playedCards: playedCards)
        if result {
            movePlayerToNextPhase(player)
            discardPile.append(contentsOf: playedCards.first!)
            discardPile.append(contentsOf: playedCards.last!)
            
            if case Phase.ten(requirements: _)? = player.phase {
                winningPlayer = player
            }
        }
        
        return result
    }
    
    // MARK: - CloudKit Sync
    
    /**
     Sets the local shared Phase10GameEngine's recordID to the Game record from the public iCloud database that matches the input gameID.
     
     - Parameter gameID: String corresponding to the recordName for the Phase10Game that should be returned
     */
    func loadGame(for gameID: String) {
        let reference = CKRecord.Reference(recordID: CKRecord.ID(recordName: gameID), action: .none)
        
        openReqs += 1
        CKContainer.default().publicCloudDatabase.fetch(withRecordID: reference.recordID) { [weak self] (record, error) in
            self?.recordID = record?.recordID
            
            // is this order constant
            if let turnIndex = record?[.turnIndex] as? Int {
                self?.turnIndex = turnIndex
            }
            
            if let winningPlayerIndex = record?[.winningPlayerIndex] as? Int {
                // set winning player -- need to store in db
                self?.winningPlayerIndex = winningPlayerIndex
            }
            
            
            if let discardPileRefs = record?[.discardPile] as? [CKRecord.Reference] {
                self?.loadCardsIntoDiscardPile(withReferences: discardPileRefs)
            }
            self?.openReqs -= 1
        }
    }
    
    /**
     Sets the local shared Phase10GameEngine's players array to contain Players matching records from the public iCloud database that have the input gameID.
     
     - Parameter gameID: String corresponding to the recordName for the Phase10Game that owns the players that should be returned
     */
    func loadPlayers(for gameID: String) {
        let reference = CKRecord.Reference(recordID: CKRecord.ID(recordName: gameID), action: .none)
        let pred = NSPredicate(format: "\(Phase10Player.Key.game) == %@", reference)
        let query = CKQuery(recordType: Phase10Player.recordType, predicate: pred)
        openReqs += 1
        CKContainer.default().publicCloudDatabase.perform(query, inZoneWith: nil) { (records, error) in
            self.openReqs -= 1
            records?.forEach { [weak self] record in
                if let hand = record[.hand] as? [CKRecord.Reference] {
                    let name = record[.name] as? String ?? ""
                    let phase = record[.phase] as? Int ?? 0
                    let index = record[.index] as? Int ?? 0
                    let player = Phase10Player(name: name, phase: phase, index: index)
                    self?.players.append(player)
                    self?.loadCards(for: player, withReferences: hand)
                }
            }
            
            self.players = self.players.sorted(by: self.playerSort)
        }
    }
    
    /**
     Sets the local shared Phase10GameEngine's deck to be the Deck record from the public iCloud database that matches the input gameID.
     
     - Parameter gameID: String corresponding to the recordName for the Phase10Game that owns the deck that should be returned
     */
    func loadDeck(for gameID: String) {
        let reference = CKRecord.Reference(recordID: CKRecord.ID(recordName: gameID), action: .none)
        let pred = NSPredicate(format: "\(Phase10Deck.Key.game) == %@", reference)
        let query = CKQuery(recordType: Phase10Deck.recordType, predicate: pred)
        openReqs += 1
        CKContainer.default().publicCloudDatabase.perform(query, inZoneWith: nil) { [weak self] (records, error) in
            records?.forEach { [weak self] record in
                self?.openReqs -= 1
                self?.deck.recordID = record.recordID
                if let deck = self?.deck,
                    let cards = record[.cards] as? [CKRecord.Reference] {
                    self?.loadCards(into: deck, withReferences: cards)
                }
            }
            
            // when all the cards in the deck are loaded we can deal
            if let player = self?.players.first(where: { $0.isGameOwner }) {
                self?.beginRoundForPlayer(player)
            }
        }
    }
    
    /**
     Returns a Phase10Card object, where possible, by parsing the description in the input Record.
     Ex: hand blue 9 --> a Phase10Card with color blue and number 9
     
     - Parameter record: CKRecord containing a description field that should be expanded to produce a Phase10Card
     */
    func card(from record: CKRecord) -> Phase10Card? {
        if let description = record[.description] as? String {
            let cardDesc = CardDescriptor(desc: "hand \(description)")
            
            if let type = cardDesc?.type,
                let color = cardDesc?.color {
                let card = Phase10Card(type, color: color)
                
                if let placeIndex = record[.placeIndex] as? Int {
                    card.placeIndex = placeIndex
                }
                
                
                return Phase10Card(type, color: color)
            }
        }
        return nil
    }
    
    /**
     Loads all the Card objects matching the input references from the public iCloud database into the input Phase10Deck
     
     - Parameters:
        - deck: Phase10Deck that should have all the cards corresponding to the input References loaded into it (This deck corresponds to the record id that holds these cards in the database)
        - references: Array of References to Phase10Cards that should be loaded into the input Phase10Deck
     */
    func loadCards(into deck: Phase10Deck, withReferences references: [CKRecord.Reference]) {
        openReqs += references.count
        for reference in references {
            CKContainer.default().publicCloudDatabase.fetch(withRecordID: reference.recordID) { [weak self] (record, error) in
                self?.openReqs -= 1
                if let record = record,
                    let card = self?.card(from: record) {
                    deck.cards.append(card)
                }
            }
        }
        
        deck.cards = deck.cards.sorted(by: cardSort)
    }
    
    /**
     Loads all the Card objects matching the input references from the public iCloud database into the local Phase10GameEngine.shared discardPile
     
     - Parameter references: Array of References to Phase10Cards that should be loaded into the local shared Phase10GameEngine discard Pile
     */
    func loadCardsIntoDiscardPile(withReferences references: [CKRecord.Reference]) {
        openReqs += references.count
        for reference in references {
            CKContainer.default().publicCloudDatabase.fetch(withRecordID: reference.recordID) { [weak self] (record, error) in
                self?.openReqs -= 1
                if let record = record,
                    let card = self?.card(from: record) {
                    self?.discardPile.append(card)
                }
            }
        }
        discardPile = discardPile.sorted(by: cardSort)
    }
    
    /**
     Loads all the Card objects matching the input references from the public iCloud database into the input players hand array.
     
     - Parameters:
        - player: Phase10Player who's hand of Phase10Cards should be loaded
        - references: Array of references to Phase10Cards that should be loaded into the input players hand array
     */
    func loadCards(for player: Phase10Player, withReferences references: [CKRecord.Reference]) {
        openReqs += references.count
        for reference in references {
            CKContainer.default().publicCloudDatabase.fetch(withRecordID: reference.recordID) { [weak self] (record, error) in
                self?.openReqs -= 1
                if let record = record,
                    let card = self?.card(from: record) {
                    player.hand.append(card)
                }
            }
        }
    }
    
    // MARK: - Private Functions
    
    /**
     Starts a new round of the game by setting a player's hand with 10 new cards from the deck. At the beginning of the game this will also set all players to Phase 0.
     This is expected to be called after 1 or more players has cleared the current Phase and a new round is beginning or directly at the beginning of the game.
     
     - Parameter player: The player who is starting a new round of the game
     */
    private func beginRoundForPlayer(_ player: Phase10Player) {
        if player.phase == nil {
            player.phase = Phase10GameEngine.generalReqs.first
        }
        
        if shouldDeal() {
            player.hand.append(contentsOf: deck.cards[0...9])
            deck.cards.removeSubrange(0...9)
        }
    }
    
    // Returns true if this device is permitted to deal cards, this happens when all invited players have joined and this is called on the device that created the game
    private func shouldDeal() -> Bool {
        return Phase10GameEngineManager.shared.isGameOwner && players.count == expectedNumberOfPlayers
    }
}
