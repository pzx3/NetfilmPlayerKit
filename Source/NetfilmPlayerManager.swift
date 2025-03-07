//
//  NetfilmPlayerManager.swift
//  Pods
//
//  Created by BrikerMan on 16/5/21.
//
//

import UIKit
import AVFoundation
import NVActivityIndicatorView

@MainActor public let NetfilmPlayerConf = NetfilmPlayerManager.shared

public enum NetfilmPlayerTopBarShowCase: Int {
    case always         = 0 /// 始终显示
    case horizantalOnly = 1 /// 只在横屏界面显示
    case none           = 2 /// 不显示
}

open class NetfilmPlayerManager {
    /// 单例
    @MainActor public static let shared = NetfilmPlayerManager()
    
    /// tint color
    open var tintColor = UIColor.white
    
    /// Loader
    open var loaderType = NVActivityIndicatorType.ballRotateChase
    
    /// should auto play
    open var shouldAutoPlay = true
    
    open var topBarShowInCase = NetfilmPlayerTopBarShowCase.always
    
    open var animateDelayTimeInterval = TimeInterval(5)
    
    /// should show log
    open var allowLog = false
    
    /// use gestures to set brightness, volume and play position
    open var enableBrightnessGestures = true
    open var enableVolumeGestures = true
    open var enablePlaytimeGestures = false
    open var enablePlayControlGestures = false
    
    open var enableChooseDefinition = true
    
    internal static func asset(for resouce: NetfilmPlayerResourceDefinition) -> AVURLAsset {
        return AVURLAsset(url: resouce.url, options: resouce.options)
    }
    
    /**
     打印log
     
     - parameter info: log信息
     */
    func log(_ info:String) {
        if allowLog {
            print(info)
        }
    }
}
