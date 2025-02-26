//
//  NetfilmPlayer.swift
//  Pods
//
//  Created by BrikerMan on 16/4/28.
//
//

import UIKit
import SnapKit
import MediaPlayer

/// NetfilmPlayerDelegate to obserbe player state
public protocol NetfilmPlayerDelegate : AnyObject {
    func NetfilmPlayer(player: NetfilmPlayer, playerStateDidChange state: NetfilmPlayerState)
    func NetfilmPlayer(player: NetfilmPlayer, loadedTimeDidChange loadedDuration: TimeInterval, totalDuration: TimeInterval)
    func NetfilmPlayer(player: NetfilmPlayer, playTimeDidChange currentTime : TimeInterval, totalTime: TimeInterval)
    func NetfilmPlayer(player: NetfilmPlayer, playerIsPlaying playing: Bool)
    func NetfilmPlayer(player: NetfilmPlayer, playerOrientChanged isFullscreen: Bool)
}

/**
 internal enum to check the pan direction
 
 - horizontal: horizontal
 - vertical:   vertical
 */
enum NetfilmPanDirection: Int {
    case horizontal = 0
    case vertical   = 1
}

open class NetfilmPlayer: UIView {
    
    open weak var delegate: NetfilmPlayerDelegate?
    
    open var backBlock:((Bool) -> Void)?
    
    /// Gesture to change volume / brightness
    open var panGesture: UIPanGestureRecognizer!
    
    /// AVLayerVideoGravityType
    open var videoGravity = AVLayerVideoGravity.resizeAspect {
        didSet {
            self.playerLayer?.videoGravity = videoGravity
        }
    }
    
    open var isPlaying: Bool {
        get {
            return playerLayer?.isPlaying ?? false
        }
    }
    
    //Closure fired when play time changed
    open var playTimeDidChange:((TimeInterval, TimeInterval) -> Void)?

    //Closure fired when play state chaged
    @available(*, deprecated, message: "Use newer `isPlayingStateChanged`")
    open var playStateDidChange:((Bool) -> Void)?

    open var playOrientChanged:((Bool) -> Void)?

    open var isPlayingStateChanged:((Bool) -> Void)?

    open var playStateChanged:((NetfilmPlayerState) -> Void)?
    
    open var avPlayer: AVPlayer? {
        return playerLayer?.player
    }
    
    open var playerLayer: NetfilmPlayerLayerView?
    
    fileprivate var resource: NetfilmPlayerResource!
    
    fileprivate var currentDefinition = 0
    
    fileprivate var controlView: NetfilmPlayerControlView!
    
    fileprivate var customControlView: NetfilmPlayerControlView?
    
    fileprivate var isFullScreen:Bool {
        get {
            return UIApplication.shared.statusBarOrientation.isLandscape
        }
    }
    
    /// 滑动方向
    fileprivate var panDirection = NetfilmPanDirection.horizontal
    
    /// 音量滑竿
    fileprivate var volumeViewSlider: UISlider!
    
    fileprivate let NetfilmPlayerAnimationTimeInterval: Double             = 4.0
    fileprivate let NetfilmPlayerControlBarAutoFadeOutTimeInterval: Double = 0.5
    
    /// 用来保存时间状态
    fileprivate var sumTime         : TimeInterval = 0
    open var totalDuration   : TimeInterval = 0
    fileprivate var currentPosition : TimeInterval = 0
    fileprivate var shouldSeekTo    : TimeInterval = 0
    
    fileprivate var isURLSet        = false
    fileprivate var isSliderSliding = false
    fileprivate var isPauseByUser   = false
    fileprivate var isVolume        = false
    fileprivate var isMaskShowing   = false
    fileprivate var isSlowed        = false
    fileprivate var isMirrored      = false
    fileprivate var isPlayToTheEnd  = false
    //视频画面比例
    fileprivate var aspectRatio: NetfilmPlayerAspectRatio = .default
    
    //Cache is playing result to improve callback performance
    fileprivate var isPlayingCache: Bool? = nil
    
