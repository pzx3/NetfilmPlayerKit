//
//  NetfilmPlayerControlView.swift
//  Pods
//
//  Created by BrikerMan on 16/4/29.
//
//

import UIKit
import NVActivityIndicatorView
import AVFoundation
import SnapKit

@MainActor
@objc public protocol NetfilmPlayerControlViewDelegate: AnyObject {
    /**
     call when control view choose a definition
     
     - parameter controlView: control view
     - parameter index:       index of definition
     */
    func controlView(controlView: NetfilmPlayerControlView, didChooseDefinition index: Int)
    
    /**
     call when control view pressed an button
     
     - parameter controlView: control view
     - parameter button:      button type
     */
    func controlView(controlView: NetfilmPlayerControlView, didPressButton button: UIButton)
    
    /**
     call when slider action trigged
     
     - parameter controlView: control view
     - parameter slider:      progress slider
     - parameter event:       action
     */
    func controlView(controlView: NetfilmPlayerControlView, slider: UISlider, onSliderEvent event: UIControl.Event)
    
    /**
     call when needs to change playback rate
     
     - parameter controlView: control view
     - parameter rate:        playback rate
     */
    @objc optional func controlView(controlView: NetfilmPlayerControlView, didChangeVideoPlaybackRate rate: Float)
}

open class NetfilmPlayerControlView: UIView {
    
    open weak var delegate: NetfilmPlayerControlViewDelegate?
    open weak var player: NetfilmPlayer?
    
    // MARK: Variables
    open var resource: NetfilmPlayerResource?
    
    open var selectedIndex = 0
    open var isFullscreen  = false
    open var isMaskShowing = true
    
    open var totalDuration: TimeInterval = 0
    open var delayItem: DispatchWorkItem?
    
    var playerLastState: NetfilmPlayerState = .notSetURL
    
    fileprivate var isSelectDefinitionViewOpened = false
    
    // MARK: UI Components
    /// main views which contains the topMaskView and bottom mask view
    open var mainMaskView   = UIView()
    open var topMaskView    = UIView()
    open var bottomMaskView = UIView()
    
    /// Image view to show video cover
    open var maskImageView = UIImageView()
    
    /// top views
    open var topWrapperView = UIView()
    open var backButton = UIButton(type : UIButton.ButtonType.custom)
    open var titleLabel = UILabel()
    open var chooseDefinitionView = UIView()
    
    /// bottom view
    open var bottomWrapperView = UIView()
    open var currentTimeLabel = UILabel()
    open var totalTimeLabel   = UILabel()
    
    /// Progress slider
    open var timeSlider = NetfilmTimeSlider()
    
    /// load progress view
    open var progressView = UIProgressView()
    
    /* play button
     playButton.isSelected = player.isPlaying
     */
    open var playButton = UIButton(type: UIButton.ButtonType.custom)
    open var playButtonBig = UIButton(type: UIButton.ButtonType.custom)

    open var forwardButton = UIButton(type: UIButton.ButtonType.custom)
    open var backwardButton = UIButton(type: UIButton.ButtonType.custom)
    
       
    open var containerViewForNextEpisode = UIView()  // الحاوية الرئيسية للزر
    open var progressViewForNextEpisode = UIView()   // شريط التقدم
    open var nextEpisodeLabel = UILabel()  // نص "الحلقة التالية"
    open var playIcon = UIImageView()  // أيقونة التشغيل
    private var progressWidthConstraint: Constraint?
    private var progress: CGFloat = 0
    private var timer: Timer?
    
    /* fullScreen button
     fullScreenButton.isSelected = player.isFullscreen
     */
    open var fullscreenButton = UIButton(type: UIButton.ButtonType.custom)
    
    open var subtitleLabel    = UILabel()
    open var subtileAttribute: [NSAttributedString.Key : Any]?
    
    /// Activty Indector for loading
    open var loadingIndicator  = NVActivityIndicatorView(frame:  CGRect(x: 0, y: 0, width: 50, height: 50))
    
    open var seekToView       = UIView()
    open var seekToViewImage  = UIImageView()
    open var seekToLabel      = UILabel()
    
    open var replayButton     = UIButton(type: UIButton.ButtonType.custom)

    
    /// Gesture used to show / hide control view
    open var tapGesture: UITapGestureRecognizer!
    open var doubleTapGesture: UITapGestureRecognizer!
    
    // MARK: - handle player state change
    /**
     call on when play time changed, update duration here
     
     - parameter currentTime: current play time
     - parameter totalTime:   total duration
     */
    open func playTimeDidChange(currentTime: TimeInterval, totalTime: TimeInterval) {
        currentTimeLabel.text = NetfilmPlayer.formatSecondsToString(currentTime)
        totalTimeLabel.text   = NetfilmPlayer.formatSecondsToString(totalTime)
        timeSlider.value      = Float(currentTime) / Float(totalTime)
        
        switch player?.isMovie {
        case true: break
        case false: showNextEpisode()
        case .none:
            break
        case .some(_):
            break
        }
   
//        if let subtitle = resource?.subtitle {
//            showSubtile(from: subtitle, at: currentTime)
//        }
    }


