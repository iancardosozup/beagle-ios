/*
 * Copyright 2020 ZUP IT SERVICOS EM TECNOLOGIA E INOVACAO SA
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

public protocol DependencyRenderer {
    var renderer: (BeagleController) -> BeagleRenderer { get set }
}

/// Use this class whenever you want to transform a Component into a UIView
public struct BeagleRenderer {

    public let dependencies: BeagleDependenciesProtocol
    public private(set) weak var controller: BeagleController?

    internal init(controller: BeagleController) {
        self.controller = controller
        self.dependencies = controller.dependencies
    }

    /// main function of this class. Call it to transform a Component into a UIView
    public func render(_ component: ServerDrivenComponent) -> UIView {
        let view = component.toView(renderer: self)
        return setupView(view, of: component)
    }

    public func render(_ children: [ServerDrivenComponent]) -> [UIView] {
        return children.map { render($0) }
    }

    private func setupView(_ view: UIView, of component: ServerDrivenComponent) -> UIView {
        view.beagle.setupView(of: component)
        view.componentType = type(of: component)
        
        if let id = (component as? IdentifiableComponent)?.id {
            controller?.setIdentifier(id, in: view)
        }
        if let context = (component as? HasContext)?.context {
            controller?.setContext(context, in: view)
        }
        if let onInit = (component as? InitiableComponent)?.onInit {
            controller?.addOnInit(onInit, in: view)
        }
        if let style = (component as? StyleComponent)?.style {
            observe(style: style, in: view)
            if let radius = style.cornerRadius {
                return BorderView(
                    content: view,
                    cornerRadius: radius,
                    borderWidth: style.borderWidth,
                    borderColor: style.borderColor,
                    margin: style.margin
                )
            }
        }
        return view
    }
    
    private func observe(style: Style, in view: UIView) {
        if let displayExpression = style.display {
            observe(displayExpression, andUpdateManyIn: view) { [weak view] display in
                guard let display = display else { return }
                view?.yoga.display = YogaTranslating().translate(display)
            }
        }
    }
}

// MARK: - Observe Expressions

public extension BeagleRenderer {

    typealias Mapper<From, To> = (From) -> To

    // MARK: Property of same Expression's Value

    func observe<Value, View: UIView>(
        _ expression: Expression<Value>?,
        andUpdate keyPath: ReferenceWritableKeyPath<View, Value?>,
        in view: View,
        map: Mapper<Value?, Value?>? = nil
    ) {
        if let expression = expression {
            expression.observe(view: view, controller: controller) { [weak view] value in
                view?[keyPath: keyPath] = map?(value) ?? value
            }
        } else if let map = map {
            view[keyPath: keyPath] = map(nil)
        }
    }

    // MARK: Property with different type than expression

    func observe<Value, View: UIView, Property>(
        _ expression: Expression<Value>?,
        andUpdate keyPath: ReferenceWritableKeyPath<View, Property>,
        in view: View,
        map: @escaping Mapper<Value?, Property>
    ) {
        observe(expression, andUpdateManyIn: view) { [weak view] in
            view?[keyPath: keyPath] = map($0)
        }
    }

    // MARK: Update various properties (not just 1) in view

    /// will call `updateFunction` even when `expression` is nil
    func observe<Value>(
        _ expression: Expression<Value>?,
        andUpdateManyIn view: UIView,
        updateFunction: @escaping (Value?) -> Void
    ) {
        if let exp = expression {
            exp.observe(view: view, controller: controller, updateFunction: updateFunction)
        } else {
            updateFunction(nil)
        }
    }

    func observe<Value>(
        _ expression: Expression<Value>,
        andUpdateManyIn view: UIView,
        updateFunction: @escaping (Value?) -> Void
    ) {
        expression.observe(view: view, controller: controller, updateFunction: updateFunction)
    }

    // TODO: should we make `observeMany` to simplify this to users?
}