    // MARK: - Public functions
    open var isMovie: Bool = false
    /**
     Play
     
     - parameter resource:        media resource
     - parameter definitionIndex: starting definition index, default start with the first definition
     */
    open func setVideo(resource: NetfilmPlayerResource, definitionIndex: Int = 0) {
        isURLSet = false
        self.resource = resource
        self.isMovie = false
        
        currentDefinition = definitionIndex
        controlView.prepareUI(for: resource, selectedIndex: definitionIndex)
        
        if NetfilmPlayerConf.shouldAutoPlay {
            isURLSet = true
            let asset = resource.definitions[definitionIndex]
            playerLayer?.playAsset(asset: asset.avURLAsset)
        } else {
            controlView.showCover(url: resource.cover)
            controlView.hideLoader()
        }
    }
    
    open func setVideoForMovie(resource: NetfilmPlayerResource, definitionIndex: Int = 0) {
        isURLSet = false
        self.resource = resource
        self.isMovie = true
        
        currentDefinition = definitionIndex
        controlView.prepareUI(for: resource, selectedIndex: definitionIndex)
        
        if NetfilmPlayerConf.shouldAutoPlay {
            isURLSet = true
            let asset = resource.definitions[definitionIndex]
            playerLayer?.playAsset(asset: asset.avURLAsset)
        } else {
            controlView.showCover(url: resource.cover)
            controlView.hideLoader()
        }
    }
    
    /**
     auto start playing, call at viewWillAppear, See more at pause
     */
    open func autoPlay() {
        if !isPauseByUser && isURLSet && !isPlayToTheEnd {
            play()
        }
    }
    
    /**
     Play
     */
    open func play() {
        guard resource != nil else { return }
        
        if !isURLSet {
            let asset = resource.definitions[currentDefinition]
            playerLayer?.playAsset(asset: asset.avURLAsset)
            controlView.hideCoverImageView()
            isURLSet = true
        }
        
        panGesture.isEnabled = true
        playerLayer?.play()
        isPauseByUser = false
    }
    
    /**
     Pause
     
     - parameter allow: should allow to response `autoPlay` function
     */
    open func pause(allowAutoPlay allow: Bool = false) {
        playerLayer?.pause()
        isPauseByUser = !allow
    }
    
    /**
     seek
     
     - parameter to: target time
     */
    open func seek(_ to: TimeInterval, completion: (@Sendable () -> Void)? = nil) {
        playerLayer?.seek(to: to, completion: completion)
    }

    
    /**
     update UI to fullScreen
     */
    open func updateUI(_ isFullScreen: Bool) {
        controlView.updateUI(isFullScreen)
    }
    
    /**
     increade volume with step, default step 0.1
     
     - parameter step: step
     */
    open func addVolume(step: Float = 0.1) {
        self.volumeViewSlider.value += step
    }
    
    /**
     decreace volume with step, default step 0.1
     
     - parameter step: step
     */
    open func reduceVolume(step: Float = 0.1) {
        self.volumeViewSlider.value -= step
    }
    
    /**
     prepare to dealloc player, call at View or Controllers deinit funciton.
     */
    open func prepareToDealloc() {
        playerLayer?.prepareToDeinit()
        controlView.prepareToDealloc()
    }
    
    /**
     If you want to create NetfilmPlayer with custom control in storyboard.
     create a subclass and override this method.
     
     - return: costom control which you want to use
     */
    open func storyBoardCustomControl() -> NetfilmPlayerControlView? {
        return nil
    }
    
    // MARK: - Action Response
    
