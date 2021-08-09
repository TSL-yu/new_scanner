//
//  LibraryCollectionViewCell.swift
//  LidarScanner
//
//  Created by Peter Tam on 4/9/21.
//

import UIKit
import SwipeCellKit

class LibraryCollectionViewCell: SwipeCollectionViewCell {
    @IBOutlet weak var modelTitle: UILabel!
    @IBOutlet weak var modelImage: UIImageView!
    @IBOutlet weak var date: UILabel!
}
