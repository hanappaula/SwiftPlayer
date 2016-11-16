//
//  SwiftPlayerQueue.swift
//  Pods
//
//  Created by Ítalo Sangar on 4/8/16.
//
//

import Foundation

struct PlayerQueue {
  
  var history = [PlayerTrack]()
  var nextQueue = [PlayerTrack]()
  var mainQueue = [PlayerTrack]() {
    didSet {
      allTracks = mainQueue
      nextQueue = []
    }
  }
  
  fileprivate var allTracks = [PlayerTrack]()
  
  ///////////////////////////////////////////////
  func totalTracks() -> Int {
    return nextQueue.count + mainQueue.count
  }
  
  ///////////////////////////////////////////////
  mutating func newNextTrack(_ track: PlayerTrack, nowIndex: Int) {
    var tk = track
    tk.origin = TrackType.next
    nextQueue.insert(tk, at: 0)
    allTracks.insert(tk, at: 0)
    
    for (index, track) in nextQueue.enumerated() {
      nextQueue[index].position = index
    }
  }
  
  ///////////////////////////////////////////////
  mutating func queueAtIndex(_ index: Int, shuffleEnabled: Bool, requestFromTouch: Bool) -> PlayerTrack? {
    var newIndex = index
    if !shuffleEnabled && !requestFromTouch && allTracks[0].origin == TrackType.next {
        return allTracks[0]
    }
    
    // Prevent index out of range
    if newIndex == allTracks.count {
      newIndex -= 1
    } else if newIndex < 0 {
      newIndex = 0
    }
    return allTracks[newIndex]
  }
  
  ///////////////////////////////////////////////
  mutating func removeNextPlayedTracks() {
    for (index, track) in allTracks[0..<nextQueue.count].enumerated() where track.origin == TrackType.next {
      if track.played {
        allTracks.remove(at: index)
        nextQueue.remove(at: index)
      }
    }
  }
  
  ///////////////////////////////////////////////
  mutating func setNextTrackAsPlayed(_ track: PlayerTrack) {
    for (index, tk) in allTracks.enumerated() where tk.position == track.position && track.origin == TrackType.next {
      allTracks[index].played = true
      nextQueue[index].played = true
      break
    }
  }
  
  ///////////////////////////////////////////////
  mutating func indexForShuffle() -> Int? {
    var index = shuffleIndex()
    if index == nil {
      setAllTracksPlayedFalse()
      return shuffleIndex()
    }
    
    return index
  }
  
  ///////////////////////////////////////////////
  fileprivate mutating func shuffleIndex() -> Int? {
    var shuffleArray: [Int] = []
    for (index, track) in allTracks.enumerated() where track.played == false {
      shuffleArray.append(index)
    }
    
    if shuffleArray.count > 0 {
      var shuffleIndex = shuffleArray[Int(arc4random_uniform(UInt32(shuffleArray.count)))]
      allTracks[shuffleIndex].played = true
      return shuffleIndex
    } else {
      return nil
    }
  }
  
  ///////////////////////////////////////////////
  mutating func setAllTracksPlayedFalse() {
    for (index, track) in allTracks.enumerated() {
      allTracks[index].played = false
    }
  }
  
  ///////////////////////////////////////////////
  func indexToPlayAt(_ indexMain: Int) -> Int? {
    return indexMain + nextQueue.count
  }
  
  ///////////////////////////////////////////////
  mutating func indexToPlayNextAt(_ indexNext: Int) -> Int? {
    if indexNext != 0 {
      allTracks.removeSubrange(0..<indexNext)
      nextQueue.removeSubrange(0..<indexNext)
    }
    
    return 0
  }
  
  ///////////////////////////////////////////////
  func trackAtIndex(_ index: Int) -> PlayerTrack {
    if index < 0 {
      return allTracks[0]
    } else if index >= allTracks.count {
      return allTracks[allTracks.count - 1]
    } else {
      return allTracks[index]
    }
  }
}


extension Array {
  func shift(withDistance distance: IndexDistance = 1) -> Array<Element> {
    let index = distance >= 0 ?
      self.index(startIndex, offsetBy: distance, limitedBy: endIndex) :
      self.index(endIndex, offsetBy: distance, limitedBy: startIndex)
    
    return Array(self[index! ..< endIndex] + self[startIndex ..< index!])
  }
  
  mutating func shiftInPlace(withDistance distance: IndexDistance = 1) {
    self = shift(withDistance: distance)
  }
  
  mutating func moveItem(fromIndex oldIndex: Index, toIndex newIndex: Index) {
    insert(remove(at: oldIndex), at: newIndex)
  }
}