    @objc fileprivate func panDirection(_ pan: UIPanGestureRecognizer) {
//        // 根据在view上Pan的位置，确定是调音量还是亮度
//        let locationPoint = pan.location(in: self)
//        
//        // 我们要响应水平移动和垂直移动
//        // 根据上次和本次移动的位置，算出一个速率的point
//        let velocityPoint = pan.velocity(in: self)
//        
//        // 判断是垂直移动还是水平移动
//        switch pan.state {
//        case UIGestureRecognizer.State.began:
//            // 使用绝对值来判断移动的方向
//            let x = abs(velocityPoint.x)
//            let y = abs(velocityPoint.y)
//            
//            if x > y {
//                if NetfilmPlayerConf.enablePlaytimeGestures {
//                    self.panDirection = NetfilmPanDirection.horizontal
//                    
//                    // 给sumTime初值
//                    if let player = playerLayer?.player {
//                        let time = player.currentTime()
//                        self.sumTime = TimeInterval(time.value) / TimeInterval(time.timescale)
//                    }
//                }
//            } else {
//                self.panDirection = NetfilmPanDirection.vertical
//                if locationPoint.x > self.bounds.size.width / 2 {
//                    self.isVolume = true
//                } else {
//                    self.isVolume = false
//                }
//            }
//            
//        case UIGestureRecognizer.State.changed:
//            switch self.panDirection {
//            case NetfilmPanDirection.horizontal:
//                self.horizontalMoved(velocityPoint.x)
//            case NetfilmPanDirection.vertical:
//                self.verticalMoved(velocityPoint.y)
//            }
//            
//        case UIGestureRecognizer.State.ended:
//            // 移动结束也需要判断垂直或者平移
//            // 比如水平移动结束时，要快进到指定位置，如果这里没有判断，当我们调节音量完之后，会出现屏幕跳动的bug
//            switch (self.panDirection) {
//            case NetfilmPanDirection.horizontal:
//                controlView.hideSeekToView()
//                isSliderSliding = false
//                if isPlayToTheEnd {
//                    isPlayToTheEnd = false
//                    seek(self.sumTime, completion: {[weak self] in
//                        self?.play()
//                    })
//                } else {
//                    seek(self.sumTime, completion: {[weak self] in
//                        self?.autoPlay()
//                    })
//                }
//                // 把sumTime滞空，不然会越加越多
//                self.sumTime = 0.0
//                
//            case NetfilmPanDirection.vertical:
//                self.isVolume = false
//            }
//        default:
//            break
//        }
    }
    
    fileprivate func verticalMoved(_ value: CGFloat) {
        if NetfilmPlayerConf.enableVolumeGestures && self.isVolume{
            self.volumeViewSlider.value -= Float(value / 10000)
        }
        else if NetfilmPlayerConf.enableBrightnessGestures && !self.isVolume{
            UIScreen.main.brightness -= value / 10000
        }
    }
    
    fileprivate func horizontalMoved(_ value: CGFloat) {
//        guard NetfilmPlayerConf.enablePlaytimeGestures else { return }
//        
//        isSliderSliding = true
//        if let playerItem = playerLayer?.playerItem {
//            // 每次滑动需要叠加时间，通过一定的比例，使滑动一直处于统一水平
//            self.sumTime = self.sumTime + TimeInterval(value) / 100.0 * (TimeInterval(self.totalDuration)/400)
//            
//            let totalTime = playerItem.duration
//            
//            // 防止出现NAN
//            if totalTime.timescale == 0 { return }
//            
//            let totalDuration = TimeInterval(totalTime.value) / TimeInterval(totalTime.timescale)
//            if (self.sumTime >= totalDuration) { self.sumTime = totalDuration }
//            if (self.sumTime <= 0) { self.sumTime = 0 }
//            
//            controlView.showSeekToView(to: sumTime, total: totalDuration, isAdd: value > 0)
//        }
    }
    
    @objc open func onOrientationChanged() {
        self.updateUI(isFullScreen)
        delegate?.NetfilmPlayer(player: self, playerOrientChanged: isFullScreen)
        playOrientChanged?(isFullScreen)
    }
    
    // I don't need it anymore.
//    @objc fileprivate func fullScreenButtonPressed() {
//        controlView.updateUI(!self.isFullScreen)
//        if isFullScreen {
//            UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
//            UIApplication.shared.setStatusBarHidden(false, with: .fade)
//            UIApplication.shared.statusBarOrientation = .portrait
//        } else {
//            UIDevice.current.setValue(UIInterfaceOrientation.landscapeRight.rawValue, forKey: "orientation")
//            UIApplication.shared.setStatusBarHidden(false, with: .fade)
//            UIApplication.shared.statusBarOrientation = .landscapeRight
//        }
//    }
    
