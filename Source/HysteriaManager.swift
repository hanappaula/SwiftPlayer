//
//  HysteriaManager.swift
//  Pods
//
//  Created by iTSangar on 1/15/16.
//
//

import UIKit
import Foundation
import MediaPlayer
import HysteriaPlayer

// MARK: - HysteriaManager
class HysteriaManager: NSObject {
  
  fileprivate static var instance: HysteriaManager?
  class var sharedInstance : HysteriaManager {
    if instance == nil {
      instance = HysteriaManager()
    }
    
    return instance!
  }
  lazy var hysteriaPlayer = HysteriaPlayer.sharedInstance()!
  
  var logs = true
  var queue = PlayerQueue()
  var delegate: SwiftPlayerDelegate?
  var controller: UIViewController?
  var queueDelegate: SwiftPlayerQueueDelegate?
  
  fileprivate var requestFromTouch = false
  fileprivate var lastIndexShuffle = -1
  fileprivate var fixIndexAfterNextRemoved = false
  fileprivate var lastHysteriaMainIndex = -1
  
  fileprivate override init() {
    super.init()
    initHysteriaPlayer()
  }
  
  fileprivate func initHysteriaPlayer() {
    hysteriaPlayer.delegate = self;
    hysteriaPlayer.datasource = self;
    hysteriaPlayer.enableMemoryCached(false)
  }
}

// MARK: - HysteriaManager - UI
extension HysteriaManager {
  fileprivate func currentTime() {
    hysteriaPlayer.addPeriodicTimeObserver(forInterval: CMTimeMake(100, 1000), queue: nil, using: {
      time in
      let totalSeconds = CMTimeGetSeconds(time)
      if HysteriaManager.instance != nil {
        self.delegate?.playerCurrentTimeChanged(Float(totalSeconds))
      }
    })
  }
  
  fileprivate func updateCurrentItem() {
    infoCenterWithTrack(currentItem())
    
    let duration = hysteriaPlayer.getPlayingItemDurationTime()
    if duration > 0.0 {
      delegate?.playerDurationTime(duration)
    }
  }
  
}


// MARK: - HysteriaManager - MPNowPlayingInfoCenter
extension HysteriaManager {
  
