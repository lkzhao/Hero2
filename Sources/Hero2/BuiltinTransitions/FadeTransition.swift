//
//  File.swift
//  
//
//  Created by Luke Zhao on 12/4/22.
//

import Foundation

public class FadeTransition: Transition {
    public override func animate() {
        guard let front = foregroundView else {
            fatalError()
        }
        addDismissStateBlock {
            front.alpha = 0
        }
        addPresentStateBlock {
            front.alpha = 1
        }
        addCompletionBlock { _ in
            front.alpha = 1
        }
    }
}
