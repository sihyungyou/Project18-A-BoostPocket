//
//  CountryCell.swift
//  BoostPocket
//
//  Created by 송주 on 2020/11/19.
//  Copyright © 2020 BoostPocket. All rights reserved.
//

import UIKit
import FlagKit

class CountryCell: UITableViewCell {
    static let identifier = "CountryCell"

    @IBOutlet weak var countryNameLabel: UILabel!
    @IBOutlet weak var countryFlagImageView: UIImageView!
    
    var countryItemViewModel: CountryItemPresentable! {
        didSet {
            countryNameLabel.text = countryItemViewModel.name
            if let flagImage = UIImage(data: countryItemViewModel.flag) {
                countryFlagImageView.image = flagImage
            }
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.accessoryType = .none
    }
}