    // MARK: - 生命周期
    deinit {
        Task { @MainActor [weak self]  in
            self?.playerLayer?.pause()
            self?.playerLayer?.prepareToDeinit()
        }
        NotificationCenter.default.removeObserver(self, name: UIApplication.didChangeStatusBarOrientationNotification, object: nil)
    }

    
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        if let customControlView = storyBoardCustomControl() {
            self.customControlView = customControlView
        }
        initUI()
        initUIData()
        configureVolume()
        preparePlayer()
    }
    
    @available(*, deprecated, message:"Use newer init(customControlView:_)")
    public convenience init(customControllView: NetfilmPlayerControlView?) {
        self.init(customControlView: customControllView)
    }
    
    public init(customControlView: NetfilmPlayerControlView?) {
        super.init(frame:CGRect.zero)
        self.customControlView = customControlView
        initUI()
        initUIData()
        configureVolume()
        preparePlayer()
    }
    
    public convenience init() {
        self.init(customControlView:nil)
    }
    
    // MARK: - 初始化
    fileprivate func initUI() {
        self.backgroundColor = UIColor.black
        
        if let customView = customControlView {
            controlView = customView
        } else {
            controlView = NetfilmPlayerControlView()
        }
        
        addSubview(controlView)
        controlView.updateUI(isFullScreen)
        controlView.delegate = self
        controlView.player   = self
        controlView.snp.makeConstraints { (make) in
            make.edges.equalTo(self)
        }
        
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(self.panDirection(_:)))
        self.addGestureRecognizer(panGesture)
    }
    
    fileprivate func initUIData() {
        NotificationCenter.default.addObserver(self, selector: #selector(self.onOrientationChanged), name: UIApplication.didChangeStatusBarOrientationNotification, object: nil)
    }
    
    fileprivate func configureVolume() {
        let volumeView = MPVolumeView()
        for view in volumeView.subviews {
            if let slider = view as? UISlider {
                self.volumeViewSlider = slider
            }
        }
    }
    
    fileprivate func preparePlayer() {
        playerLayer = NetfilmPlayerLayerView()
        playerLayer!.videoGravity = videoGravity
        insertSubview(playerLayer!, at: 0)
        playerLayer!.snp.makeConstraints { [weak self](make) in
          guard let `self` = self else { return }
          make.edges.equalTo(self)
        }
        playerLayer!.delegate = self
        controlView.showLoader()
        self.layoutIfNeeded()
    }
}

extension NetfilmPlayer: NetfilmPlayerLayerViewDelegate {
    public func NetfilmPlayer(player: NetfilmPlayerLayerView, playerIsPlaying playing: Bool) {
        controlView.playStateDidChange(isPlaying: playing)
        delegate?.NetfilmPlayer(player: self, playerIsPlaying: playing)
        isPlayingStateChanged?(player.isPlaying)
        isPlayingStateChanged?(player.isPlaying)
    }
    
    public func NetfilmPlayer(player: NetfilmPlayerLayerView, loadedTimeDidChange loadedDuration: TimeInterval, totalDuration: TimeInterval) {
        NetfilmPlayerManager.shared.log("loadedTimeDidChange - \(loadedDuration) - \(totalDuration)")
        controlView.loadedTimeDidChange(loadedDuration: loadedDuration, totalDuration: totalDuration)
        delegate?.NetfilmPlayer(player: self, loadedTimeDidChange: loadedDuration, totalDuration: totalDuration)
        controlView.totalDuration = totalDuration
        self.totalDuration = totalDuration
    }
    
