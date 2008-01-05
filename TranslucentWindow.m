//
//  TranslucentView.m
//
//  Created by Takashi T. Hamada on Thu Nov 01 2000.
//  Copyright (c) 2000,2001 Takashi T. Hamada. All rights reserved.
//
//  Modifications:
//  bb 26.06.2002 - removed the _transparency method
//

#import "TranslucentWindow.h"


@implementation TranslucentWindow

//-------------------------------------------------------------
// set the transparency
//-------------------------------------------------------------
//- (float)_transparency
//{
//    return 0.9999999999;
//}



// Not much here, just calling the following private API.
extern void _NSSetWindowOpacity(int windowNumber, BOOL isOpaque);


//-------------------------------------------------------------
// make the window (pseudo) transparent
//-------------------------------------------------------------
- initWithContentRect:(NSRect)contentRect styleMask:(unsigned int)aStyle backing:(NSBackingStoreType)bufferingType defer:(BOOL)flag
{
    if (self = [super initWithContentRect:contentRect styleMask:aStyle backing:bufferingType defer:flag])
        _NSSetWindowOpacity([self windowNumber], NO);

    [self setAcceptsMouseMovedEvents:YES];	// for dragging itself by receiving the mouse events
    
    return self;
}


//-------------------------------------------------------------
// no shadow is needed
//-------------------------------------------------------------
- (BOOL)hasShadow
{
    return NO;
}


//-------------------------------------------------------------
// For displaying the tooltips with transparent window
//-------------------------------------------------------------
- (BOOL)canBecomeKeyWindow
{
    return YES;
}

@end
