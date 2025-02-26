### 📌 **NetfilmPlayer – A Modified Video Player Based on BMPlayer | Swift 6**  
🎬 **NetfilmPlayer**  
A **customized and enhanced video player** based on `BMPlayer`, fully optimized for **Swift 6 and iOS 18**.  
Designed for **seamless movie and TV show playback**, featuring **UI improvements, new controls, and enhanced user experience**.

---

## 📌 **Modifications & Enhancements in NetfilmPlayer**  

### 1️⃣ **✅ Full Swift 6 Compatibility**  
- The code is **fully updated for Swift 6 and iOS 18**.  
- Improved performance and resolved minor warnings for a smoother experience.  

### 2️⃣ **🎯 Better Video Playback Controls**  
- **Added Play/Pause button in the center of the screen** 🎬.  
- **Added 10-second forward & backward buttons in the center of the screen** ⏩⏪.  

### 3️⃣ **📺 Optimized TV Show Playback**  
- **Added `UILabel` to display episode name and season below the movie/show title**.  
- **Added a beautifully designed `Next Episode` button for TV series**.  
- **Separated Movie and TV Show playback UI**:
  - **Movie mode** 🎥 (Standard playback without episode controls).  
  - **TV Show mode** 📺 (Displays:
    - **Show title** 🎬  
    - **Episode name and season** 🏷  
    - **Next Episode button** ⏭).  

### 4️⃣ **⚡️ Removed Unnecessary Features**  
- ❌ **Removed the fullscreen button** (no longer needed).  
- ❌ **Removed total video duration from the UI**.  
- ❌ **Removed timeline seeking via swipe gestures**, replaced with **dedicated 10-second forward & backward buttons**.  

### 5️⃣ **🎨 Modern UI & Better User Experience**  
- **Sleek, well-organized, and aesthetically pleasing design**.  
- **Controls are neatly arranged for an intuitive experience**.  

---

## 📌 **Usage Example**
```swift
import NetfilmPlayer

let playerView = NetfilmPlayer()
playerView.setVideo(URL(string: "https://example.com/video.mp4")!)
playerView.play()
```

### **📌 Custom Controls in `NetfilmPlayerControlView`**
```swift
playerView.controlView.didPressPlay = { [weak playerView] in
    Task { @MainActor in
        playerView?.play()
    }
}

playerView.controlView.didPressNextEpisode = { [weak playerView] in
    Task { @MainActor in
        playerView?.loadNextEpisode()
    }
}
```

---

## 📌 **Technical Features**  
✅ **Swift 6 & iOS 18 Support**.  
✅ **Improved playback controls for an enhanced viewing experience**.  
✅ **Dedicated TV show playback mode with episode & season details**.  
✅ **Modern UI with neatly arranged controls**.  
✅ **Better resource management and performance improvements**.  

---

🚀 **This library will be available on `GitHub` soon with full documentation! 🎯🔥**
