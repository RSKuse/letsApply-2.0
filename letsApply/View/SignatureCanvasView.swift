//
//  SignatureCanvasView.swift
//  letsApply
//

import UIKit

final class SignatureCanvasView: UIView {

    var onDrawingStateChanged: ((Bool) -> Void)?

    private var strokes: [[CGPoint]] = []
    private var activeStroke: [CGPoint] = []
    private var pendingNormalizedStrokes: [SignatureStroke] = []

    private lazy var drawingPanGesture: UIPanGestureRecognizer = {
        let gesture = UIPanGestureRecognizer(
            target: self,
            action: #selector(handleDrawingPan(_:))
        )
        gesture.minimumNumberOfTouches = 1
        gesture.maximumNumberOfTouches = 1
        gesture.cancelsTouchesInView = false
        return gesture
    }()

    var drawingGestureRecognizer: UIGestureRecognizer {
        drawingPanGesture
    }

    var hasSignature: Bool {
        !signatureStrokes.isEmpty
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .white
        layer.cornerRadius = AppTheme.cardRadius
        layer.borderColor = AppTheme.border.cgColor
        layer.borderWidth = 1
        isMultipleTouchEnabled = false
        accessibilityLabel = "Signature pad"
        accessibilityHint = "Draw your signature with one finger."
        addGestureRecognizer(drawingPanGesture)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var signatureStrokes: [SignatureStroke] {
        get {
            let allStrokes = activeStroke.isEmpty ? strokes : strokes + [activeStroke]
            return allStrokes
                .filter { $0.count > 1 }
                .map { points in
                    SignatureStroke(points: points.map { point in
                        SignaturePoint(
                            CGPoint(
                                x: point.x / max(bounds.width, 1),
                                y: point.y / max(bounds.height, 1)
                            )
                        )
                    })
                }
        }
        set {
            pendingNormalizedStrokes = newValue
            restorePendingStrokesIfPossible()
            activeStroke = []
            setNeedsDisplay()
        }
    }

    func clear() {
        strokes.removeAll()
        activeStroke.removeAll()
        pendingNormalizedStrokes.removeAll()
        setNeedsDisplay()
    }

    override func layoutSubviews() {
        let previousSize = bounds.size
        super.layoutSubviews()

        restorePendingStrokesIfPossible()
        guard previousSize != .zero, previousSize != bounds.size else { return }
        let xScale = bounds.width / previousSize.width
        let yScale = bounds.height / previousSize.height
        strokes = strokes.map { stroke in
            stroke.map { CGPoint(x: $0.x * xScale, y: $0.y * yScale) }
        }
    }

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        context.setStrokeColor(UIColor.label.cgColor)
        context.setLineWidth(2)
        context.setLineCap(.round)
        context.setLineJoin(.round)

        (strokes + (activeStroke.isEmpty ? [] : [activeStroke])).forEach { stroke in
            guard let firstPoint = stroke.first else { return }
            context.beginPath()
            context.move(to: firstPoint)
            stroke.dropFirst().forEach { context.addLine(to: $0) }
            context.strokePath()
        }

        let baselineY = bounds.height - 20
        context.setStrokeColor(AppTheme.border.cgColor)
        context.setLineWidth(1)
        context.move(to: CGPoint(x: 16, y: baselineY))
        context.addLine(to: CGPoint(x: bounds.width - 16, y: baselineY))
        context.strokePath()
    }

    @objc private func handleDrawingPan(_ gesture: UIPanGestureRecognizer) {
        let point = constrainedPoint(gesture.location(in: self))

        switch gesture.state {
        case .began:
            onDrawingStateChanged?(true)
            activeStroke = [point]
            setNeedsDisplay()
        case .changed:
            guard activeStroke.last.map({ distance(from: $0, to: point) > 0.8 }) ?? true else {
                return
            }
            activeStroke.append(point)
            setNeedsDisplay()
        case .ended:
            finishActiveStroke(with: point)
            onDrawingStateChanged?(false)
        case .cancelled, .failed:
            finishActiveStroke(with: nil)
            onDrawingStateChanged?(false)
        default:
            break
        }
    }

    private func finishActiveStroke(with finalPoint: CGPoint?) {
        if let finalPoint,
           activeStroke.last.map({ distance(from: $0, to: finalPoint) > 0.8 }) ?? true {
            activeStroke.append(finalPoint)
        }

        if activeStroke.count > 1 {
            strokes.append(activeStroke)
        }
        activeStroke = []
        setNeedsDisplay()
    }

    private func constrainedPoint(_ point: CGPoint) -> CGPoint {
        CGPoint(
            x: min(max(point.x, 0), bounds.width),
            y: min(max(point.y, 0), bounds.height)
        )
    }

    private func distance(from first: CGPoint, to second: CGPoint) -> CGFloat {
        hypot(second.x - first.x, second.y - first.y)
    }

    private func restorePendingStrokesIfPossible() {
        guard bounds.width > 1, bounds.height > 1, !pendingNormalizedStrokes.isEmpty else {
            return
        }

        strokes = pendingNormalizedStrokes.map { stroke in
            stroke.points.map {
                CGPoint(
                    x: $0.cgPoint.x * bounds.width,
                    y: $0.cgPoint.y * bounds.height
                )
            }
        }
        pendingNormalizedStrokes.removeAll()
    }
}
