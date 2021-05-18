//
//  UILabel+CornerRadiusShadow.swift
//  verifier-ios
//
//

import UIKit

public extension UIView {
    /// Gets or sets the radius used for rounding the corners of the view.
    @IBInspectable var cornerRadius: CGFloat {
        get {
            return layer.cornerRadius
        }
        set {
            layer.cornerRadius = newValue
        }
    }
    /// Gets or sets the border width of the view.
    @IBInspectable var borderWidth: CGFloat {
        get {
            return layer.borderWidth
        }
        set {
            layer.borderWidth = newValue
        }
    }
    /// Gets or sets the border color of the view.
    @IBInspectable var borderColor: UIColor {
        get {
            if let borderColor = layer.borderColor {
                return UIColor(cgColor: borderColor)
            }
            return UIColor.clear
        }
        set {
            layer.borderColor = newValue.cgColor
        }
    }
    // MARK: - Shadow
    /// Gets or sets the offset of the shadow cast by the view.
    @IBInspectable var shadowOffset: CGSize {
        get {
            return layer.shadowOffset
        }
        set {
            layer.shadowOffset = newValue
        }
    }
    /// Gets or sets the shadow color of the view.
    @IBInspectable var shadowColor: UIColor {
        get {
            if let color = layer.shadowColor {
                return UIColor(cgColor: color)
            }
            return UIColor.clear
        }
        set {
            layer.shadowColor = newValue.cgColor
        }
    }
    /// Gets or sets the shadow opacity of the view.
    @IBInspectable var shadowOpacity: Float {
        get {
            return layer.shadowOpacity
        }
        set {
            layer.shadowOpacity = newValue
        }
    }
    /// Gets or sets the blur radius used to render view's shadow.
    @IBInspectable var shadowRadius: CGFloat {
        get {
            return layer.shadowRadius
        }
        set {
            layer.shadowRadius = newValue
        }
    }
}
