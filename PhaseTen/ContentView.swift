//
//  ContentView.swift
//  PhaseTen
//
//  Created by Malcolm Goldiner on 4/2/20.
//  Copyright © 2020 Malcolm Goldiner. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        CardView(card: Phase10Card(.one, color: .red))
    }
}

struct CardView: View {
    @State var card: Phase10Card
    
    var backgroundColor: UIColor {
        return card.color ?? .white
    }
    
    var body: some View {
        HStack {
            Text("\(card.type.value())")
                .font(.system(size: 360))
                .foregroundColor(Color(card.color ?? .white))
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        CardView(card: Phase10Card(.one, color: .red))
    }
}
