import AppKit

final class SoundManager {
    static let shared = SoundManager()
    private var alarmTimer: Timer?
    
    private init() {}
    
    // クリック音・操作音は無効化
    func playClick() {}
    func playStart() {}
    
    // タイムアップ時のみアラームを鳴らす
    func playAlarm(repeatCount: Int = 3) {
        var count = 0
        alarmTimer?.invalidate()
        
        let playSound = {
            if let sound = NSSound(named: "Glass") ?? NSSound(named: "Ping") {
                sound.play()
            } else {
                NSSound.beep()
            }
        }
        
        playSound()
        count += 1
        
        alarmTimer = Timer.scheduledTimer(withTimeInterval: 0.4, repeats: true) { [weak self] timer in
            if count >= repeatCount {
                timer.invalidate()
                self?.alarmTimer = nil
            } else {
                playSound()
                count += 1
            }
        }
    }
    
    func stopAlarm() {
        alarmTimer?.invalidate()
        alarmTimer = nil
    }
}
