//
//  AccessoryView.swift
//  Nano-iOS
//
//  Created by Richard Henry on 4/13/24.
//

import SwiftUI
import UIKit

final class AccessoryView: UIView {
    @Observable class AccessorySize {
        var width: CGFloat = 300
    }

    struct ContentModifier: ViewModifier {
        var size: AccessorySize

        func body(content: Content) -> some View {
            // Improve layout performance by providing a fixed width to the accessory content.
            content.frame(width: size.width)
        }
    }

    let hostingController: UIViewController
    let backgroundView = UIVisualEffectView(effect: UIBlurEffect(style: .regular))
    let accessorySize: AccessorySize
    weak var associatedScrollView: UIScrollView?

    var contentView: UIView {
        hostingController.view
    }

    init<RootView: View>(rootView: RootView) {
        let size = AccessorySize()

        hostingController = {
            let rootView = rootView.modifier(ContentModifier(size: size))
            let hostingController = UIHostingController(rootView: rootView)
            hostingController.safeAreaRegions = []
            hostingController.sizingOptions = .intrinsicContentSize
            return hostingController
        }()

        accessorySize = size

        super.init(frame: .zero)

        contentView.backgroundColor = .clear

        addSubview(backgroundView)
        addSubview(contentView)

        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            backgroundView.topAnchor.constraint(equalTo: contentView.topAnchor),
            backgroundView.leadingAnchor.constraint(equalTo: leadingAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: bottomAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: trailingAnchor),
            contentView.topAnchor.constraint(greaterThanOrEqualTo: safeAreaLayoutGuide.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: keyboardLayoutGuide.topAnchor),
            contentView.widthAnchor.constraint(equalTo: safeAreaLayoutGuide.widthAnchor),
            contentView.centerXAnchor.constraint(equalTo: safeAreaLayoutGuide.centerXAnchor),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        contentView.frame.contains(point)
    }

    override func didMoveToSuperview() {
        super.didMoveToSuperview()

        if let superview = superview {
            translatesAutoresizingMaskIntoConstraints = false
            topAnchor.constraint(equalTo: superview.topAnchor).isActive = true
            leadingAnchor.constraint(equalTo: superview.leadingAnchor).isActive = true
            bottomAnchor.constraint(equalTo: superview.bottomAnchor).isActive = true
            trailingAnchor.constraint(equalTo: superview.trailingAnchor).isActive = true
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        accessorySize.width = contentView.bounds.width

        associatedScrollView?.verticalScrollIndicatorInsets.bottom = contentView.bounds.height
        associatedScrollView?.contentInset.bottom = contentView.bounds.height
    }
}
