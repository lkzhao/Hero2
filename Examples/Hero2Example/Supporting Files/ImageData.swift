//
//  ImageData
//  Hero2Example
//
//  Created by Luke Zhao on 8/2/21.
//  Copyright © 2021 Luke Zhao. All rights reserved.
//

import UIKit

struct ImageData {
  let id = UUID().uuidString
  let url: URL
  let size: CGSize
  
  static let testImages = [
    ImageData(url: URL(string: "https://unsplash.com/photos/Yn0l7uwBrpw/download?force=true&w=640")!,
              size: CGSize(width: 640, height: 360)),
    ImageData(url: URL(string: "https://unsplash.com/photos/J4-xolC4CCU/download?force=true&w=640")!,
              size: CGSize(width: 640, height: 800)),
    ImageData(url: URL(string: "https://unsplash.com/photos/biggKnv1Oag/download?force=true&w=640")!,
              size: CGSize(width: 640, height: 434)),
    ImageData(url: URL(string: "https://unsplash.com/photos/MR2A97jFDAs/download?force=true&w=640")!,
              size: CGSize(width: 640, height: 959)),
    ImageData(url: URL(string: "https://unsplash.com/photos/oaCnDk89aho/download?force=true&w=640")!,
              size: CGSize(width: 640, height: 426)),
    ImageData(url: URL(string: "https://unsplash.com/photos/MOfETox0bkE/download?force=true&w=640")!,
              size: CGSize(width: 640, height: 426)),
    ImageData(url: URL(string: "https://unsplash.com/photos/Yn0l7uwBrpw/download?force=true&w=640")!,
              size: CGSize(width: 640, height: 360)),
    ImageData(url: URL(string: "https://unsplash.com/photos/J4-xolC4CCU/download?force=true&w=640")!,
              size: CGSize(width: 640, height: 800)),
    ImageData(url: URL(string: "https://unsplash.com/photos/biggKnv1Oag/download?force=true&w=640")!,
              size: CGSize(width: 640, height: 434)),
    ImageData(url: URL(string: "https://unsplash.com/photos/MR2A97jFDAs/download?force=true&w=640")!,
              size: CGSize(width: 640, height: 959)),
    ImageData(url: URL(string: "https://unsplash.com/photos/oaCnDk89aho/download?force=true&w=640")!,
              size: CGSize(width: 640, height: 426)),
    ImageData(url: URL(string: "https://unsplash.com/photos/MOfETox0bkE/download?force=true&w=640")!,
              size: CGSize(width: 640, height: 426)),
  ]
}
