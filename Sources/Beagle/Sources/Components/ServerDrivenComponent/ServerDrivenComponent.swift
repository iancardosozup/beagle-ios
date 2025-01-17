/*
 * Copyright 2020, 2022 ZUP IT SERVICOS EM TECNOLOGIA E INOVACAO SA
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import UIKit

public protocol ServerDrivenComponent: Decodable, Renderable {}

@available(*, deprecated, message: "Since version 1.10. Declarative screen construction will be removed in 2.0")
public protocol ComposeComponent: ServerDrivenComponent {
    func build() -> ServerDrivenComponent
}

extension ComposeComponent {
    public func toView(renderer: BeagleRenderer) -> UIView {
        return renderer.render(build())
    }
}

extension ServerDrivenComponent {
    @available(*, deprecated, message: "Since version 1.10. Declarative screen construction will be removed in 2.0")
    public func toScreen() -> Screen {
        let screen = self as? ScreenComponent
        let safeArea = screen?.safeArea
            ?? SafeArea(top: true, leading: true, bottom: true, trailing: true)

        if let analytics = screen?.screenAnalyticsEvent {
            return Screen(
                identifier: screen?.identifier,
                style: screen?.style,
                safeArea: safeArea,
                navigationBar: screen?.navigationBar,
                screenAnalyticsEvent: analytics,
                child: screen?.child ?? self,
                context: screen?.context
            )
        } else {
            return Screen(
                identifier: screen?.identifier ?? getFirstChildContainerId(),
                style: screen?.style,
                safeArea: safeArea,
                navigationBar: screen?.navigationBar,
                child: screen?.child ?? self,
                context: screen?.context
            )
        }
    }
    
    private func getFirstChildContainerId() -> String? {
        let child = self as? Beagle.Container
        return child?.id
    }
}

public protocol Renderable {

    /// here is where your component should turn into a UIView. If your component has child components,
    /// let *renderer* do the job to render those children into UIViews; don't call this method directly
    /// in your children.
    func toView(renderer: BeagleRenderer) -> UIView
}

extension UnknownComponent {

    public func toView(renderer: BeagleRenderer) -> UIView {
        #if DEBUG
        let label = UILabel(frame: .zero)
        label.numberOfLines = 2
        label.text = "Unknown Component of type:\n \(String(describing: type))"
        label.textColor = .red
        label.backgroundColor = .yellow
        return label
        #else
        let view = UIView()
        return view
        #endif
    }
    
}