    /**
     change subtitle resource
     
     - Parameter subtitles: new subtitle object
     */
    open func update(subtitles: NetfilmSubtitles?) {
//        resource?.subtitle = subtitles
    }
    
    /**
     call on load duration changed, update load progressView here
     
     - parameter loadedDuration: loaded duration
     - parameter totalDuration:  total duration
     */
    open func loadedTimeDidChange(loadedDuration: TimeInterval, totalDuration: TimeInterval) {
        progressView.setProgress(Float(loadedDuration)/Float(totalDuration), animated: true)
    }
    
    open func playerStateDidChange(state: NetfilmPlayerState) {
        switch state {
            
        case .readyToPlay:
            hideLoader()
            
        case .buffering:
            showLoader()
            
        case .bufferFinished:
            hideLoader()
            
        case .playedToTheEnd:
            playButton.isSelected = false
            playButtonBig.isSelected = false
            showPlayToTheEndView()
            controlViewAnimation(isShow: true)
            
        default:
            break
        }
        playerLastState = state
    }
    
    
 
    func showNextEpisode() {
        guard let player = player else { return } // تأكد من أن المشغل موجود
        guard let currentCMTime = player.avPlayer?.currentTime() else { return } // الحصول على الوقت الحالي
        
        let currentTime = CMTimeGetSeconds(currentCMTime) // تحويل CMTime إلى Double
        let totalDuration = player.totalDuration // إجمالي مدة الفيديو (يجب أن يكون Double)
        
        // التأكد من أن القيم صحيحة وليست NaN
        guard !currentTime.isNaN, !totalDuration.isNaN else { return }

        let remainingTime = totalDuration - currentTime // حساب الوقت المتبقي
        
        // إذا تبقى 25 ثانية أو أقل، إظهار الزر + بدء التقدم
        if remainingTime <= 25 {
            if containerViewForNextEpisode.isHidden { // تجنب إعادة إظهاره إذا كان ظاهرًا بالفعل
                containerViewForNextEpisode.isHidden = false
                startProgress() // تشغيل شريط التقدم أو أي إجراء آخر
            }
        }
        // إذا كان الوقت المتبقي أكبر من 25 ثانية، إخفاء الزر
        else {
            if !containerViewForNextEpisode.isHidden { // تجنب إعادة إخفائه إذا كان مخفيًا بالفعل
                containerViewForNextEpisode.isHidden = true
            }
            timer?.invalidate()
            self.progress = 0.0
            self.progressWidthConstraint?.update(offset: 0.0)
            timer = nil
        }
    }


    
    
    /**
     Call when User use the slide to seek function
     
     - parameter toSecound:     target time
     - parameter totalDuration: total duration of the video
     - parameter isAdd:         isAdd
     */
    open func showSeekToView(to toSecound: TimeInterval, total totalDuration:TimeInterval, isAdd: Bool) {
        seekToView.isHidden = false
        seekToLabel.text    = NetfilmPlayer.formatSecondsToString(toSecound)
        
        let rotate = isAdd ? 0 : CGFloat(Double.pi)
        seekToViewImage.transform = CGAffineTransform(rotationAngle: rotate)
        
        let targetTime = NetfilmPlayer.formatSecondsToString(toSecound)
        timeSlider.value = Float(toSecound / totalDuration)
        currentTimeLabel.text = targetTime
    }
    
    // MARK: - UI update related function
    /**
     Update UI details when player set with the resource
     
     - parameter resource: video resouce
     - parameter index:    defualt definition's index
     */
    open func prepareUI(for resource: NetfilmPlayerResource, selectedIndex index: Int) {
        self.resource = resource
        self.selectedIndex = index
        titleLabel.text = resource.name
        subtitleLabel.text = resource.subtitle
        prepareChooseDefinitionView()
        containerViewForNextEpisode.isHidden = true
        autoFadeOutControlViewWithAnimation()
    }
    
    open func playStateDidChange(isPlaying: Bool) {
        autoFadeOutControlViewWithAnimation()
        playButton.isSelected = isPlaying
        playButtonBig.isSelected = isPlaying

    }
    
