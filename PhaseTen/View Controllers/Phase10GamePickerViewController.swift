//
//  Phase10GamePickerViewController.swift
//  PhaseTen
//
//  Created by Malcolm Goldiner on 6/13/20.
//  Copyright © 2020 Malcolm Goldiner. All rights reserved.
//

import UIKit
import CloudKit

class Phase10GamePickerViewController: UIViewController {
    
    @IBOutlet weak var gameNameLabel: UILabel!
    
    @IBOutlet weak var gameIDTextField: UITextField!
    
    @IBOutlet weak var joinGameButton: UIButton!
    
    @IBOutlet weak var newGameButton: UIButton!
    
    @IBOutlet weak var noAccountLabel: UILabel! {
        didSet {
            CKContainer.default().accountStatus { [weak self] (status, error) in
                DispatchQueue.main.async {
                    if status == .noAccount {
                        self?.newGameButton.isHidden = true
                        self?.joinGameButton.isHidden = true
                        self?.noAccountLabel.isHidden = false
                        self?.gameIDTextField.isEnabled = false
                    } else {
                        self?.noAccountLabel.isHidden = true
                    }
                }
                
                
            }
        }
    }
    
    @IBAction func joinGamePressed(_ sender: UIButton) {
        guard let id = gameIDTextField.text else {
            return
        }
        
        Phase10GameEngine.shared.loadGame(for: id)
        Phase10GameEngine.shared.loadPlayers(for: id)
        Phase10GameEngine.shared.loadDeck(for: id)
        
        Phase10GameEngineManager.shared.isOriginatingUser = false 
        
        performSegue(withIdentifier: "beginGameSegue", sender: nil)
    }
    
    @IBAction func newGamePressed(_ sender: UIButton) {
    }
    
}
