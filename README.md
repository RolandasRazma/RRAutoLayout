RRAutoLayout
============

**iOS6** [AutoLayout](https://developer.apple.com/library/ios/#documentation/UserExperience/Conceptual/AutolayoutPG/Articles/Introduction.html) backport to **iOS5**

Disclaimer
============
I assume you are advanced iOS developer, know most of its internals and understand that this code/article is more proof of concept than working port (even if it kind of works).

What you will find inside
============
If you fork, you will find workspace with 2 projects **RRTestApp** and **RRAutoLayout**.<br />
**RRTestApp** has [constraints](https://developer.apple.com/library/ios/#documentation/UserExperience/Conceptual/AutolayoutPG/Articles/constraintFundamentals.html#//apple_ref/doc/uid/TP40010853-CH2-SW1) based layout and all constrains added in interface builder like you normally would do for iOS6, whats interesting is that it has deployment target iOS5. You can run same project on iOS6 and iOS5 and it should look and behave (when rotating) the same. Essentially its iOS6 [AutoLayout]((https://developer.apple.com/library/ios/#documentation/UserExperience/Conceptual/AutolayoutPG/Articles/Introduction.html)) back port to iOS5

I don't have blog so...
============
After submitting [@YPlan](http://yplanapp.com) to Apple AppStore I wanted to do something cool and relaxing, and what can be more relaxing then fiddling around Apple iOS internals? (you know you see sometimes in my tweets that I did `#import <objc/runtime.h>`) So I decided to figure out how **iOS6** **AutoLayout** works internally and if possible port it to **iOS5** (at least part of it).<br />
Well, just hack porting might be quite simple so I wanted to port it Apple way - call by call compatible with iOS6, on iOS6 it should fallback to iOS6 default implementation and leave no trace, it has to be completely transparent to developer (no extra imports, no class renaming, constraints has to load from **Interface Builder**) and no private API calls - so it should be AppStore valid. So the goal is: if developer wrote correct constraints for iOS6 they should jus start automatically work on iOS5 without any changes in code or Interface Builder. How hard it can be? :)<br />
I already had some experience with revere engineering Apple API's when I did `NSPDFKit` port to iOS while working [@UD7](http://ud7.com) so already knew where to start.<br /><br />
First, I need headers, and for that there is magic tool called `class-dump`. So `class-dump -Hsr ...` and we have headers that interests us.<br />
Next we need call tree we want to build. For that I already had some scripts left from my `NSPDFKit` port so after some trickery we have nice looking trees: [/RRAutoLayout/Extras/](https://github.com/RolandasRazma/RRAutoLayout/tree/master/Extras) - quick look at them and you can see how part of Apple iOS6 internals get executed.<br />
<a target='_blank' title='ImageShack - Image And Video Hosting' href='http://imageshack.us/photo/my-images/189/callstack.jpg/'><img src='http://img189.imageshack.us/img189/2086/callstack.jpg' border='0'/></a><br />
Keep in mind, that those are only call trees of iOS6 parts what I'm interested in and not complete ones.<br />
We are interested in flows that hit `*constraints*` - quite a few...<br />
Now the fun part: implement most of those flows to get AutoLayout working on iOS5 :)<br />
<br />
So first things first, I created workspace with 2 projects **RRTestApp** and **RRAutoLayout**. In theory, you need only to drop **4 files** (and copy macro) from **RRAutoLayout** to your project (no includes needed) and simple constraints should just start working. Alternately you can link against `libRRAutoLayout` (with -ObjC).<br />
So first lets fix errors you getting by running constraints containing project on iOS5. Error you see is because unarchiving compiled Interface Builder files runtime can’t find `NSLayoutConstraints`. So the obvious solution is to create class with same name. Remember I wrote "fall back to default iOS6 implementation when running on iOS6"? So we can't just create `NSLayoutConstraint` class because it would conflict with default Apple one on iOS6. We need a way to create it on runtime in iOS5 but not iOS6 - and for that we will use magic of `<objc/runtime.h>` `objc_registerClassPair`.<br />
First lets check if `NSLayoutConstraints` is present and if not we will rename our class (`RRLayoutConstraint`) to `NSLayoutConstraint` so:
```objc
if( !NSClassFromString(@"NSLayoutConstraint") ){
    objc_registerClassPair(objc_allocateClassPair([RRLayoutConstraint class], "NSLayoutConstraint", 0));
}
```
Nice, project starts without errors, but we see nothing on the screen. First we need to populate our class with data from `XIB` unarchiver. This is quit easy, just `[aDecoder decodeIntegerForKey:@"..."]` and set it where it belongs.<br />
Now we have our `NSLayoutConstraint` with all data from Interface Builder, but it gets `dealloc`'ed as soon as it created - we need to hold onto it. From Apple docs we see that `UIView` holds all its constraints, but views on iOS5 don't have all those ivars and methods to hold them...<br />
Adding methods is quite easy, everyone who reads this is already familiar with categories and if not..., well you shouldn't be reading this :) So as I wrote - we need clever way to store constraints in `UIView` on iOS5 and leverage all of its memory management. Lets start with `-[UIView constraints]` and `-[UIView addConstraint:]`. 
We don't want just drop those into category of `UIView` because they would conflict on iOS6 default implementation, so we need magic of `<objc/runtime.h>` again. First lets check if we not running in iOS6 `if( ![[UIView class] respondsToSelector:@selector(requiresConstraintBasedLayout)] )` if not - insert our custom implementation of methods with default names of iOS6 - `class_addMethod`.<br />
Ok, so far so good, we have nonconflicting implementation in iOS5 witch does nothing in iOS6, now... were to store those constraints... (as you know categories don't have ivars). For this we will use quite new `<objc/runtime.h>` magic (this works from 10.6 as I remember) `objc_setAssociatedObject`. 
```objc
- (void)rr_a_addConstraint:(NSLayoutConstraint *)constraint {
    NSMutableArray *internalConstraints = objc_getAssociatedObject(self, "rr_internalConstraints");
    if( !internalConstraints ){
        internalConstraints = [NSMutableArray array];
        objc_setAssociatedObject(self, "rr_internalConstraints", internalConstraints, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    [internalConstraints addObject:constraint];
    
    ...
}
```
Still with me? :) so what we just did is "Sets an associated value for a given object using a given key and association policy.".<br />
So the easiest part is done - we loaded constraints and have them stored on `UIView` now we need all custom logic to use them Apple way and for that lets look at the cal tree of starting the app [/Extras/app-start.html](https://github.com/RolandasRazma/RRAutoLayout/tree/master/Extras) As you can see there is quite few methods with *constraints* and even more hitting them. We already inserted non conflicting (iOS6/iOS5) methods now lets look how to call them from default apple methods what already exists on iOS5. For that we will use `<objc/runtime.h>` magic again. This time `method_exchangeImplementations`. I assume you already know how to do that so won't go into deep explanation how it works. 
Everything is straight forward: find *constraints* methods, look witch methods calls them on iOS6, and add same call paths to iOS5.<br />
Ok, we have constraints stored on `UIView`, and call paths that use them...<br />
Now the fun part (and not completely implemented) - all custom logic of applying constraints. <br />
<br />
And here I failed miserably, it looks like constrains are applied deep inside `-[UIView layoutSubviews]` but `-[UIView setFrame:]` isn't used. After few hours poking around I found that frame is updated with `-[UIView setBounds:]` and `-[UIView setCenter:]` as trace was showing... I was ignoring them as I was looking for `setFrame:`... After I found how frame was changed I started to think why, later I figured out that to avoid layout invalidation!<br />
<br />
After that things started move faster again. Trace shows that layout manager does all updating when `-[UIView layoutSubviews]` asks for it, but layout manager is all private and I want my implementation be AppStore valid, so I added all logic to `-[UIView layoutSubviews]` itself. Constraints logic isn't easy to debug and implement, so if you feel like you know better way to do it, or want add missing implementations feel free to do that and of course send pull request :)

[Matthew Scott pointed out](http://stacks.11craft.com/cassowary-cocoa-autolayout-and-enaml-constraints.html) that Cocoa Autolayout uses [Cassowary](http://www.cs.washington.edu/research/constraints/cassowary/) constraint solver. Wonder how hard would it be to add it to have complete port - anyone wants to try and send pull request? :)
