//
//  SwiftPlayer.swift
//  Pods
//
//  Created by iTSangar on 1/14/16.
//
//

import Foundation
import MediaPlayer

// MARK: - SwiftPlayer Delegate -
public protocol SwiftPlayerDelegate: class {
  func playerDurationTime(_ time: Float)
  func playerCurrentTimeChanged(_ time: Float)
  func playerRateChanged(_ isPlaying: Bool)
  func playerCurrentTrackChanged(_ track: PlayerTrack?)
  func playerReadyToPlay()
  func playerRouteChanged()
}

extension SwiftPlayerDelegate {
  func playerDurationTime(_ time: Float) {}
  func playerCurrentTimeChanged(_ time: Float) {}
  func playerRateChanged(_ isPlaying: Bool) {}
  func playerCurrentTrackChanged(_ track: PlayerTrack?) {}
  func playerRouteChanged() {}
}

// MARK: - SwiftPlayer Queue Delegate -
public protocol SwiftPlayerQueueDelegate: class {
  func queueUpdated()
}

extension SwiftPlayerQueueDelegate {
  func queueUpdated() {}
}


// MARK: - SwiftPlayer Struct -
/// Struct to access player actions 🎵
public struct SwiftPlayer {
  
  /// Set logs
  public static func logs(_ active: Bool) {
    HysteriaManager.sharedInstance.logs = active
  }
  
  /// Set delegate
  public static func delegate(_ delegate: SwiftPlayerDelegate) {
    HysteriaManager.sharedInstance.delegate = delegate
  }
  
  /// Set ViewController
  public static func controller(_ controller: UIViewController?) {
    HysteriaManager.sharedInstance.controller = controller
  }
  
  // Get ViewController
  public static func playerController() -> UIViewController? {
    return HysteriaManager.sharedInstance.controller
  }
  
  /// ▶️ Play music
  public static func play() {
    HysteriaManager.sharedInstance.play()
  }
  
  /// ▶️🔢 Play music by specified index
  public static func playAtIndex(_ index: Int) {
    HysteriaManager.sharedInstance.playAtIndex(index)
  }
  
  /// ▶️0️⃣ Play all tracks starting by 0
  public static func playAll() {
    HysteriaManager.sharedInstance.playAllTracks()
  }
  
  /// ⏸ Pause music if music is playing
  public static func pause() {
    HysteriaManager.sharedInstance.pause()
  }
  
  /// ⏩ Play next music
  public static func next() {
    HysteriaManager.sharedInstance.next()
  }
  
  /// ⏪ Play previous music
  public static func previous() {
    do {
      HysteriaManager.sharedInstance.pause()
      var currentTime:CMTime
      currentTime = HysteriaManager.sharedInstance.currentItem().currentTime()
      NSLog("seconds = %f", CMTimeGetSeconds(currentTime));
      
      if CMTimeGetSeconds(currentTime) > 5.0 {
        HysteriaManager.sharedInstance.currentItem().seek(to: kCMTimeZero)
        HysteriaManager.sharedInstance.play()
      }else{
        HysteriaManager.sharedInstance.previous()
      }
    } catch {
      print("Something went wrong!")
    }
  }
  
  public static func stop() {
    HysteriaManager.sharedInstance.stop()
  }
  
  /// Mute audio
  public static func mute(_ mute: Bool) {
    HysteriaManager.sharedInstance.mute(mute)
  }
  
  public static func isMuted() -> Bool {
    return HysteriaManager.sharedInstance.isMuted()
  }
  
  /// Return true if sound is playing
  public static func isPlaying() -> Bool {
    return HysteriaManager.sharedInstance.hysteriaPlayer.isPlaying()
  }
  
  /// 🔀 Enable the player shuffle
  public static func enableShufle() {
    HysteriaManager.sharedInstance.enableShuffle()
  }
  
  /// Disable player shuffle
  public static func disableShuffle() {
    HysteriaManager.sharedInstance.disableShuffle()
  }
  
