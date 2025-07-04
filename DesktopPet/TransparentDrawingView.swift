//
//  TransparentDrawingView.swift
//  DesktopPet
//
//  Created by 李瑞华 on 2025/7/4.
//

import Cocoa
import CoreGraphics
import CoreServices

class TransparentDrawingView: NSView {

    // MARK: - 视图透明
    override var isOpaque: Bool { false }

    // MARK: - 宠物几何和动画状态
    var petCenter: NSPoint = .zero
    var petAngle: CGFloat = 0.0
    var petOrientationAngle: CGFloat = 0.0

    // 性能优化：点数大幅降低
    let NUM_POINTS: Int = 13000
    let DOT_SIZE: CGFloat = 1.0
    let PET_COLOR: NSColor = NSColor(red: 250/255.0, green: 240/255.0, blue: 240/255.0, alpha: 1.0)
    let PET_SPEED: CGFloat = 0.3
    let ROTATION_SPEED: CGFloat = 1.4
    let WANDER_STRENGTH: CGFloat = 0.0005
    let WALL_REPULSION_STRENGTH: CGFloat = 1.0
    let BUFFER: CGFloat = 200.0
    let PET_SCALE: CGFloat = 1.5 // 比例因子，1.0为原始，2.0为2倍大，可自由调

    var t: CGFloat = 0.0
    let t_step: CGFloat = .pi / 240.0

    var x_coords: [CGFloat] = []
    var y_coords: [CGFloat] = []

    // MARK: - 图像缓存和上下文
    private var petImageCache: CGImage?
    private var cachedImageRect: NSRect?
    var cachedPetScreenPoints: [NSPoint] = []

    // 拖动
    private var lastMousePoint: NSPoint?

    // 优化动画刷新方式（Timer，非DisplayLink）
    private var animationTimer: Timer?

