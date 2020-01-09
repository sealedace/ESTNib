//
//  UIView+ESTNib.swift
//  EarnestApp
//
//  Created by Andrew Schreiber on 9/22/15.
//  Copyright © 2015 Earnest Inc. All rights reserved.
//

import UIKit

extension UIView {
    open override func awakeAfter(using coder: NSCoder) -> Any? {
        let nibName = String(reflecting: Mirror(reflecting: self).subjectType)

        guard Bundle.main.path(forResource: nibName, ofType: "nib") != nil else {
            return super.awakeAfter(using: coder)
        }
        
        if !translatesAutoresizingMaskIntoConstraints {
            //Prevents infinite loop from loadNibNamed internally-calling awakeAfterUsingCoder. Is false when called from storyboard, true when called from loadNibNamed.
            let replaced = Bundle.main.loadNibNamed(nibName, owner: nil, options: nil)?.first as! UIView

            transferProperties(to: replaced)
            
            let newConstraints = reparentedConstraints(oldParent: self, newParent: replaced)
            
            // Use reflected children to copy over values
            for view in subviews {
                let subviewConstraint = view.reparentedConstraints(oldParent: self, newParent: replaced)
                view.removeFromSuperview()
                replaced.insertSubview(view, at: replaced.subviews.endIndex)
                view.addConstraints(subviewConstraint)
            }
            
            replaced.addConstraints(newConstraints)
            
            return replaced
        }
        return self
    }
    
    private func transferProperties<T:UIView>(to: T) {
        to.translatesAutoresizingMaskIntoConstraints = false
        to.autoresizingMask = autoresizingMask
        to.isHidden = self.isHidden
        to.tag = tag
        to.isUserInteractionEnabled = self.isUserInteractionEnabled
        to.frame = frame
        to.bounds = bounds
        to.clipsToBounds = clipsToBounds
        
        // Could use better reflection of properties!
    }
    
    private func reparentedConstraints(oldParent:UIView, newParent:UIView) -> [NSLayoutConstraint]
    {
        return constraints.map { constraint -> NSLayoutConstraint in
            let firstItem = oldParent == constraint.firstItem as? UIView ? newParent : constraint.firstItem
            let secondItem = oldParent == constraint.secondItem as? UIView ? newParent : constraint.secondItem
            let newConstraint = NSLayoutConstraint(
                item: firstItem!,
                attribute: constraint.firstAttribute,
                relatedBy: constraint.relation,
                toItem: secondItem,
                attribute: constraint.secondAttribute,
                multiplier: constraint.multiplier,
                constant: constraint.constant)
            
            newConstraint.priority = constraint.priority
            newConstraint.shouldBeArchived = constraint.shouldBeArchived
            newConstraint.identifier = constraint.identifier
            newConstraint.isActive = constraint.isActive
            
            return newConstraint
        }
    }
}