    /**
     auto fade out controll view with animtion
     */
    open func autoFadeOutControlViewWithAnimation() {
        cancelAutoFadeOutAnimation()
        delayItem = DispatchWorkItem { [weak self] in
            if self?.playerLastState != .playedToTheEnd {
                self?.controlViewAnimation(isShow: false)
            }
        }
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + NetfilmPlayerConf.animateDelayTimeInterval,
                                      execute: delayItem!)
    }
    
    /**
     cancel auto fade out controll view with animtion
     */
    open func cancelAutoFadeOutAnimation() {
        delayItem?.cancel()
    }
    
    /**
     Implement of the control view animation, override if need's custom animation
     
     - parameter isShow: is to show the controlview
     */
    open func controlViewAnimation(isShow: Bool) {
        let alpha: CGFloat = isShow ? 1.0 : 0.0
        self.isMaskShowing = isShow
        
        UIApplication.shared.setStatusBarHidden(!isShow, with: .fade)
        
        UIView.animate(withDuration: 0.4, animations: {[weak self] in
          guard let wSelf = self else { return }
          wSelf.topMaskView.alpha    = alpha
          wSelf.bottomMaskView.alpha = alpha
          wSelf.playButtonBig.alpha = alpha
          wSelf.forwardButton.alpha = alpha
          wSelf.backwardButton.alpha = alpha

          wSelf.mainMaskView.backgroundColor = UIColor(white: 0, alpha: isShow ? 0.4 : 0.0)

          if isShow {
              if wSelf.isFullscreen { wSelf.chooseDefinitionView.alpha = 1.0 }
          } else {
              wSelf.replayButton.isHidden = true
              wSelf.chooseDefinitionView.snp.updateConstraints { (make) in
                  make.height.equalTo(35)
              }
              wSelf.chooseDefinitionView.alpha = 0.0
          }
          wSelf.layoutIfNeeded()
        }) { [weak self](_) in
            if isShow {
                self?.autoFadeOutControlViewWithAnimation()
            }
        }
    }
    
    /**
     Implement of the UI update when screen orient changed
     
     - parameter isForFullScreen: is for full screen
     */
    open func updateUI(_ isForFullScreen: Bool) {
        isFullscreen = isForFullScreen
        fullscreenButton.isSelected = isForFullScreen
        chooseDefinitionView.isHidden = !NetfilmPlayerConf.enableChooseDefinition || !isForFullScreen
        if isForFullScreen {
            if NetfilmPlayerConf.topBarShowInCase.rawValue == 2 {
                topMaskView.isHidden = true
            } else {
                topMaskView.isHidden = false
            }
        } else {
            if NetfilmPlayerConf.topBarShowInCase.rawValue >= 1 {
                topMaskView.isHidden = true
            } else {
                topMaskView.isHidden = false
            }
        }
    }
    
    /**
     Call when video play's to the end, override if you need custom UI or animation when played to the end
     */
    open func showPlayToTheEndView() {
        replayButton.isHidden = false
        playButtonBig.isHidden = true
        backwardButton.isHidden = true
        forwardButton.isHidden = true
    }
    
    open func hidePlayToTheEndView() {
        replayButton.isHidden = true
        playButtonBig.isHidden = false
        backwardButton.isHidden = false
        forwardButton.isHidden = false
    }
    
    open func showLoader() {
        loadingIndicator.isHidden = false
        playButtonBig.isHidden = true
        forwardButton.isHidden = true
        backwardButton.isHidden = true
        loadingIndicator.startAnimating()
    }
    
    open func hideLoader() {
        loadingIndicator.isHidden = true
        playButtonBig.isHidden = false
        forwardButton.isHidden = false
        backwardButton.isHidden = false
    }
    
    open func hideSeekToView() {
        seekToView.isHidden = true
    }
    
    open func showCoverWithLink(_ cover:String) {
        self.showCover(url: URL(string: cover))
    }
    
    open func showCover(url: URL?) {
        if let url = url {
            DispatchQueue.global(qos: .default).async { [weak self] in
                let data = try? Data(contentsOf: url)
                DispatchQueue.main.async(execute: { [weak self] in
                  guard let `self` = self else { return }
                    if let data = data {
                        self.maskImageView.image = UIImage(data: data)
                    } else {
                        self.maskImageView.image = nil
                    }
                    self.hideLoader()
                });
            }
        }
    }
    
    open func hideCoverImageView() {
        self.maskImageView.isHidden = true
    }
    
    open func prepareChooseDefinitionView() {
        guard let resource = resource else {
            return
        }
        for item in chooseDefinitionView.subviews {
            item.removeFromSuperview()
        }
        
        for i in 0..<resource.definitions.count {
            let button = NetfilmPlayerClearityChooseButton()
            
            if i == 0 {
                button.tag = selectedIndex
            } else if i <= selectedIndex {
                button.tag = i - 1
            } else {
                button.tag = i
            }
            
            button.setTitle("\(resource.definitions[button.tag].definition)", for: UIControl.State())
            chooseDefinitionView.addSubview(button)
            button.addTarget(self, action: #selector(self.onDefinitionSelected(_:)), for: UIControl.Event.touchUpInside)
            button.snp.makeConstraints({ [weak self](make) in
                guard let `self` = self else { return }
                make.top.equalTo(chooseDefinitionView.snp.top).offset(35 * i)
                make.width.equalTo(50)
                make.height.equalTo(25)
                make.centerX.equalTo(chooseDefinitionView)
            })
            
            if resource.definitions.count == 1 {
                button.isEnabled = false
                button.isHidden = true
            }
        }
    }
    
    open func prepareToDealloc() {
        self.delayItem = nil
    }
    
    // MARK: - Action Response
    /**
     Call when some action button Pressed
     
     - parameter button: action Button
     */
    
    
    @objc open func onButtonPressed(_ button: UIButton) {
      autoFadeOutControlViewWithAnimation()
      if let type = ButtonType(rawValue: button.tag) {
        switch type {
        case .play, .replay:
          if playerLastState == .playedToTheEnd {
            hidePlayToTheEndView()
          }
        default:
          break
        }
      }
        
      delegate?.controlView(controlView: self, didPressButton: button)
    }
    
    @objc open func PlayButtonBigPressed(_ button: UIButton) {
      autoFadeOutControlViewWithAnimation()
      if let type = ButtonType(rawValue: button.tag) {
        switch type {
        case .play, .replay:
          if playerLastState == .playedToTheEnd {
            hidePlayToTheEndView()
          }
        default:
          break
        }
      }
        controlViewAnimation(isShow: !isMaskShowing)
      delegate?.controlView(controlView: self, didPressButton: button)
    }
    
    
    @objc open func forwardButtonPressed(_ button: UIButton) {
        if let player = player?.avPlayer, let duration = player.currentItem?.duration {
            let currentTime = player.currentTime()
            let newTime = CMTime(seconds: CMTimeGetSeconds(currentTime) + 10, preferredTimescale: currentTime.timescale)
            
            if newTime < duration {
                player.seek(to: newTime) { finished in
                    print("Seek completed")
                    DispatchQueue.main.async {
                                        self.timeSlider.value = Float(CMTimeGetSeconds(newTime) / CMTimeGetSeconds(duration))
                                    }
                }
            } else {
                player.seek(to: duration) { finished in
                    print("Reached end of video")
                }
            }
        }

    }
    
    @objc open func backwardButtonPressed(_ button: UIButton) {
        if let player = player?.avPlayer, let duration = player.currentItem?.duration {
            let currentTime = player.currentTime()
            let newTime = CMTime(seconds: CMTimeGetSeconds(currentTime) - 10, preferredTimescale: currentTime.timescale)
            
            if newTime < duration {
                player.seek(to: newTime) { finished in
                    print("Seek completed")
                    DispatchQueue.main.async {
                                        self.timeSlider.value = Float(CMTimeGetSeconds(newTime) / CMTimeGetSeconds(duration))
                                    }
                }
            } else {
                player.seek(to: duration) { finished in
                    print("Reached end of video")
                }
            }
        }
    }
    
    /**
     Call when the tap gesture tapped
     
     - parameter gesture: tap gesture
     */
    @objc open func onTapGestureTapped(_ gesture: UITapGestureRecognizer) {
        if playerLastState == .playedToTheEnd {
            return
        }
        controlViewAnimation(isShow: !isMaskShowing)
    }
    
    @objc open func onDoubleTapGestureRecognized(_ gesture: UITapGestureRecognizer) {
        guard let player = player else { return }
        guard playerLastState == .readyToPlay || playerLastState == .buffering || playerLastState == .bufferFinished else { return }
        
        if player.isPlaying {
            player.pause()
            controlViewAnimation(isShow: !isMaskShowing)
        } else {
            player.play()
            controlViewAnimation(isShow: !isMaskShowing)
        }
    }
    
    // MARK: - handle UI slider actions
    @objc func progressSliderTouchBegan(_ sender: UISlider)  {
      delegate?.controlView(controlView: self, slider: sender, onSliderEvent: .touchDown)
    }
    
    @objc func progressSliderValueChanged(_ sender: UISlider)  {
      hidePlayToTheEndView()
      cancelAutoFadeOutAnimation()
      let currentTime = Double(sender.value) * totalDuration
      currentTimeLabel.text = NetfilmPlayer.formatSecondsToString(currentTime)
      delegate?.controlView(controlView: self, slider: sender, onSliderEvent: .valueChanged)
    }
    
    @objc func progressSliderTouchEnded(_ sender: UISlider)  {
      autoFadeOutControlViewWithAnimation()
      delegate?.controlView(controlView: self, slider: sender, onSliderEvent: .touchUpInside)
    }
    
    
    // MARK: - private functions
    fileprivate func showSubtile(from subtitle: NetfilmSubtitles, at time: TimeInterval) {
//        if let group = subtitle.search(for: time) {
//            subtitleBackView.isHidden = false
//            subtitleLabel.attributedText = NSAttributedString(string: group.text,
//                                                              attributes: subtileAttribute)
//        } else {
//            subtitleBackView.isHidden = true
//        }
    }
    
    @objc fileprivate func onDefinitionSelected(_ button:UIButton) {
        let height = isSelectDefinitionViewOpened ? 35 : resource!.definitions.count * 40
        chooseDefinitionView.snp.updateConstraints { (make) in
            make.height.equalTo(height)
        }
        
        UIView.animate(withDuration: 0.3, animations: {[weak self] in
            self?.layoutIfNeeded()
        })
        isSelectDefinitionViewOpened = !isSelectDefinitionViewOpened
        if selectedIndex != button.tag {
            selectedIndex = button.tag
            delegate?.controlView(controlView: self, didChooseDefinition: button.tag)
        }
        prepareChooseDefinitionView()
    }
    
    @objc fileprivate func onReplyButtonPressed() {
        replayButton.isHidden = true
    }
    
    // MARK: - Init
    override public init(frame: CGRect) {
        super.init(frame: frame)
        setupUIComponents()
        addSnapKitConstraint()
        customizeUIComponents()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupUIComponents()
        addSnapKitConstraint()
        customizeUIComponents()
    }
    
    /// Add Customize functions here
    open func customizeUIComponents() {
        
    }

    func setupUIComponents() {
        // Subtile view

        
        
        // إعداد الـ containerView (الحاوية الرئيسية)
        containerViewForNextEpisode.backgroundColor = .gray
        containerViewForNextEpisode.layer.cornerRadius = 10
        containerViewForNextEpisode.clipsToBounds = true
        let tapGestureNext = UITapGestureRecognizer(target: self, action: #selector(startProgressTapped))
        containerViewForNextEpisode.addGestureRecognizer(tapGestureNext)
        
        // إعداد شريط التقدم الأبيض (يبدأ من عرض 0)
        progressView.backgroundColor = UIColor.white
        
        
        progressViewForNextEpisode.backgroundColor = UIColor.white
        progressViewForNextEpisode.layer.cornerRadius = 10
        progressViewForNextEpisode.isUserInteractionEnabled = true  // السماح بالتفاعل

        
        
        // إعداد نص "الحلقة التالية"
         nextEpisodeLabel.text = "الحلقة التالية"
         nextEpisodeLabel.textColor = .black
         nextEpisodeLabel.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        
        
        // إعداد أيقونة التشغيل
              playIcon.image = UIImage(systemName: "play.fill")
              playIcon.tintColor = .black
              playIcon.contentMode = .scaleAspectFit

        
//        subtitleBackView.layer.cornerRadius = 2
//        subtitleBackView.backgroundColor = UIColor.black.withAlphaComponent(0.4)
//        subtitleBackView.addSubview(subtitleLabel)
//        subtitleBackView.isHidden = true
//        
//        addSubview(subtitleBackView)
        
        // Main mask view
        addSubview(mainMaskView)
        mainMaskView.addSubview(topMaskView)
        mainMaskView.addSubview(bottomMaskView)
        mainMaskView.addSubview(playButtonBig)
        mainMaskView.addSubview(forwardButton)
        mainMaskView.addSubview(backwardButton)
        mainMaskView.insertSubview(maskImageView, at: 0)
        mainMaskView.clipsToBounds = true
        mainMaskView.backgroundColor = UIColor(white: 0, alpha: 0.4 )
        mainMaskView.addSubview(containerViewForNextEpisode)
        containerViewForNextEpisode.addSubview(progressViewForNextEpisode)
        containerViewForNextEpisode.addSubview(nextEpisodeLabel)
        containerViewForNextEpisode.addSubview(playIcon)
        // Top views
        topMaskView.addSubview(topWrapperView)
        topWrapperView.addSubview(backButton)
        topWrapperView.addSubview(titleLabel)
        topWrapperView.addSubview(subtitleLabel)
        topWrapperView.addSubview(chooseDefinitionView)
        
        backButton.tag = NetfilmPlayerControlView.ButtonType.back.rawValue
        backButton.setImage(NetfilmImageResourcePath("Pod_Asset_NetfilmPlayer_back"), for: .normal)
        backButton.addTarget(self, action: #selector(onButtonPressed(_:)), for: .touchUpInside)
        
        titleLabel.textColor = UIColor.white
        titleLabel.text      = ""
        titleLabel.font      = UIFont.systemFont(ofSize: 16)
        
        subtitleLabel.textColor = UIColor.white
        subtitleLabel.text      = ""
        subtitleLabel.font      = UIFont.systemFont(ofSize: 14)
        
        
        chooseDefinitionView.clipsToBounds = true
        
        // Bottom views
        bottomMaskView.addSubview(bottomWrapperView)
        bottomWrapperView.addSubview(playButton)
        bottomWrapperView.addSubview(currentTimeLabel)
        bottomWrapperView.addSubview(totalTimeLabel)
        bottomWrapperView.addSubview(progressView)
        bottomWrapperView.addSubview(timeSlider)
        bottomWrapperView.addSubview(fullscreenButton)
        
        playButton.tag = NetfilmPlayerControlView.ButtonType.play.rawValue
        playButton.setImage(NetfilmImageResourcePath("Pod_Asset_NetfilmPlayer_play"),  for: .normal)
        playButton.setImage(NetfilmImageResourcePath("Pod_Asset_NetfilmPlayer_pause"), for: .selected)
        playButton.addTarget(self, action: #selector(onButtonPressed(_:)), for: .touchUpInside)
        
        
        playButtonBig.tag = NetfilmPlayerControlView.ButtonType.play.rawValue
        playButtonBig.setImage(NetfilmImageResourcePath("Pod_Asset_NetfilmPlayer_playBig"),  for: .normal)
        playButtonBig.setImage(NetfilmImageResourcePath("Pod_Asset_NetfilmPlayer_pauseBig"), for: .selected)
        playButtonBig.addTarget(self, action: #selector(PlayButtonBigPressed(_:)), for: .touchUpInside)
        
        
        forwardButton.setImage(NetfilmImageResourcePath("Pod_Asset_NetfilmPlayer_forward"),  for: .normal)
        forwardButton.addTarget(self, action: #selector(forwardButtonPressed(_:)), for: .touchUpInside)
        
        
        backwardButton.setImage(NetfilmImageResourcePath("Pod_Asset_NetfilmPlayer_backward"), for: .normal)
        backwardButton.addTarget(self, action: #selector(backwardButtonPressed(_:)), for: .touchUpInside)

        
        currentTimeLabel.textColor  = UIColor.white
        currentTimeLabel.font       = UIFont.systemFont(ofSize: 12)
        currentTimeLabel.text       = "00:00"
        currentTimeLabel.textAlignment = NSTextAlignment.center
        
        totalTimeLabel.textColor    = UIColor.white
        totalTimeLabel.font         = UIFont.systemFont(ofSize: 12)
        totalTimeLabel.text         = "00:00"
        totalTimeLabel.textAlignment   = NSTextAlignment.center
        
        
        timeSlider.maximumValue = 1.0
        timeSlider.minimumValue = 0.0
        timeSlider.value        = 0.0
        timeSlider.setThumbImage(NetfilmImageResourcePath("Pod_Asset_NetfilmPlayer_slider_thumb"), for: .normal)
        
        timeSlider.maximumTrackTintColor = UIColor.clear
        timeSlider.minimumTrackTintColor = UIColor.red
        
        timeSlider.addTarget(self, action: #selector(progressSliderTouchBegan(_:)),
                             for: UIControl.Event.touchDown)
        
        timeSlider.addTarget(self, action: #selector(progressSliderValueChanged(_:)),
                             for: UIControl.Event.valueChanged)
        
        timeSlider.addTarget(self, action: #selector(progressSliderTouchEnded(_:)),
                             for: [UIControl.Event.touchUpInside,UIControl.Event.touchCancel, UIControl.Event.touchUpOutside])
        
        progressView.tintColor      = UIColor ( red: 1.0, green: 1.0, blue: 1.0, alpha: 0.6 )
        progressView.trackTintColor = UIColor ( red: 1.0, green: 1.0, blue: 1.0, alpha: 0.3 )
        
        fullscreenButton.tag = NetfilmPlayerControlView.ButtonType.fullscreen.rawValue
//        fullscreenButton.setImage(NetfilmImageResourcePath("Pod_Asset_NetfilmPlayer_fullscreen"),    for: .normal)
//        fullscreenButton.setImage(NetfilmImageResourcePath("Pod_Asset_NetfilmPlayer_portialscreen"), for: .selected)
        fullscreenButton.addTarget(self, action: #selector(onButtonPressed(_:)), for: .touchUpInside)
        
        mainMaskView.addSubview(loadingIndicator)
        
        loadingIndicator.type  = NetfilmPlayerConf.loaderType
        loadingIndicator.color = NetfilmPlayerConf.tintColor
        
        // View to show when slide to seek
        addSubview(seekToView)
        seekToView.addSubview(seekToViewImage)
        seekToView.addSubview(seekToLabel)
        
        seekToLabel.font                = UIFont.systemFont(ofSize: 13)
        seekToLabel.textColor           = UIColor ( red: 0.9098, green: 0.9098, blue: 0.9098, alpha: 1.0 )
        seekToView.backgroundColor      = UIColor ( red: 0.0, green: 0.0, blue: 0.0, alpha: 0.7 )
        seekToView.layer.cornerRadius   = 4
        seekToView.layer.masksToBounds  = true
        seekToView.isHidden             = true
        
        seekToViewImage.image = NetfilmImageResourcePath("Pod_Asset_NetfilmPlayer_seek_to_image")
        
        addSubview(replayButton)
        replayButton.isHidden = true
        replayButton.setImage(NetfilmImageResourcePath("Pod_Asset_NetfilmPlayer_replay"), for: .normal)
        replayButton.addTarget(self, action: #selector(onButtonPressed(_:)), for: .touchUpInside)
        replayButton.tag = ButtonType.replay.rawValue
        
        tapGesture = UITapGestureRecognizer(target: self, action: #selector(onTapGestureTapped(_:)))
        addGestureRecognizer(tapGesture)
        
        if NetfilmPlayerManager.shared.enablePlayControlGestures {
            doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(onDoubleTapGestureRecognized(_:)))
            doubleTapGesture.numberOfTapsRequired = 2
            addGestureRecognizer(doubleTapGesture)
            
            tapGesture.require(toFail: doubleTapGesture)
        }
    }
    
    func addSnapKitConstraint() {
        // Main mask view
        mainMaskView.snp.makeConstraints { [unowned self](make) in
            make.edges.equalTo(self)
        }
        
        maskImageView.snp.makeConstraints { [unowned self](make) in
            make.edges.equalTo(self.mainMaskView)
        }
        
        containerViewForNextEpisode.snp.makeConstraints { make in
            make.right.equalToSuperview().inset(70)
            make.bottom.equalToSuperview().inset(55)
                make.width.equalTo(150)
                make.height.equalTo(40)
            }
        
        progressViewForNextEpisode.snp.makeConstraints { make in
                  make.leading.top.bottom.equalToSuperview()
                 
            self.progressWidthConstraint = make.width.equalTo(0).constraint
              }
              
        

         
        
        nextEpisodeLabel.snp.makeConstraints { make in
                 make.centerY.equalToSuperview()
                 make.leading.equalToSuperview().offset(20)
             }
        
        playIcon.snp.makeConstraints { make in
                  make.centerY.equalToSuperview()
                  make.leading.equalTo(nextEpisodeLabel.snp.trailing).offset(10)
              }
        
        
        topMaskView.snp.makeConstraints { [unowned self](make) in
            make.top.left.right.equalTo(self.mainMaskView)
        }
        
        topWrapperView.snp.makeConstraints { [unowned self](make) in
            make.height.equalTo(50)
            if #available(iOS 11.0, *) {
              make.top.left.right.equalTo(self.topMaskView.safeAreaLayoutGuide)
              make.bottom.equalToSuperview()
            } else {
              make.top.equalToSuperview().offset(15)
              make.bottom.left.right.equalToSuperview()
            }
        }
        
        bottomMaskView.snp.makeConstraints { [unowned self](make) in
            make.bottom.left.right.equalTo(self.mainMaskView)
        }
        
    
        
        bottomWrapperView.snp.makeConstraints { [unowned self](make) in
            make.height.equalTo(50)
            if #available(iOS 11.0, *) {
              make.bottom.left.right.equalTo(self.bottomMaskView.safeAreaLayoutGuide)
              make.top.equalToSuperview()
            } else {
              make.edges.equalToSuperview()
            }
        }
        
        // Top views
        backButton.snp.makeConstraints { (make) in
          make.width.height.equalTo(30)
          make.left.bottom.equalToSuperview()
        }
        
        titleLabel.snp.makeConstraints { [unowned self](make) in
            make.centerX.equalTo(self.mainMaskView.snp.centerX)
            make.centerY.equalTo(self.backButton.snp.centerY)
        }
        
        subtitleLabel.snp.makeConstraints { [unowned self](make) in
            make.top.equalTo(self.titleLabel.snp.bottom)
            make.centerX.equalTo(self.titleLabel.snp.centerX)
     
        }
        
        
        
        chooseDefinitionView.snp.makeConstraints { [unowned self](make) in
            make.right.equalToSuperview().offset(-20)
            make.top.equalTo(self.titleLabel.snp.top).offset(-4)
            make.width.equalTo(60)
            make.height.equalTo(30)
        }
        
        // Bottom views
        playButton.isHidden = true
        playButton.snp.makeConstraints { (make) in
            make.width.equalTo(50)
            make.height.equalTo(50)
            make.left.bottom.equalToSuperview()
        }
        
        playButtonBig.snp.makeConstraints { make in
            make.width.equalTo(30)
            make.height.equalTo(30)
            make.center.equalTo(self.mainMaskView.snp.center)
            
        }
   
        
        forwardButton.snp.makeConstraints { make in
            make.width.equalTo(40)
            make.height.equalTo(40)
            make.centerY.equalTo(self.playButtonBig.snp.centerY)
            make.left.equalTo(self.playButtonBig.snp.right).inset(-150)
        }
        
        
        backwardButton.snp.makeConstraints { make in
            make.width.equalTo(40)
            make.height.equalTo(40)
            make.centerY.equalTo(self.playButtonBig.snp.centerY)
            make.right.equalTo(self.playButtonBig.snp.left).inset(-150)
            
        }
        /* Orginal code
         currentTimeLabel.snp.makeConstraints { [unowned self](make) in
             make.left.equalTo(self.playButton.snp.right)
             make.centerY.equalTo(self.playButton)
             make.width.equalTo(40)
         }

         timeSlider.snp.makeConstraints { [unowned self](make) in
             make.centerY.equalTo(self.currentTimeLabel)
             make.left.equalTo(self.currentTimeLabel.snp.right).offset(10).priority(750)
             make.height.equalTo(30)
         }
         
         progressView.snp.makeConstraints { [unowned self](make) in
             make.centerY.left.right.equalTo(self.timeSlider)
             make.height.equalTo(2)
         }
         
         totalTimeLabel.snp.makeConstraints { [unowned self](make) in
             make.centerY.equalTo(self.currentTimeLabel)
             make.left.equalTo(self.timeSlider.snp.right).offset(5)
             make.width.equalTo(40)
         }
     
         fullscreenButton.snp.makeConstraints { [unowned self](make) in
             make.width.equalTo(50)
             make.height.equalTo(50)
             make.centerY.equalTo(self.currentTimeLabel)
             make.left.equalTo(self.totalTimeLabel.snp.right)
             make.right.equalToSuperview()
         }
         */
        
        
        timeSlider.snp.makeConstraints { [unowned self] make in
            make.left.bottom.equalToSuperview() // يبدأ من اليسار
            make.height.equalTo(30)
            make.centerY.equalTo(playButton.snp.centerY)
            make.right.equalTo(currentTimeLabel.snp.left).offset(-5) // ينتهي عند بداية currentTimeLabel
        }

        progressView.snp.makeConstraints { [unowned self] make in
            make.centerY.left.right.equalTo(timeSlider)
            make.height.equalTo(2)
        }

        currentTimeLabel.snp.makeConstraints { [unowned self] make in
            make.centerY.equalTo(timeSlider)
            make.right.equalToSuperview().offset(-10) // ينتهي عند حافة الـ Superview مع مسافة 10
            make.width.equalTo(40) // عرض ثابت
        }

        
        loadingIndicator.snp.makeConstraints { [unowned self](make) in
            make.center.equalTo(self.mainMaskView)
        }
        
        // View to show when slide to seek
//        seekToView.snp.makeConstraints { [unowned self](make) in
//            make.center.equalTo(self.snp.center)
//            make.width.equalTo(100)
//            make.height.equalTo(40)
//        }
//        
//        seekToViewImage.snp.makeConstraints { [unowned self](make) in
//            make.left.equalTo(self.seekToView.snp.left).offset(15)
//            make.centerY.equalTo(self.seekToView.snp.centerY)
//            make.height.equalTo(15)
//            make.width.equalTo(25)
//        }
//        
//        seekToLabel.snp.makeConstraints { [unowned self](make) in
//            make.left.equalTo(self.seekToViewImage.snp.right).offset(10)
//            make.centerY.equalTo(self.seekToView.snp.centerY)
//        }

        replayButton.snp.makeConstraints { [unowned self](make) in
            make.center.equalTo(self.mainMaskView)
            make.width.height.equalTo(50)
        }

     
        

    }
    
    @objc private func startProgress() {
        timer?.invalidate() // إيقاف أي مؤقت سابق
        timer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { [weak self] _ in
            guard let self = self else { return }

            Task { @MainActor in
                if self.progress == 150 { // Time it's finished
                    self.timer?.invalidate() // إيقاف المؤقت عند الوصول إلى الحد الأقصى
                    self.timer = nil
                    self.player?.pause()
                    self.player = nil
                    self.player?.removeFromSuperview()
                    NotificationCenter.default.post(name: NSNotification.Name("GoToNextEpisode"), object: nil)
                    print("progress it's fulled")
                } else {
                    self.progress += 6 // زيادة العرض تدريجياً
                    self.progressWidthConstraint?.update(offset: self.progress)
                    UIView.animate(withDuration: 1) {
                        self.mainMaskView.layoutIfNeeded()
                    }
                }
            }
        }
    }

    
    @objc private func startProgressTapped() {
        timer?.invalidate() // إيقاف أي مؤقت سابق
        timer = nil
        NotificationCenter.default.post(name: NSNotification.Name("GoToNextEpisode"), object: nil)
        player?.pause()
        player = nil
        player?.removeFromSuperview()
        print("Tapped")
     }
    
    fileprivate func NetfilmImageResourcePath(_ fileName: String) -> UIImage? {
        let bundle = Bundle(for: NetfilmPlayer.self)
        return UIImage(named: fileName, in: bundle, compatibleWith: nil)
    }
}