    // MARK: - 构造方法
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)

        petCenter = NSPoint(x: frameRect.midX, y: frameRect.midY)
        petAngle = CGFloat.random(in: 0..<2 * .pi)
        petOrientationAngle = petAngle

        for i in stride(from: NUM_POINTS, to: 0, by: -1) {
            x_coords.append(CGFloat(i))
            y_coords.append(CGFloat(i) / 235.0)
        }

        updatePetImageCache()
        setupTimer()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - 绘图
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        NSColor.clear.set()
        dirtyRect.fill()
        if let image = petImageCache, let rect = cachedImageRect {
            guard let context = NSGraphicsContext.current?.cgContext else { return }
            context.draw(image, in: rect)
        }
    }

    // MARK: - 动画更新逻辑
    func updatePetState() {
        if lastMousePoint != nil {
            updatePetImageCache()
            return
        }

        petAngle += CGFloat.random(in: -WANDER_STRENGTH...WANDER_STRENGTH)
        petCenter.x += PET_SPEED * cos(petOrientationAngle)
        petCenter.y += PET_SPEED * sin(petOrientationAngle)

        var dx = cos(petAngle)
        var dy = sin(petAngle)
        var repulsed = false

        if petCenter.x < BUFFER { dx += WALL_REPULSION_STRENGTH; repulsed = true }
        if petCenter.x > bounds.width - BUFFER { dx -= WALL_REPULSION_STRENGTH; repulsed = true }
        if petCenter.y < BUFFER { dy += WALL_REPULSION_STRENGTH; repulsed = true }
        if petCenter.y > bounds.height - BUFFER { dy -= WALL_REPULSION_STRENGTH; repulsed = true }

        if repulsed { petAngle = atan2(dy, dx) }

        petCenter.x = max(BUFFER, min(petCenter.x, bounds.width - BUFFER))
        petCenter.y = max(BUFFER, min(petCenter.y, bounds.height - BUFFER))

        var angleDiff = petAngle - petOrientationAngle
        angleDiff = fmod((angleDiff + .pi), (2 * .pi)) - .pi
        petOrientationAngle += angleDiff * ROTATION_SPEED

        t += t_step
        updatePetImageCache()
    }

    // MARK: - 优化：在内存中绘制宠物并缓存为图像
    private func updatePetImageCache() {
        var minX: CGFloat = .greatestFiniteMagnitude
        var minY: CGFloat = .greatestFiniteMagnitude
        var maxX: CGFloat = -.greatestFiniteMagnitude
        var maxY: CGFloat = -.greatestFiniteMagnitude
        var currentFrameScreenPoints: [NSPoint] = []

        for i in 0..<NUM_POINTS {
            let x = x_coords[i]
            let y = y_coords[i]
            let k = (4 + sin(y * 2 - t) * 3) * cos(x / 29)
            let e = y / 8 - 13
            let d = sqrt(k * k + e * e)
            let q = 3 * sin(k * 2) + 0.3 / (k + CGFloat.ulpOfOne) +
                      sin(y / 25) * k * (9 + 4 * sin(e * 9 - d * 3 + t * 2))
            let c = d - t

            let local_u = q + 30 * cos(c) + 200
            let local_v = q * sin(c) + 39 * d - 220

            let centered_u = local_u - 200
            let centered_v = -local_v + 220

            let angle_correction: CGFloat = -.pi / 2
            let cos_o = cos(petOrientationAngle + angle_correction)
            let sin_o = sin(petOrientationAngle + angle_correction)

            let rotated_u = centered_u * cos_o - centered_v * sin_o
            let rotated_v = centered_u * sin_o + centered_v * cos_o

            let scaled_x = rotated_u * PET_SCALE
            let scaled_y = rotated_v * PET_SCALE

            let screen_x = scaled_x + petCenter.x
            let screen_y = scaled_y + petCenter.y
            
            currentFrameScreenPoints.append(NSPoint(x: screen_x, y: screen_y))

            let currentDotMinX = screen_x - DOT_SIZE / 2
            let currentDotMaxX = screen_x + DOT_SIZE / 2
            let currentDotMinY = screen_y - DOT_SIZE / 2
            let currentDotMaxY = screen_y + DOT_SIZE / 2

            minX = min(minX, currentDotMinX)
            minY = min(minY, currentDotMinY)
            maxX = max(maxX, currentDotMaxX)
            maxY = max(maxY, currentDotMaxY)
        }

        self.cachedPetScreenPoints = currentFrameScreenPoints

        let renderRect = NSRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
        guard renderRect.width > 0 && renderRect.height > 0 else {
            petImageCache = nil
            cachedImageRect = nil
            return
        }
        let imageSize = NSSize(width: renderRect.width, height: renderRect.height)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Little.rawValue)

        guard let context = CGContext(data: nil,
                                      width: Int(imageSize.width),
                                      height: Int(imageSize.height),
                                      bitsPerComponent: 8,
                                      bytesPerRow: 0,
                                      space: colorSpace,
                                      bitmapInfo: bitmapInfo.rawValue) else {
            print("Failed to create graphics context for image cache.")
            return
        }

        context.translateBy(x: -renderRect.origin.x, y: -renderRect.origin.y)
        context.setFillColor(PET_COLOR.cgColor)
        for point in currentFrameScreenPoints {
            let circleRect = NSRect(x: point.x - DOT_SIZE / 2,
                                    y: point.y - DOT_SIZE / 2,
                                    width: DOT_SIZE,
                                    height: DOT_SIZE)
            context.addEllipse(in: circleRect)
            context.fillPath()
        }

        petImageCache = context.makeImage()
        cachedImageRect = renderRect
    }

    // MARK: - 鼠标事件处理（拖动）
    override func mouseDown(with event: NSEvent) {
        let locationInView = convert(event.locationInWindow, from: nil)
        guard let imageRect = cachedImageRect else {
            super.mouseDown(with: event)
            return
        }
        if imageRect.contains(locationInView) && isPixelOpaque(at: locationInView, in: imageRect) {
            self.lastMousePoint = locationInView
            super.mouseDown(with: event)
        } else {
            self.lastMousePoint = nil
        }
    }

    override func mouseDragged(with event: NSEvent) {
        guard let lastPoint = lastMousePoint else {
            super.mouseDragged(with: event)
            return
        }
        let newLocationInView = convert(event.locationInWindow, from: nil)
        let dx = newLocationInView.x - lastPoint.x
        let dy = newLocationInView.y - lastPoint.y
        petCenter.x += dx
        petCenter.y += dy
        self.lastMousePoint = newLocationInView
        setNeedsDisplay(bounds)
        super.mouseDragged(with: event)
    }

    override func mouseUp(with event: NSEvent) {
        self.lastMousePoint = nil
        super.mouseUp(with: event)
    }

    // MARK: - 点击穿透的核心实现
    override func hitTest(_ point: NSPoint) -> NSView? {
        guard let image = petImageCache, let imageRect = cachedImageRect else { return nil }
        guard imageRect.contains(point) else { return nil }
        if isPixelOpaque(at: point, in: imageRect) {
            return super.hitTest(point)
        } else {
            return nil
        }
    }

    // MARK: - 像素透明度检查
    private func isPixelOpaque(at point: NSPoint, in imageRect: NSRect) -> Bool {
        guard let image = petImageCache else { return false }
        let relativeX = (point.x - imageRect.origin.x) / imageRect.width
        let relativeY = (point.y - imageRect.origin.y) / imageRect.height
        let pixelX = Int(relativeX * CGFloat(image.width))
        let pixelY = Int((1.0 - relativeY) * CGFloat(image.height))
        guard pixelX >= 0 && pixelX < image.width &&
              pixelY >= 0 && pixelY < image.height else {
            return false
        }
        guard let dataProvider = image.dataProvider,
              let data = dataProvider.data else {
            print("Failed to get image data provider for pixel check.")
            return false
        }
        let bytesPerRow = image.bytesPerRow
        let pixelData = CFDataGetBytePtr(data)
        let pixelInfo = pixelY * bytesPerRow + pixelX * 4
        let alpha = pixelData?[pixelInfo + 3] ?? 0
        return alpha > 0
    }

    // MARK: - 性能优化：用Timer替换CVDisplayLink
    private func setupTimer() {
        animationTimer?.invalidate()
        //调帧率
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.02, repeats: true) { [weak self] _ in // 20fps
            guard let self = self else { return }
            self.updatePetState()
            self.setNeedsDisplay(self.bounds)
        }
    }

    deinit {
        animationTimer?.invalidate()
    }

    // MARK: - 鼠标穿透（动态切换 window.ignoresMouseEvents）
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        self.window?.acceptsMouseMovedEvents = true
        let options: NSTrackingArea.Options = [.mouseMoved, .activeAlways, .inVisibleRect]
        let area = NSTrackingArea(rect: self.bounds, options: options, owner: self, userInfo: nil)
        self.addTrackingArea(area)
    }

    override func mouseMoved(with event: NSEvent) {
        guard let window = self.window else { return }
        let point = convert(event.locationInWindow, from: nil)
        let isOpaque = (self.cachedImageRect != nil) && self.isPixelOpaque(at: point, in: self.cachedImageRect!)
        window.ignoresMouseEvents = !isOpaque
    }
}
