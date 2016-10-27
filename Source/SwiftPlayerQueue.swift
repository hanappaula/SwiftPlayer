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
    nextQueue.insert(track, at: 0)
    allTracks.insert(track, at: nowIndex + 1)
  }
  
  ///////////////////////////////////////////////
  mutating func removeNextAtIndex(_ index: Int) {
    allTracks.remove(at: index)
    nextQueue.remove(at: 0)
  }
  
  ///////////////////////////////////////////////
  mutating func queueAtIndex(_ index: Int) -> PlayerTrack? {
    if allTracks.contains(where: { $0.origin == TrackType.next }) {
      if index > 0 && allTracks[index - 1].origin == TrackType.next {
        allTracks.remove(at: index - 1)
        nextQueue.remove(at: 0)
        return nil
      }
    }
    allTracks[index].played = true
    
    return allTracks[index]
  }
  
  ///////////////////////////////////////////////
  mutating func cleanAllTracksList(_ untilIndex: Int) {
    for (index, track) in allTracks[0..<(untilIndex + nextQueue.count + 1)].enumerated() where track.origin == TrackType.next {
      if track.played {
        allTracks.remove(at: index)
      }
    }
  }
  
  ///////////////////////////////////////////////
  func indexForShuffle() -> Int? {
    for (index, track) in allTracks.enumerated() where track.origin == TrackType.next {
      return index
    }
    return nil
  }
  
  ///////////////////////////////////////////////
  func indexToPlayAt(_ indexMain: Int) -> Int? {
    for (index, track) in allTracks.enumerated() where track.origin == TrackType.normal && track.position == indexMain {
      return index
    }
    return nil
  }
  
  ///////////////////////////////////////////////
  mutating func indexToPlayNextAt(_ indexNext: Int, nowIndex: Int) -> Int? {
    var indexOnQueue = 0
    var firstFound = 0
    var totalFound = 0
    
    for (index, track) in allTracks.enumerated() where track.origin == TrackType.next {
      firstFound = index
      indexOnQueue = index + indexNext
      break
    }
    
    for i in 0..<indexOnQueue {
      if allTracks[i].origin == TrackType.next {
        totalFound += 1
      }
    }
    
    if allTracks[nowIndex].origin == TrackType.next {
      firstFound += 1
      indexOnQueue += 1
    }
    
    allTracks.removeSubrange(firstFound...(indexOnQueue - 1))
    
    for _ in firstFound...(indexOnQueue - 1) {
      nextQueue.remove(at: 0)
    }
    
    return indexOnQueue - totalFound
  }
  
  ///////////////////////////////////////////////
  mutating func reorderQueuePrevious(_ nowIndex: Int, reorderHysteria: (_ from: Int, _ to: Int) -> Void) {
    if nowIndex <= 0 { return }
    
    var totalNext = 0
    for nTrack in allTracks where nTrack.origin == TrackType.next {
      totalNext += 1
    }
    
    while totalNext != 0 {
      for (index, track) in allTracks.reversed().enumerated() where track.origin == TrackType.next {
        let track = allTracks[((allTracks.count - 1) - index)]
        allTracks.moveItem(fromIndex: ((allTracks.count - 1) - index), toIndex: nowIndex + 1)
        reorderHysteria(((allTracks.count - 1) - index), nowIndex + 1)
        totalNext -= 1
        break
      }
    }
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
