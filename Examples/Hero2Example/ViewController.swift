//
//  ViewController.swift
//  Hero2Example
//
//  Created by Luke Zhao on 2018-12-13.
//  Copyright © 2018 Luke Zhao. All rights reserved.
//

import Hero2
import UIComponent
import UIKit

class ViewController: ComponentViewController {
    override var component: Component {
        VStack {
            ExampleSection(title: "Hero Transition") {
                ExampleItem(name: "Match", viewController: MatchViewController())
                ExampleItem(name: "Bubble", viewController: BubbleViewController())
                ExampleItem(name: "Push", viewController: PushViewController())
                ExampleItem(name: "ImageGallery", viewController: ImageGalleryViewController())
            }
            ExampleSection(title: "Match Modal Transition") {
                ExampleItem(name: "Instagram", viewController: InstagramViewController())
            }
            ExampleSection(title: "Sheet Transition") {
                ExampleItem(name: "Sheet", shouldPresent: true, viewController: SheetViewController())
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Hero2 Examples"
    }
}

struct ExampleItem: ComponentBuilder {
    let name: String
    let shouldPresent: Bool
    let viewController: () -> UIViewController
    init(name: String, shouldPresent: Bool = false, viewController: @autoclosure @escaping () -> UIViewController) {
        self.name = name
        self.shouldPresent = shouldPresent
        self.viewController = viewController
    }
    func build() -> Component {
        VStack {
            Text(name)
        }
        .inset(16)
        .tappableView {
            let vc = viewController()
            if shouldPresent {
                $0.present(vc)
            } else {
                $0.push(vc)
            }
        }
    }
}

struct ExampleSection: ComponentBuilder {
    let title: String
    let children: [Component]
    init(title: String, @ComponentArrayBuilder _ content: () -> [Component]) {
        self.title = title
        self.children = content()
    }
    func build() -> Component {
        VStack {
            Text(title, font: .boldSystemFont(ofSize: 14)).inset(top: 30, left: 16, bottom: 10, right: 16)
            Separator()
            Join {
                for child in children {
                    child
                }
            } separator: {
                Separator()
            }
        }
    }
}