  /// Return true if 🔀 shuffle is enable
  public static func isShuffle() -> Bool {
    return HysteriaManager.sharedInstance.shuffleStatus()
  }
  
  /// 🔁 Enable repeat mode on music list
  public static func enableRepeat() {
    HysteriaManager.sharedInstance.enableRepeat()
  }
  
  /// 🔂 Enable repeat mode only in actual music
  public static func enableRepeatOne() {
    HysteriaManager.sharedInstance.enableRepeatOne()
  }
  
  /// Disable repeat mode
  public static func disableRepeat() {
    HysteriaManager.sharedInstance.disableRepeat()
  }
  
  /// Return true if 🔁 repeat or 🔂 repeatOne is enable
  public static func isRepeat() -> Bool {
    let (_, _, Off) = HysteriaManager.sharedInstance.repeatStatus()
    return !Off
  }
  
  /// Return true if 🔂 repeatOne is enable
  public static func isRepeatOne() -> Bool {
    let (_, One, _) = HysteriaManager.sharedInstance.repeatStatus()
    return One
  }
  
  /// 🔘 Set new seek value from UISlider
  public static func seekToWithSlider(_ slider: UISlider) {
    HysteriaManager.sharedInstance.seekTo(slider)
  }
  
  /// Get duration time of track
  public static func trackDurationTime() -> Float {
    return HysteriaManager.sharedInstance.playingItemDurationTime()
  }
  
  /// 🔊 Player volume view
  public static func volumeViewFrom(_ view: UIView) -> MPVolumeView {
    return HysteriaManager.sharedInstance.volumeViewFrom(view)
  }
  
  // MARK: QUEUE
  
  /// Set new playlist in player
  public static func newPlaylist(_ playlist: [PlayerTrack]) -> SwiftPlayer.Type {
    HysteriaManager.sharedInstance.setPlaylist(playlist)
    return self
  }
  
  /// Set queue delegate
  public static func queueDelegate(_ delegate: SwiftPlayerQueueDelegate) {
    HysteriaManager.sharedInstance.queueDelegate = delegate
  }
  
  /// Add new track in next queue
  public static func addNextTrack(_ track: PlayerTrack) {
    HysteriaManager.sharedInstance.addPlayNext(track)
  }
  
  /// Total tracks in playlists
  public static func totalTracks() -> Int {
    return HysteriaManager.sharedInstance.queue.totalTracks()
  }
  
  /// Tracks in main queue
  public static func mainTracks() -> [PlayerTrack] {
    return HysteriaManager.sharedInstance.queue.mainQueue
  }
  
  /// Tracks without playing track in next queue
  public static func nextTracks() -> [PlayerTrack] {
    var nextTracks = HysteriaManager.sharedInstance.queue.nextQueue
    if !nextTracks.isEmpty {
      if let currentTrack = currentTrack() {
        if currentTrack.origin == TrackType.next {
          nextTracks.removeFirst()
        }
      }
    }
    
    return nextTracks
  }
  
  /// All tracks by index
  public static func trackAtIndex(_ index: Int) -> PlayerTrack {
    return HysteriaManager.sharedInstance.trackAtIndex(index)
  }
  
  /// Current AVPlayerItem
  public static func currentTrack() -> PlayerTrack? {
    return HysteriaManager.sharedInstance.currentTrack()
  }
  
  /// Current index of playlist
  public static func currentTrackIndex() -> Int? {
    return HysteriaManager.sharedInstance.currentIndex()
  }
  
  /// Play music from main queue by specified index
  public static func playMainAtIndex(_ index: Int) {
    HysteriaManager.sharedInstance.playMainAtIndex(index)
  }
  
  /// Play music from next queue by specified index
  public static func playNextAtIndex(_ index: Int) {
    HysteriaManager.sharedInstance.playNextAtIndex(index)
  }
}