  func updateImageInfoCenter(_ image: UIImage) {
    if var dictionary = MPNowPlayingInfoCenter.default().nowPlayingInfo {
      dictionary[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(image: image)
    }
  }
  
  fileprivate func infoCenterWithTrack(_ track: PlayerTrack?) {
    guard let track = track else { return }
    if var dictionary = MPNowPlayingInfoCenter.default().nowPlayingInfo {
      
      dictionary[MPMediaItemPropertyPlaybackDuration] = TimeInterval((hysteriaPlayer.getPlayingItemDurationTime()))
      dictionary[MPNowPlayingInfoPropertyElapsedPlaybackTime] =  TimeInterval((hysteriaPlayer.getPlayingItemCurrentTime()))
      
      if let albumName = track.album?.name {
        dictionary[MPMediaItemPropertyAlbumTitle] = albumName
      }
      if let artistName = track.artist?.name {
        dictionary[MPMediaItemPropertyArtist] = artistName
      }
      if let name = track.name {
        dictionary[MPMediaItemPropertyTitle] = name
      }
      if let image = track.image,
        let loaded = imageFromString(image) {
        dictionary[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(image: loaded)
      }
      MPNowPlayingInfoCenter.default().nowPlayingInfo = dictionary
    } else {
      var dictionary: [String : AnyObject] = [
        MPMediaItemPropertyAlbumTitle: "" as AnyObject,
        MPMediaItemPropertyArtist: "" as AnyObject,
        MPMediaItemPropertyPlaybackDuration: TimeInterval(hysteriaPlayer.getPlayingItemDurationTime()) as AnyObject,
        MPMediaItemPropertyTitle: "" as AnyObject]
      
      if let albumName = track.album?.name {
        dictionary[MPMediaItemPropertyAlbumTitle] = albumName as AnyObject?
      }
      if let artistName = track.artist?.name {
        dictionary[MPMediaItemPropertyArtist] = artistName as AnyObject?
      }
      if let name = track.name {
        dictionary[MPMediaItemPropertyTitle] = name as AnyObject?
      }
      if let image = track.image,
        let loaded = imageFromString(image) {
        dictionary[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(image: loaded)
      }
      
      MPNowPlayingInfoCenter.default().nowPlayingInfo = dictionary
    }
  }
  
  fileprivate func imageFromString(_ imagePath: String) -> UIImage? {
    let detectorr = try! NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
    let matches = detectorr.matches(in: imagePath, options: [], range: NSMakeRange(0, imagePath.characters.count))
    
    for match in matches {
      let url = (imagePath as NSString).substring(with: match.range)
      if let data = try? Data(contentsOf: URL(string: url)!) {
        return UIImage(data: data)
      }
    }
    
    if let data = try? Data(contentsOf: URL(fileURLWithPath: imagePath)) {
      let image = UIImage(data: data)
      return image
    }
    
    return nil
  }
}

// MARK: - HysteriaManager - Actions
extension HysteriaManager {
  
  // Play Methods
  func play() {
    if !(hysteriaPlayer.isPlaying()) {
      hysteriaPlayer.play()
      updateCurrentItem()
    }
  }
  
  func playAtIndex(_ index: Int) {
    fetchAndPlayAtIndex(index)
  }
  
  func playAllTracks() {
    fetchAndPlayAtIndex(0)
  }
  
  func pause() {
    if (hysteriaPlayer.isPlaying()) {
      hysteriaPlayer.pause()
    }
  }
  
  func next() {
    hysteriaPlayer.playNext()
    play()
  }
  
  func previous() {
    if let index = currentIndex() {
      hysteriaPlayer.playPrevious()
    }
  }
  
  func stop() {
    hysteriaPlayer.deprecatePlayer()
    hysteriaPlayer = HysteriaPlayer.sharedInstance()!
    HysteriaManager.instance = nil
  }
  
  // Shuffle Methods
  func shuffleStatus() -> Bool {
    switch hysteriaPlayer.getShuffleMode() {
    case .on:
      return true
    case .off:
      return false
    }
  }
  
  func enableShuffle() {
    hysteriaPlayer.setPlayerShuffleMode(.on)
  }
  
  func disableShuffle() {
    hysteriaPlayer.setPlayerShuffleMode(.off)
    queue.setAllTracksPlayedFalse()
  }
  
  // Repeat Methods
  func repeatStatus() -> (Bool, Bool, Bool) {
    switch hysteriaPlayer.getRepeatMode() {
    case .on:
      return (true, false, false)
    case .once:
      return (false, true, false)
    case .off:
      return (false, false, true)
    }
  }
  
  func enableRepeat() {
    hysteriaPlayer.setPlayerRepeatMode(.on)
  }
  
  func enableRepeatOne() {
    hysteriaPlayer.setPlayerRepeatMode(.once)
  }
  
  func disableRepeat() {
    hysteriaPlayer.setPlayerRepeatMode(.off)
  }
  
  func seekTo(_ slider: UISlider) {
    let duration = hysteriaPlayer.getPlayingItemDurationTime()
    if duration.isFinite {
      let minValue = slider.minimumValue
      let maxValue = slider.maximumValue
      let value = slider.value
      let time = duration * (value - minValue) / (maxValue - minValue)
      hysteriaPlayer.seek(toTime: Double(time))
    }
  }
  
  func mute(_ mute: Bool) {
    hysteriaPlayer.mute(mute)
  }
  
  func isMuted() -> Bool {
    return hysteriaPlayer.isMuted()
  }
}


// MARK: - Hysteria Playlist
extension HysteriaManager {
  func setPlaylist(_ playlist: [PlayerTrack]) {
    var nPlaylist = [PlayerTrack]()
    for (index, track) in playlist.enumerated() {
      var nTrack = track
      nTrack.position = index
      nPlaylist.append(nTrack)
    }
    queue.mainQueue = nPlaylist
  }
  
  func addPlayNext(_ track: PlayerTrack) {
    if logs {print("• player track added :track >> \(track)")}
    var nTrack = track
    nTrack.origin = TrackType.next
    if let index = currentIndex() {
      queue.newNextTrack(nTrack, nowIndex: index)
      updateCount()
      fixIndexAfterNextRemoved = true
    }
    
  }
  
  fileprivate func addHistoryTrack(_ track: PlayerTrack) {
    queue.history.append(track)
  }
  
  func playMainAtIndex(_ index: Int) {
    if let qIndex = queue.indexToPlayAt(index) {
      fetchAndPlayAtIndex(qIndex)
      requestFromTouch = true
    }
    
  }
  
  func playNextAtIndex(_ index: Int) {
    if let qIndex = queue.indexToPlayNextAt(index) {
      updateCount()
      fetchAndPlayAtIndex(index)
    }
  }
  
  fileprivate func reorderHysteryaQueue() -> (_ from: Int, _ to: Int) -> Void {
    let closure: (_ from: Int, _ to: Int) -> Void = { from, to in
      self.hysteriaPlayer.moveItem(from: from, to: to)
    }
    return closure
  }
  
  func trackAtIndex(_ index: Int) -> PlayerTrack {
    if fixIndexAfterNextRemoved && !requestFromTouch {
      return queue.trackAtIndex(0)
    }
    return queue.trackAtIndex(index)
  }
  
  func currentTrack() -> PlayerTrack? {
    if let index = currentIndex() {
      if fixIndexAfterNextRemoved {
        if index == 0 {
          // First main track
          return queue.trackAtIndex(queue.nextQueue.count)
        }
      }
      return trackAtIndex(index)
    }
    return nil
  }
}


// MARK: - Hysteria Utils
extension HysteriaManager {
  fileprivate func updateCount() {
    hysteriaPlayer.itemsCount = hysteriaPlayerNumberOfItems()
  }
  
  fileprivate func currentItem() -> PlayerTrack? {
    if let index = currentIndex() {
      let track = trackAtIndex(index)
      addHistoryTrack(track)
      return track
    }else{
      let track = queue.trackAtIndex(0)
      addHistoryTrack(track)
      return track
    }
    return nil
  }
  
  func currentItem() -> AVPlayerItem! {
    return hysteriaPlayer.getCurrentItem()
  }
  
  func currentIndex() -> Int? {
    if let index = hysteriaPlayer.getHysteriaIndex(hysteriaPlayer.getCurrentItem()) {
      return Int(index)
    }
    return nil
  }
  
  fileprivate func fetchAndPlayAtIndex(_ index: Int) {
    hysteriaPlayer.fetchAndPlayPlayerItem(index)
  }
  
  func playingItemDurationTime() -> Float {
    return hysteriaPlayer.getPlayingItemDurationTime()
  }
  
  func volumeViewFrom(_ view: UIView) -> MPVolumeView! {
    let volumeView = MPVolumeView(frame: view.bounds)
    volumeView.showsRouteButton = false
    volumeView.showsVolumeSlider = true
    return volumeView
  }
}


// MARK: - HysteriaPlayerDataSource
extension HysteriaManager: HysteriaPlayerDataSource {
  func hysteriaPlayerNumberOfItems() -> Int {
    return queue.totalTracks()
  }
  
  func hysteriaPlayerAsyncSetUrlForItem(at index: Int, preBuffer: Bool) {
    if preBuffer { return }
    var newIndex = index
    
    queue.removeNextPlayedTracks()
    updateCount()
    
    // Make hysteria play next item (relative to last main item played) on main queue after next queue be empty
    if queue.nextQueue.isEmpty {
      if fixIndexAfterNextRemoved == true {
        fixIndexAfterNextRemoved = false
        if !requestFromTouch {
          fetchAndPlayAtIndex(lastHysteriaMainIndex + 1)
          return
        } else {
          // In case there was one item on next queue before 
          fetchAndPlayAtIndex(index - 1)
        }
      }
      lastHysteriaMainIndex = index
    }
    
    if shuffleStatus() == true {
      newIndex = queue.indexForShuffle()!
    }
    
    guard let track = queue.queueAtIndex(newIndex, shuffleEnabled: shuffleStatus(), requestFromTouch: requestFromTouch) else {
      fetchAndPlayAtIndex(index - 1)
      return
    }
    
    if track.origin == TrackType.next {
      queue.setNextTrackAsPlayed(track)
    }
    
    requestFromTouch = false
    
    hysteriaPlayer.setupPlayerItem(with: URL(string: track.url)!, index: index)
  }
}


// MARK: - HysteriaPlayerDelegate
extension HysteriaManager: HysteriaPlayerDelegate {
  
  func hysteriaPlayerWillChanged(at index: Int) {
    if logs {print("• player will changed :atindex >> \(index)")}
  }
  
  func hysteriaPlayerCurrentItemChanged(_ item: AVPlayerItem!) {
    if logs {print("• current item changed :item >> \(item)")}
    var trackl:PlayerTrack = currentItem()!
    delegate?.playerCurrentTrackChanged(trackl)
    queueDelegate?.queueUpdated()
    updateCurrentItem()
  }
  
  func hysteriaPlayerRateChanged(_ isPlaying: Bool) {
    if logs {print("• player rate changed :isplaying >> \(isPlaying)")}
    delegate?.playerRateChanged(isPlaying)
  }
  
  func hysteriaPlayerDidReachEnd() {
    if logs {print("• player did reach end")}
  }
  
  func hysteriaPlayerCurrentItemPreloaded(_ time: CMTime) {
    if logs {print("• current item preloaded :time >> \(CMTimeGetSeconds(time))")}
  }
  
  func hysteriaPlayerDidFailed(_ identifier: HysteriaPlayerFailed, error: NSError!) {
    if logs {print("• player did failed :error >> \(error.description)")}
    switch identifier {
    case .currentItem: next()
      break
    case .player:
      break
    }
  }
  
  func hysteriaPlayerReady(_ identifier: HysteriaPlayerReadyToPlay) {
    if logs {print("• player ready to play")}
    switch identifier {
    case .currentItem:
      updateCurrentItem()
      delegate?.playerReadyToPlay()
      break
    case .player: currentTime()
      break
    }
  }
  
  func hysteriaPlayerItemFailed(toPlayEndTime item: AVPlayerItem!, error: NSError!) {
    if logs {print("• item failed to play end time :error >> \(error.description)")}
    self.pause()
  }
  
  func hysteriaPlayerItemPlaybackStall(_ item: AVPlayerItem!) {
    if logs {print("• item playback stall :item >> \(item)")}
  }
  
  func hysteriaPlayerRouteChanged() {
    delegate?.playerRouteChanged()
  }
  
}
