//
//  QueueTableViewCell.swift
//  SwiftPlayer
//
//  Created by Ítalo Sangar on 4/18/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import UIKit
import SwiftPlayer

class QueueTableViewCell: UITableViewCell {
  
  @IBOutlet var coverImage: UIImageView!
  @IBOutlet var trackName: UILabel!
  @IBOutlet var artistName: UILabel!
  
  var track: PlayerTrack? {
    didSet {
      
      
      trackName.text = track?.name
      
      if let artist = track?.artist?.name {
        if let album = track?.album?.name {
          artistName.text = artist + " — " + album
        }
      }
      
      if let image = track?.image {
        coverImage.af_setImage(withURL: URL(string: image)!)
      }
    }
  }
  
  override func setSelected(_ selected: Bool, animated: Bool) {
    super.setSelected(selected, animated: animated)
    // Configure the view for the selected state
  }
}