    public func NetfilmPlayer(player: NetfilmPlayerLayerView, playerStateDidChange state: NetfilmPlayerState) {
        NetfilmPlayerManager.shared.log("playerStateDidChange - \(state)")

        controlView.playerStateDidChange(state: state)

        switch state {
        case .readyToPlay:
            Task { @MainActor in
                if !isPauseByUser {
                    play()
                }
                if shouldSeekTo != 0 {
                    seek(shouldSeekTo, completion: { [weak self] in
                        Task { @MainActor in
                            guard let self = self else { return }
                            if !self.isPauseByUser {
                                self.play()
                            } else {
                                self.pause()
                            }
                        }
                    })
                    shouldSeekTo = 0
                }
            }

        case .bufferFinished:
            Task { @MainActor in
                autoPlay()
            }

        case .playedToTheEnd:
            Task { @MainActor in
                isPlayToTheEnd = true
            }

        default:
            break
        }

        Task { @MainActor in
            panGesture.isEnabled = state != .playedToTheEnd
            delegate?.NetfilmPlayer(player: self, playerStateDidChange: state)
            playStateChanged?(state)
        }
    }

    
    public func NetfilmPlayer(player: NetfilmPlayerLayerView, playTimeDidChange currentTime: TimeInterval, totalTime: TimeInterval) {
        NetfilmPlayerManager.shared.log("playTimeDidChange - \(currentTime) - \(totalTime)")
        delegate?.NetfilmPlayer(player: self, playTimeDidChange: currentTime, totalTime: totalTime)
        self.currentPosition = currentTime
        totalDuration = totalTime
        if isSliderSliding {
            return
        }
        controlView.playTimeDidChange(currentTime: currentTime, totalTime: totalTime)
        controlView.totalDuration = totalDuration
        playTimeDidChange?(currentTime, totalTime)
    }
}

extension NetfilmPlayer: NetfilmPlayerControlViewDelegate {
    open func controlView(controlView: NetfilmPlayerControlView,
                          didChooseDefinition index: Int) {
        shouldSeekTo = currentPosition
        playerLayer?.resetPlayer()
        currentDefinition = index
        playerLayer?.playAsset(asset: resource.definitions[index].avURLAsset)
    }
    open func controlView(controlView: NetfilmPlayerControlView,
                          didPressButton button: UIButton) {
        if let action = NetfilmPlayerControlView.ButtonType(rawValue: button.tag) {
            switch action {
            case .back:
                backBlock?(isFullScreen)
                if isFullScreen {
                    // fullScreenButtonPressed() لم يعد مطلوبًا
                } else {
                    Task { @MainActor in
                        playerLayer?.prepareToDeinit()
                    }
                }

            case .play:
                Task { @MainActor in
                    if button.isSelected {
                        pause()
                    } else {
                        if isPlayToTheEnd {
                            seek(0, completion: { [weak self] in
                                Task { @MainActor in
                                    self?.play()
                                }
                            })
                            controlView.hidePlayToTheEndView()
                            isPlayToTheEnd = false
                        }
                        play()
                    }
                }

            case .replay:
                Task { @MainActor in
                    isPlayToTheEnd = false
                    seek(0)
                    play()
                }

            case .fullscreen:
                break // fullScreenButtonPressed() لم يعد مطلوبًا

            default:
                print("[Error] unhandled Action")
            }
        }
    }

    
    open func controlView(controlView: NetfilmPlayerControlView,
                          slider: UISlider,
                          onSliderEvent event: UIControl.Event) {
        switch event {
        case .touchDown:
            playerLayer?.onTimeSliderBegan()
            isSliderSliding = true
            
        case .touchUpInside :
            isSliderSliding = false
            let target = self.totalDuration * Double(slider.value)
            
            if isPlayToTheEnd {
                isPlayToTheEnd = false
                seek(target, completion: {[weak self] in
                    Task { @MainActor in
                        self?.play()
                    }
                })
                controlView.hidePlayToTheEndView()
            } else {
                seek(target, completion: {[weak self] in
                    Task { @MainActor in
                        self?.autoPlay()
                    }
                })
            }
        default:
            break
        }
    }
    
    public func controlView(controlView: NetfilmPlayerControlView, didChangeVideoAspectRatio: NetfilmPlayerAspectRatio) {
        self.playerLayer?.aspectRatio = self.aspectRatio
    }
    
    open func controlView(controlView: NetfilmPlayerControlView, didChangeVideoPlaybackRate rate: Float) {
        self.playerLayer?.player?.rate = rate
    }
}
