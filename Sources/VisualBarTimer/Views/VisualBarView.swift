import SwiftUI

struct VisualBarView: View {
    @ObservedObject var engine: TimerEngine
    @ObservedObject var settings: TimerSettings
    
    // セグメント数 (実機のLEDバー感)
    private let segmentCount = 48
    
    var body: some View {
        GeometryReader { geometry in
            if settings.orientation == .horizontal {
                horizontalBar(size: geometry.size)
            } else {
                verticalBar(size: geometry.size)
            }
        }
    }
    
    // MARK: - 横向き (右から左に減る: 左端が0, 右端がMAX)
    @ViewBuilder
    private func horizontalBar(size: CGSize) -> some View {
        let activeSegments = Int(round(engine.progress * Double(segmentCount)))
        
        VStack(spacing: 5) {
            // LEDセグメントバー
            HStack(spacing: 2) {
                ForEach(0..<segmentCount, id: \.self) { index in
                    let isActive = index < activeSegments
                    let color = segmentColor(forIndex: index, total: segmentCount, progress: engine.progress)
                    
                    RoundedRectangle(cornerRadius: 2)
                        .fill(isActive ? (engine.isFlashing ? Color.white : color) : Color.white.opacity(0.16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 2)
                                .stroke(isActive ? Color.white.opacity(0.4) : Color.black.opacity(0.6), lineWidth: 0.5)
                        )
                        .shadow(color: isActive ? color.opacity(0.75) : Color.clear, radius: 3)
                }
            }
            .padding(2)
            .frame(height: max(16, size.height - 18))
            .background(Color.black.opacity(0.85))
            .clipShape(RoundedRectangle(cornerRadius: 5))
            .overlay(
                RoundedRectangle(cornerRadius: 5)
                    .stroke(Color.white.opacity(0.40), lineWidth: 1.2)
            )
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let ratio = max(0, min(1, value.location.x / size.width))
                        engine.setProgressRatio(ratio)
                    }
            )
            
            // 目盛線・ラベル
            HStack {
                Text("0")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.8))
                Spacer()
                Text("25%")
                    .font(.system(size: 8, weight: .semibold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.5))
                Spacer()
                Text("50%")
                    .font(.system(size: 8, weight: .semibold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.5))
                Spacer()
                Text("75%")
                    .font(.system(size: 8, weight: .semibold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.5))
                Spacer()
                Text("MAX")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(.horizontal, 2)
        }
    }
    
    // MARK: - 縦向き (上から下に減る: 下端が0, 上端がMAX)
    @ViewBuilder
    private func verticalBar(size: CGSize) -> some View {
        let activeSegments = Int(round(engine.progress * Double(segmentCount)))
        
        HStack(spacing: 6) {
            // LEDセグメントバー (インデックスは上から順 = segmentCount-1 から 0)
            VStack(spacing: 2) {
                ForEach((0..<segmentCount).reversed(), id: \.self) { index in
                    let isActive = index < activeSegments
                    let color = segmentColor(forIndex: index, total: segmentCount, progress: engine.progress)
                    
                    RoundedRectangle(cornerRadius: 2)
                        .fill(isActive ? (engine.isFlashing ? Color.white : color) : Color.white.opacity(0.16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 2)
                                .stroke(isActive ? Color.white.opacity(0.4) : Color.black.opacity(0.6), lineWidth: 0.5)
                        )
                        .shadow(color: isActive ? color.opacity(0.75) : Color.clear, radius: 3)
                }
            }
            .padding(2)
            .frame(width: max(20, size.width - 28))
            .background(Color.black.opacity(0.85))
            .clipShape(RoundedRectangle(cornerRadius: 5))
            .overlay(
                RoundedRectangle(cornerRadius: 5)
                    .stroke(Color.white.opacity(0.40), lineWidth: 1.2)
            )
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let ratio = max(0, min(1, 1.0 - (value.location.y / size.height)))
                        engine.setProgressRatio(ratio)
                    }
            )
            
            // 縦向き目盛ラベル
            VStack {
                Text("MAX")
                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.8))
                Spacer()
                Text("75%")
                    .font(.system(size: 7, weight: .medium, design: .monospaced))
                    .foregroundColor(.white.opacity(0.5))
                Spacer()
                Text("50%")
                    .font(.system(size: 7, weight: .medium, design: .monospaced))
                    .foregroundColor(.white.opacity(0.5))
                Spacer()
                Text("25%")
                    .font(.system(size: 7, weight: .medium, design: .monospaced))
                    .foregroundColor(.white.opacity(0.5))
                Spacer()
                Text("0")
                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.8))
            }
            .frame(width: 22)
        }
    }
    
    // MARK: - カラー計算
    private func segmentColor(forIndex index: Int, total: Int, progress: Double) -> Color {
        if settings.theme == .monochrome {
            return Color.white
        }
        
        let segmentRatio = Double(index) / Double(total)
        
        if segmentRatio < 0.20 {
            // 残りわずか (赤)
            return Color(red: 0.98, green: 0.22, blue: 0.22)
        } else if segmentRatio < 0.50 {
            // 中盤 (黄・オレンジ)
            return Color(red: 0.98, green: 0.76, blue: 0.12)
        } else {
            // 充分 (エメラルドグリーン)
            return Color(red: 0.18, green: 0.88, blue: 0.48)
        }
    }
}
