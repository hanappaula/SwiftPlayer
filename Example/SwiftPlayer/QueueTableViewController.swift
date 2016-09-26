//
//  QueueTableViewController.swift
//  SwiftPlayer
//
//  Created by Ítalo Sangar on 4/18/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import UIKit
import SwiftPlayer
import AlamofireImage

// MARK: - Section Enum

enum TrackSection: Int {
  case nowPlaying = 0
  case next = 1
  case resume = 2
  
  var sections: Int {
    return isNext ? 3 : 2
  }
  
  var rows: Int {
    switch self {
    case .nowPlaying:
      return 1
    case .next:
      return isNext ? SwiftPlayer.nextTracks().count : SwiftPlayer.mainTracks().count
    case .resume:
      return SwiftPlayer.mainTracks().count
    }
  }
  
  var title: String {
    switch self {
    case .nowPlaying:
      return "  NOW PLAYING"
    case .next:
      let songs = SwiftPlayer.nextTracks().count > 1 ? "SONGS" : "SONG"
      return isNext ? "  UP NEXT: \(SwiftPlayer.nextTracks().count) \(songs)" : "  UP NEXT: FROM \(albumName)"
    case .resume:
      return "  RESUME: \(albumName)"
    }
  }
  
  func value(_ row: Int) -> PlayerTrack? {
    switch self {
    case .nowPlaying:
      if let index = SwiftPlayer.currentTrackIndex() {
        return SwiftPlayer.trackAtIndex(index)
      }
      return nil
    case .next:
      return isNext ? SwiftPlayer.nextTracks()[row] : SwiftPlayer.mainTracks()[row]
    case .resume:
      return SwiftPlayer.mainTracks()[row]
    }
  }
  
  func selected(_ row: Int) {
    switch self {
    case .nowPlaying:
      break
    case .next:
      if isNext {
        SwiftPlayer.playNextAtIndex(row)
      } else {
        SwiftPlayer.playMainAtIndex(row)
      }
      break
    case .resume:
      SwiftPlayer.playMainAtIndex(row)
      break
    }
  }
  
  fileprivate var albumName: String {
    if let name = SwiftPlayer.mainTracks()[0].album?.name {
      return name.uppercased()
    } else {
      return "Any Album".uppercased()
    }
  }
  
  fileprivate var isNext: Bool {
    return SwiftPlayer.nextTracks().count > 0
  }

}

// MARK: - ViewController

class QueueTableViewController: UITableViewController {
  
  var sectionStatus = TrackSection.nowPlaying
  
  override func viewDidLoad() {
    super.viewDidLoad()
    tableView.reloadData()
    SwiftPlayer.queueDelegate(self)
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
  }
  
  // MARK: Table view data source
  
  override func numberOfSections(in tableView: UITableView) -> Int {
    return sectionStatus.sections
  }
  
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    sectionStatus = TrackSection.init(rawValue: section)!
    return sectionStatus.rows
  }
  
  override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    sectionStatus = TrackSection.init(rawValue: section)!
    return sectionStatus.title
  }
  
  override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
    let header = view as! UITableViewHeaderFooterView
    header.textLabel?.font = UIFont.systemFont(ofSize: 12, weight: UIFontWeightRegular)
    view.tintColor = UIColor.lightGray.withAlphaComponent(0.7)
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    return tableView.dequeueReusableCell(withIdentifier: "QueueTableViewCell", for: indexPath) as! QueueTableViewCell
  }
  
  // MARK: Table view delegate
  
  override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
    if cell.responds(to: #selector(setter: UIView.preservesSuperviewLayoutMargins)) {
      cell.layoutMargins = UIEdgeInsets.zero
      cell.preservesSuperviewLayoutMargins = false
    }
    
    let cell = cell as! QueueTableViewCell
    sectionStatus = TrackSection.init(rawValue: (indexPath as NSIndexPath).section)!
    cell.track = sectionStatus.value(indexPath.row)
  }
  
  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    sectionStatus = TrackSection.init(rawValue: (indexPath as NSIndexPath).section)!
    sectionStatus.selected((indexPath as NSIndexPath).row)
  }
  
}


extension QueueTableViewController: SwiftPlayerQueueDelegate {
  func queueUpdated() {
    tableView.reloadData()
  }
}
