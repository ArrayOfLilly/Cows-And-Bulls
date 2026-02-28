//
//  LearnView.swift
//  CowsAndBulls
//
//  Created by Ildikó Kasza on 2026. 02. 27..
//

import SwiftUI

struct LearnView: View {
    var body: some View {
        ScrollView {
            Text("Rules of Games")
                .font(Font.largeTitle)
                .padding()
            
        Text("Objective")
            .font(Font.title)
            .padding()
            
       Text("""
            The objective of the game is to guess a 4-digit number that the other player has in mind. You can ask up to 10 questions to try and guess the number.
            """)
                .font(.body)
                .padding()
            
            Text("Skills Learned")
                .font(Font.title)
                .padding()
            
            Text("""
                Logical Deduction – Narrowing possibilities based on feedback.
                Pattern Recognition – Identifying overlap between guesses.
                Strategic Guessing – Choosing guesses that eliminate the most options.
                Memory – Tracking which guesses have ruled out or confirmed symbols.
                """)
                .padding()
            
            Text("How to play")
                .font(Font.title)
                .padding()
            
            Text("""
                 The computer choose a sequence of digits (you can set the length between 3 and 8 digits) which the code-breaker cannot see.

                 Digits can be from 0–9. Decide if repeats are allowed, currently repeats are not allowed.
                 
                 Code-breaker makes the first guess.
                 """)
                .padding()
            
                 Text("For each guess:")
                .font(Font.title)
                .padding()
            
            VStack(alignment: .listRowSeparatorLeading) {
                HStack {
                    Text("Bull (🟢)")
                        .fontWeight(.bold)
                    Text("Correct digit in the correct position.")
                }
                .padding(5)
                HStack {
                    Text("Cow (⚪)")
                        .fontWeight(.bold)
                    Text("Correct digit in the wrong position.")
                }
            }

                Text("""
                 Keep track of which numbers have been confirmed or eliminated, and which positions might be correct.

                 The code-breaker keeps making guesses, one per turn, using feedback to narrow the possibilities.
                 
                 The code-breaker wins by matching the code exactly, in less round than the current limit is. (You can set the limit as you wish.)
                 """)
                .padding()
                .font(.body)
            
            Text("Scoring:")
                .font(Font.title)
                .padding()
            
            Text("""
                First guess: 100 point.
                Number of guesses are between 1 <= 0.5 max guesses: 25 point, 
                0.5 max guesses <= 0.625 max guesses: 20 point,
                0.625 max guesses <= 0.75 max guesses: 15 point,
                0.75 max guesses <= 0.9 max guesses: 10 point,
                0.9 max guesses <= max guesses: 5 point,
                Last possible try: 1 point.
                          
                Score is multiplied by the answer length.
                
                If hard mode is enabled, scores are doubled.
                """)
            .padding()
            .font(.body)
            
            Text("Enjoy the game!")
                .font(.title)
                .padding()
            
            
        }
        .padding(20)
        .frame(maxWidth: 500)
    }
}

#Preview {
    LearnView()
}
