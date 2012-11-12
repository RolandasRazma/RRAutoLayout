//
//  UIView+RRConstraintBasedLayout.m
//  RRAutoLayout
//
//  Copyright (c) 2012 Rolandas Razma <rolandas@razma.lt>
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

#import "UIView+RRConstraintBasedLayout.h"
#import "RRLayoutConstraint.h"


static inline float CGRectAttribute(CGRect rect, RRLayoutAttribute attribute){
    
    switch ( attribute ) {
        case RRLayoutAttributeLeading:
            return rect.origin.x;
        case RRLayoutAttributeTop:
            return rect.origin.y;
        case RRLayoutAttributeBottom:
            return rect.origin.y +rect.size.height;
        case RRLayoutAttributeTrailing:
            return rect.origin.x +rect.size.width;
        default:
            NSLog(@"CGRectAttribute %i", attribute);
            break;
    }
    
    return 0.0f;
}


static inline void CGRectAddAttribute(CGRect *rect, RRLayoutAttribute attribute1, CGRect rect2, RRLayoutAttribute attribute2, CGFloat c){
    
    
    switch ( attribute1 ) {
        case RRLayoutAttributeLeading: {
            rect->origin.x = CGRectAttribute(rect2, attribute2) +c;
            break;
        }
        case RRLayoutAttributeTop: {
            rect->origin.y = CGRectAttribute(rect2, attribute2) +c;
            break;
        }
        case RRLayoutAttributeBottom: {
            //what happen if we get RRLayoutAttributeBottom before RRLayoutAttributeHeight?
            rect->origin.y = CGRectAttribute(rect2, attribute2) -c -rect->size.height;
            break;
        }
        case RRLayoutAttributeTrailing: {
            //what happen if we get RRLayoutAttributeTrailing before RRLayoutAttributeLeading?
            rect->size.width = CGRectAttribute(rect2, attribute2) -c -rect->origin.x;
            break;
        }
        default:
            NSLog(@"%i + %@ %i", attribute1, NSStringFromCGRect(rect2), attribute2);
            break;
    }
    
}


@implementation UIView (RRConstraintBasedLayout)


#pragma mark -
#pragma mark NSObject


+ (void)load {
    
    if( ![[UIView class] respondsToSelector:@selector(requiresConstraintBasedLayout)] ){
        REPLACE_METHOD([UIView class], @selector(layoutSublayersOfLayer:),  @selector(rr_r_layoutSublayersOfLayer:))
        REPLACE_METHOD([UIView class], @selector(initWithCoder:),           @selector(rr_r_initWithCoder:))
        REPLACE_METHOD([UIView class], @selector(layoutSubviews),           @selector(rr_r_layoutSubviews))
        REPLACE_METHOD([UIView class], @selector(setTransform),             @selector(rr_r_setTransform))
        REPLACE_METHOD([UIView class], @selector(setCenter),                @selector(rr_r_setCenter))
        REPLACE_METHOD([UIView class], @selector(setBounds),                @selector(rr_r_setBounds))

        ADD_METHOD([UIView class], @selector(constraints),                  @selector(rr_a_constraints))
        ADD_METHOD([UIView class], @selector(addConstraint:),               @selector(rr_a_addConstraint:))
        ADD_METHOD([UIView class], @selector(addConstraints:),              @selector(rr_a_addConstraints:))
        ADD_METHOD([UIView class], @selector(updateConstraints),            @selector(rr_a_updateConstraints))
        ADD_METHOD([UIView class], @selector(updateConstraintsIfNeeded),    @selector(rr_a_updateConstraintsIfNeeded))
        ADD_METHOD([UIView class], @selector(setNeedsUpdateConstraints),    @selector(rr_a_setNeedsUpdateConstraints))
    }
    
}


#pragma mark -
#pragma mark NSCoder


- (id)rr_r_initWithCoder:(NSCoder *)aDecoder {
    id _self = [self rr_r_initWithCoder:aDecoder];

    if ( [aDecoder containsValueForKey:@"UIViewAutolayoutConstraints"] ){
        [_self addConstraints: [aDecoder decodeObjectForKey:@"UIViewAutolayoutConstraints"]];
    }
    
    return _self;
}


#pragma mark -
#pragma mark UIConstraintBasedLayout


- (void)rr_r_layoutSublayersOfLayer:(CALayer *)layer {
    [self updateConstraintsIfNeeded];
    [self rr_r_layoutSublayersOfLayer:layer];
}


