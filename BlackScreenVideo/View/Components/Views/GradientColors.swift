//
//  Gradient.swift
//  BalotCalculator
//
//  Created by Yahya A Shawish on 01/01/2025.
//
import SwiftUI
struct GradientColors {
    static let startGameButtonGradient : LinearGradient = LinearGradient(stops: [
        Gradient.Stop(color: Color("gradiantTop"), location: 0.3),
        Gradient.Stop(color: Color("gradiantBtm"), location: 0.70),
    ], startPoint: .top, endPoint: .bottom)
    
    static let teamWinnerGradient : LinearGradient = LinearGradient(colors: [Color.white,Color("winGradient")]
    , startPoint: .top, endPoint: .bottom)
    
    
}
