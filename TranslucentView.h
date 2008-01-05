//
//  TranslucentView.h
//
//  Created by Takashi T. Hamada on Thu Nov 01 2000.
//  Copyright (c) 2000,2001 Takashi T. Hamada. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface TranslucentView : NSView
{
    id				theContentDrawer;
    SEL				theDrawingMethod;

    NSTrackingRectTag		calBGViewRectTag;
    float			ImageOpacity;
}

- (void)mouseDown:(NSEvent *)theEvent;
- (void)setContentDrawer:(id)theDrawer method:(SEL)theMethod;

@end
