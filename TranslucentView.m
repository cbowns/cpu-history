//
//  TranslucentView.m
//
//  Created by Takashi T. Hamada on Thu Nov 01 2000.
//  Copyright (c) 2000,2001 Takashi T. Hamada. All rights reserved.
//
//  Modifications:
//  bb 25.06.2002 - added acceptsFirstMouse method for click-through
//  bb 26.06.2002 - removed the isOpaque method
//

#import "TranslucentView.h"


@implementation TranslucentView

//-------------------------------------------------------------
//	initialization
//-------------------------------------------------------------
- (id)initWithFrame:(NSRect)frameRect
{
    self = [super initWithFrame:frameRect];
    calBGViewRectTag = [self addTrackingRect:[self frame] owner:self userData:&ImageOpacity assumeInside:YES];
    theContentDrawer = nil;

    return self;
}


//-------------------------------------------------------------
//	draw translucent rectangle
//-------------------------------------------------------------
- (void)drawRect:(NSRect)rect
{
    [[NSColor clearColor] set];
    NSRectFill( rect );

    // draw the content
    if (theContentDrawer != nil)
	[theContentDrawer performSelector:theDrawingMethod];
}


//-------------------------------------------------------------
//	is this necessary?
//-------------------------------------------------------------
//- (BOOL)isOpaque	{ return NO; }


//-------------------------------------------------------------
//	move the window
//-------------------------------------------------------------
- (void)mouseDown:(NSEvent *)theEvent
{
    BOOL 		keepOn = YES;
    NSPoint 		mouseLoc;
    NSPoint		globalMouseLoc;
    NSPoint		offsetMouseLoc;
    NSPoint		tempWindowLoc;
    NSRect		origFrame;

    offsetMouseLoc.x = offsetMouseLoc.y = 0;	// avoid uninitialized warning
    origFrame = [[self window] frame];
    while( 1 ) {	// gee! entering into the infinity loop...
	mouseLoc = [self convertPoint:[theEvent locationInWindow] fromView:nil];

	switch ([theEvent type]) {
	    case NSLeftMouseDown:
		// save the initial mouse location
		offsetMouseLoc = mouseLoc;				
		break;
	    case NSLeftMouseDragged:
		// get the mouse location in the global coordinates
		globalMouseLoc = [[self window] convertBaseToScreen:mouseLoc];
		// calculate the new origin of the window
		tempWindowLoc.x = (globalMouseLoc.x - offsetMouseLoc.x);
		tempWindowLoc.y = (globalMouseLoc.y - offsetMouseLoc.y);
		// get the window's location and size in the global coodinate system
		[[self window] setFrameOrigin:tempWindowLoc];	// move and resize the window
		break;
	    case NSLeftMouseUp:
		keepOn = NO;
		break;
	    default:
		break;
        }
	if (keepOn == NO)
	    break;

	theEvent = [[self window] nextEventMatchingMask:(NSLeftMouseUpMask | NSLeftMouseDraggedMask) ];
     };

    return;
}


//-------------------------------------------------------------
//	set the transparency of this view
//-------------------------------------------------------------
- (void)setContentDrawer:(id)theDrawer method:(SEL)theMethod
{
    theContentDrawer = theDrawer;
    theDrawingMethod = theMethod;
}


//-------------------------------------------------------------
//	allow click-through
//-------------------------------------------------------------
- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent
{
    return (YES);
}

@end
