//
//  AccessoryModifier.swift
//  Nano-iOS
//
//  Created by Richard Henry on 4/13/24.
//

import SwiftUI
@_spi(Advanced) import SwiftUIIntrospect
import UIKit

public struct AccessoryModifier<RootView: View>: ViewModifier {
    public let rootView: () -> (RootView)
    @Weak var viewController: UIViewController?
    @Weak var scrollView: UIScrollView?

    var accessoryView: AccessoryView? {
        viewController?.view.subviews.first { $0 is AccessoryView } as? AccessoryView
    }

    public init(rootView: @escaping () -> (RootView)) {
        self.rootView = rootView
    }

    public func body(content: Content) -> some View {
        content
            .scrollDismissesKeyboard(.interactively)
            .introspect(.scrollView, on: .iOS(.v16...)) { scrollView in
                self.scrollView = scrollView
                setupIfNeeded()
            }
            .introspect(.viewController, on: .iOS(.v16...)) { viewController in
                self.viewController = viewController
                setupIfNeeded()
            }
    }

    func setupIfNeeded() {
        guard let viewController, let scrollView, accessoryView == nil else {
            return
        }

        let accessoryView = AccessoryView(rootView: rootView())
        accessoryView.associatedScrollView = scrollView

        viewController.addChild(accessoryView.hostingController)
        viewController.view.addSubview(accessoryView)
        accessoryView.hostingController.didMove(toParent: viewController)
    }
}