- (void)rr_a_updateConstraintsIfNeeded {
    NSNumber *constraintsAreClean = objc_getAssociatedObject(self, "rr_constraintsAreClean");
    if( !constraintsAreClean || [constraintsAreClean boolValue] == NO ){
        [self updateConstraints];
        [self.subviews makeObjectsPerformSelector:@selector(updateConstraintsIfNeeded)];
        
        objc_setAssociatedObject(self, "rr_constraintsAreClean", @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}


- (void)rr_a_updateConstraints {
    [self rr_updateContentSizeConstraints];
    [self rr_updateAutoresizingConstraints];
}


- (void)rr_updateAutoresizingConstraints {

}


- (void)rr_updateContentSizeConstraints {

}


- (void)rr_informContainerThatSubviewsNeedUpdateConstraints {
    if( self.superview ){
        [self.superview setNeedsLayout];
    }
}


- (void)rr_a_setNeedsUpdateConstraints {
    objc_setAssociatedObject(self, "rr_constraintsAreClean", @NO, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self rr_informContainerThatSubviewsNeedUpdateConstraints];
}


- (NSArray *)rr_a_constraints {
    NSMutableArray *internalConstraints = objc_getAssociatedObject(self, "rr_internalConstraints");
    if( !internalConstraints ){
        internalConstraints = [NSMutableArray array];
        objc_setAssociatedObject(self, "rr_internalConstraints", internalConstraints, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return internalConstraints;
}


- (void)rr_a_addConstraint:(NSLayoutConstraint *)constraint {
    NSMutableArray *internalConstraints = objc_getAssociatedObject(self, "rr_internalConstraints");
    if( !internalConstraints ){
        internalConstraints = [NSMutableArray array];
        objc_setAssociatedObject(self, "rr_internalConstraints", internalConstraints, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    [internalConstraints addObject:constraint];
    
    // Sort constraints by priority
    [internalConstraints sortUsingComparator:^NSComparisonResult(NSLayoutConstraint *constraint1, NSLayoutConstraint *constraint2) {
        return constraint1.priority < constraint2.priority;
    }];

    [self setNeedsUpdateConstraints];
}


- (void)rr_a_addConstraints:(NSArray *)sonstraints {

    for( NSLayoutConstraint *constraint in sonstraints ){
        [self addConstraint:constraint];
    }

}


#pragma mark -
#pragma mark UIView


- (void)rr_r_layoutSubviews {
    
    NSArray *constraints = self.constraints;
    if( constraints.count ){
        [self.subviews enumerateObjectsWithOptions: NSEnumerationConcurrent
                                        usingBlock: ^(UIView *view, NSUInteger idx, BOOL *stop) {
                                            
                                            // Try to get possible size of view from it's internal constrains
                                            CGSize futureViewSize = CGSizeZero;
                                            for( NSLayoutConstraint *layoutConstraint in view.constraints ){
                                                if( [view isEqual: layoutConstraint.firstItem] && !layoutConstraint.secondItem ) {
                                                    if( layoutConstraint.firstAttribute == RRLayoutAttributeWidth ){
                                                        futureViewSize.width = layoutConstraint.constant;
                                                    }else if( layoutConstraint.firstAttribute == RRLayoutAttributeHeight ){
                                                        futureViewSize.height = layoutConstraint.constant;
                                                    }
                                                }
                                            }

                                            // Calculate bounds and center
                                            CGRect  bounds = CGRectMake(0, 0, futureViewSize.width, futureViewSize.height);
                                            CGPoint center = CGPointZero;
                                            for( NSLayoutConstraint *layoutConstraint in constraints ){

                                                if( [view isEqual: layoutConstraint.firstItem] ){

                                                    CGRectAddAttribute(&bounds,
                                                                       layoutConstraint.firstAttribute,
                                                                       [(UIView *)layoutConstraint.secondItem bounds],
                                                                       layoutConstraint.secondAttribute,
                                                                       layoutConstraint.constant);

                                                }else if( [view isEqual:layoutConstraint.secondItem] ){
                                                    
                                                    CGRectAddAttribute(&bounds,
                                                                       layoutConstraint.secondAttribute,
                                                                       [(UIView *)layoutConstraint.firstItem bounds],
                                                                       layoutConstraint.firstAttribute,
                                                                       layoutConstraint.constant);
                                                    
                                                }
                                                
                                            }

                                            center = CGPointMake(bounds.origin.x +bounds.size.width /2, bounds.origin.y +bounds.size.height /2);
                                            bounds.origin = CGPointZero;
                                            
                                            [view setBounds:bounds];
                                            [view setCenter:center];
                                        }];
    }

    [self rr_r_layoutSubviews];
}


- (void)rr_r_setTransform:(CGAffineTransform)transform {
    [self rr_r_setTransform:transform];
    [self setNeedsUpdateConstraints];
}


- (void)rr_r_setCenter:(CGPoint)center {
    [self rr_r_setCenter:center];
    [self setNeedsUpdateConstraints];
}


- (void)rr_r_setBounds:(CGRect)bounds {
    [self rr_r_setBounds:bounds];
    [self setNeedsUpdateConstraints];
}


@end