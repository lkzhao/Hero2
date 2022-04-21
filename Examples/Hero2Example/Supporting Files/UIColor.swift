//
//  ComponentBuilderExample.swift
//  Hero2Example
//
//  Created by Luke Zhao on 8/23/20.
//  Copyright © 2020 Luke Zhao. All rights reserved.
//

import Hero2
import UIKit

extension UIColor {
    static let systemColors: [UIColor] = [
        .systemRed, .systemBlue, .systemPink, .systemTeal, .systemGray, .systemFill, .systemGreen, .systemGreen,
        .systemYellow, .systemPurple, .systemOrange,
    ]
    static func randomSystemColor() -> UIColor {
        systemColors.randomElement()!
    }
}
