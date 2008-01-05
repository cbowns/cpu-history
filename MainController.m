/*
 *	Memory Monitor
 *
 *	Copyright © 2001-2003 Bernhard Baehr
 *
 *	MainController.m - Main Application Controller Class
 *
 *	This program is free software; you can redistribute it and/or modify
 *	it under the terms of the GNU General Public License as published by
 *	the Free Software Foundation; either version 2 of the License, or
 *	(at your option) any later version.
 *
 *	This program is distributed in the hope that it will be useful,
 *	but WITHOUT ANY WARRANTY; without even the implied warranty of
 *	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *	GNU General Public License for more details.
 *
 *	You should have received a copy of the GNU General Public License
 *	along with this program; if not, write to the Free Software
 *	Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 */


#import "MainController.h"


#define GRAPH_SIZE	128


@implementation MainController


- (void)drawImageOnWindow
{
	[displayImage drawInRect:NSMakeRect(0, 0, NSWidth([window frame]), NSHeight([window frame]))
		fromRect:NSMakeRect(0, 0, GRAPH_SIZE, GRAPH_SIZE) operation:NSCompositeCopy
		fraction:1.0];
}


- (void)showHideWindow
{
	float	size;
	
	if ([[preferences objectForKey:SHOW_GRAPH_WINDOW_KEY] boolValue]) {
		size = [[preferences objectForKey:GRAPH_WINDOW_SIZE_KEY] floatValue];
		[window setContentSize:NSMakeSize(size, size)];
		[window orderWindow:NSWindowBelow relativeTo:[preferences windowNumber]];
		[window setLevel:([[preferences objectForKey:GRAPH_WINDOW_ON_TOP_KEY] boolValue] ?
			NSFloatingWindowLevel : NSNormalWindowLevel)];
	} else
		[window orderOut:self];
}


- (void)drawPageins:(int)pageins pageouts:(int)pageouts
{
	int			paging;
	NSString		*string;
	NSMutableDictionary	*fontAttrs;
	
	// draw paging rate into the icon image
	if ([[preferences objectForKey:SHOW_PAGING_RATE_KEY] boolValue]) {
		paging = (pageins + pageouts) / (0.1 * [[preferences objectForKey:UPDATE_FREQUENCY_KEY] floatValue]);
		if (paging != 0) {
			if (pageins == 0)
				string = NSLocalizedString(@"out", @"");
			else if (pageouts == 0)
				string = NSLocalizedString(@"in", @"");
			else
				string = NSLocalizedString(@"i/o", @"");
			fontAttrs = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
				[NSFont boldSystemFontOfSize:48.0], NSFontAttributeName,
				[NSColor blackColor], NSForegroundColorAttributeName,
				nil];
			[string drawAtPoint:NSMakePoint(4.0, 60.0) withAttributes:fontAttrs];
			[fontAttrs setObject:[NSColor whiteColor] forKey:NSForegroundColorAttributeName];
			[string drawAtPoint:NSMakePoint(2.0, 62.0) withAttributes:fontAttrs];
			string = [NSString stringWithFormat:@"%d", paging];
			[fontAttrs setObject:[NSColor blackColor] forKey:NSForegroundColorAttributeName];
			[string drawAtPoint:NSMakePoint(4.0, 12.0) withAttributes:fontAttrs];
			[fontAttrs setObject:[NSColor whiteColor] forKey:NSForegroundColorAttributeName];
			[string drawAtPoint:NSMakePoint(2.0, 14.0) withAttributes:fontAttrs];
			[fontAttrs release];
		}
	}
}


- (void)drawComplete
// completely redraw graphImage, put graph and pageing rate into displayImage
{	
	VMData			vmdata;
	int			lastpageins, lastpageouts, x;
	float			y, yy;
	
	BOOL pageinAtopPageout = [[preferences objectForKey:PAGEIN_ATOP_PAGEOUT_KEY] boolValue];
	double pagingmax = [[preferences objectForKey:PAGING_SCALE_MAX_KEY] doubleValue];
	double interval = 0.1 * [[preferences objectForKey:UPDATE_FREQUENCY_KEY] floatValue];
	double pgfactor = 1.0 / (pagingmax * interval);
	
	[graphImage lockFocus];

	// draw the memory usage graph
	[memInfo startIterate];
	for (x = 0; [memInfo getNext:&vmdata]; x++) {
		y = vmdata.wired * GRAPH_SIZE;
		[[preferences objectForKey:WIRED_COLOR_KEY] set];
		NSRectFill (NSMakeRect(x - 1, 0.0, x, y));
		yy = y;
		y += vmdata.active * GRAPH_SIZE;
		[[preferences objectForKey:ACTIVE_COLOR_KEY] set];
		NSRectFill (NSMakeRect(x - 1, yy, x, y));
		yy = y;
		y += vmdata.inactive * GRAPH_SIZE;
		[[preferences objectForKey:INACTIVE_COLOR_KEY] set];
		NSRectFill (NSMakeRect(x - 1, yy, x, y));
		[[preferences objectForKey:FREE_COLOR_KEY] set];
		NSRectFill (NSMakeRect(x - 1, y, x, GRAPH_SIZE));
	}

	// draw the paging curves on top of the memory usage graph
	[memInfo startIterate];
	for (lastpageins = lastpageouts = x = 0; [memInfo getNext:&vmdata]; x++) {
		if (pageinAtopPageout) {
			y = GRAPH_SIZE * (1.0 - vmdata.pageins * pgfactor);
			yy = GRAPH_SIZE * (1.0 - lastpageins * pgfactor);
		} else {
			y = GRAPH_SIZE * vmdata.pageins * pgfactor;
			yy = GRAPH_SIZE * lastpageins * pgfactor;
		}
		[[preferences objectForKey:PAGEIN_COLOR_KEY] set];
		[NSBezierPath strokeLineFromPoint:NSMakePoint(x, yy) toPoint:NSMakePoint(x+1, y)];	
		if (pageinAtopPageout) {
			y = GRAPH_SIZE * vmdata.pageouts * pgfactor;
			yy = GRAPH_SIZE * lastpageouts * pgfactor;
		} else {
			y = GRAPH_SIZE * (1.0 - vmdata.pageouts * pgfactor);
			yy = GRAPH_SIZE * (1.0 - lastpageouts * pgfactor);
		}
		[[preferences objectForKey:PAGEOUT_COLOR_KEY] set];
		[NSBezierPath strokeLineFromPoint:NSMakePoint(x, yy) toPoint:NSMakePoint(x+1, y)];			
		lastpageins = vmdata.pageins;
		lastpageouts = vmdata.pageouts;
	}
	
	// transfer graph image to icon image
	[graphImage unlockFocus];
	[displayImage lockFocus];	
	[graphImage compositeToPoint:NSMakePoint(0.0, 0.0) operation:NSCompositeCopy];
	
	// draw paging rate into the icon image
	[self drawPageins:vmdata.pageins pageouts:vmdata.pageouts];
	
	[displayImage unlockFocus];
}


- (void)drawDelta
// update graphImage (based on previous graphImage), put graph and pageing rate into displayImage
{	
	VMData			vmdata, vmdata0;
	float			y, yy;
	
	BOOL pageinAtopPageout = [[preferences objectForKey:PAGEIN_ATOP_PAGEOUT_KEY] boolValue];
	double pagingmax = [[preferences objectForKey:PAGING_SCALE_MAX_KEY] doubleValue];
	double interval = 0.1 * [[preferences objectForKey:UPDATE_FREQUENCY_KEY] floatValue];
	double pgfactor = 1.0 / (pagingmax * interval);
	
	[graphImage lockFocus];

	// offset the old graph image
	[graphImage compositeToPoint:NSMakePoint(-1, 0) operation:NSCompositeCopy];
		
	[memInfo getLast:&vmdata0];
	[memInfo getCurrent:&vmdata];
	
	// draw chronological graph into graph image
	y = vmdata.wired * GRAPH_SIZE;
	[[preferences objectForKey:WIRED_COLOR_KEY] set];
	NSRectFill (NSMakeRect(GRAPH_SIZE - 1, 0.0, GRAPH_SIZE - 1, y));
	yy = y;
	y += vmdata.active * GRAPH_SIZE;
	[[preferences objectForKey:ACTIVE_COLOR_KEY] set];
	NSRectFill (NSMakeRect(GRAPH_SIZE - 1, yy, GRAPH_SIZE - 1, y));
	yy = y;
	y += vmdata.inactive * GRAPH_SIZE;
	[[preferences objectForKey:INACTIVE_COLOR_KEY] set];
	NSRectFill (NSMakeRect(GRAPH_SIZE - 1, yy, GRAPH_SIZE - 1, y));
	[[preferences objectForKey:FREE_COLOR_KEY] set];
	NSRectFill (NSMakeRect(GRAPH_SIZE - 1, y, GRAPH_SIZE - 1, GRAPH_SIZE));

	if (pageinAtopPageout) {
		y = GRAPH_SIZE * (1.0 - vmdata.pageins * pgfactor);
		yy = GRAPH_SIZE * (1.0 - vmdata0.pageins * pgfactor);
	} else {
		y = GRAPH_SIZE * vmdata.pageins * pgfactor;
		yy = GRAPH_SIZE * vmdata0.pageins * pgfactor;
	}
	[[preferences objectForKey:PAGEIN_COLOR_KEY] set];
	[NSBezierPath strokeLineFromPoint:NSMakePoint(GRAPH_SIZE - 1, yy) toPoint:NSMakePoint(GRAPH_SIZE, y)];

	if (pageinAtopPageout) {
		y = GRAPH_SIZE * vmdata.pageouts * pgfactor;
		yy = GRAPH_SIZE * vmdata0.pageouts * pgfactor;
	} else {
		y = GRAPH_SIZE * (1.0 - vmdata.pageouts * pgfactor);
		yy = GRAPH_SIZE * (1.0 - vmdata0.pageouts * pgfactor);
	}
	[[preferences objectForKey:PAGEOUT_COLOR_KEY] set];
	[NSBezierPath strokeLineFromPoint:NSMakePoint(GRAPH_SIZE - 1, yy) toPoint:NSMakePoint(GRAPH_SIZE, y)];			

	// transfer graph image to icon image
	[graphImage unlockFocus];
	[displayImage lockFocus];
	[graphImage compositeToPoint:NSMakePoint(0.0, 0.0) operation:NSCompositeCopy];

	// draw paging rate into the icon image
	[self drawPageins:vmdata.pageins pageouts:vmdata.pageouts];

	[displayImage unlockFocus];
}


- (void)setApplicationIcon
// set the (scaled) application icon
{
	float inc = GRAPH_SIZE * (1.0 - [[preferences objectForKey:DOCK_ICON_SIZE_KEY] floatValue]);
	[iconImage lockFocus];
	[displayImage drawInRect:NSMakeRect(inc, inc, GRAPH_SIZE - 2 * inc, GRAPH_SIZE - 2 * inc) fromRect:NSMakeRect(0, 0, GRAPH_SIZE, GRAPH_SIZE) operation:NSCompositeCopy fraction:1.0];
	[iconImage unlockFocus];
	[NSApp setApplicationIconImage:iconImage];
}


- (void)refreshGraph
// get a new sample and refresh the graph
{
	[memInfo refresh];
	[self drawDelta];
	[self setApplicationIcon];
	
	if ([[preferences objectForKey:SHOW_GRAPH_WINDOW_KEY] boolValue]) {
		[window disableFlushWindow];
		[view display];
		[window enableFlushWindow];
		[window flushWindow];
	}
}


- (void)updateGraph
// completely redraw the graph (to show new preferences settings)
{
	[self drawComplete];
	[iconImage lockFocus];
	[[NSColor clearColor] set];
	NSRectFill (NSMakeRect(0, 0, GRAPH_SIZE, GRAPH_SIZE));
	[iconImage unlockFocus];
	[self setApplicationIcon];
	
	if ([[preferences objectForKey:SHOW_GRAPH_WINDOW_KEY] boolValue]) {
		[window disableFlushWindow];
		[view display];
		[window enableFlushWindow];
		[window flushWindow];
	}
}


- (void)setTimer
{
	double newInterval = 0.1 * [[preferences objectForKey:UPDATE_FREQUENCY_KEY] floatValue];

	if (timer) {
		if (fabs([timer timeInterval] - newInterval) < 0.001)
			return;		/* frequency not changed */
		[timer invalidate];
		[timer release];
	}
	timer = [NSTimer scheduledTimerWithTimeInterval:newInterval
		target:self selector:@selector(refreshGraph) userInfo:nil repeats:YES];
	[timer retain];
}


- (void)showPreferences:(id)sender
{
	[NSApp activateIgnoringOtherApps:YES];	/* activate application when called from Dock menu */
	[preferences showPreferences:self];
}


- (void)showAboutBox:(id)sender
{
	[NSApp activateIgnoringOtherApps:YES];	/* activate application when called from Dock menu */
	[NSApp orderFrontStandardAboutPanel:sender];
}


- (BOOL)isLoginItem
{
	id	obj;
	
	NSString *memoryMonitorPath = [[NSBundle mainBundle] bundlePath];
	NSDictionary *loginItemDict = [NSDictionary dictionaryWithContentsOfFile:[NSString stringWithFormat:@"%@/Library/Preferences/loginwindow.plist", NSHomeDirectory()]];
	NSEnumerator *loginItemEnumerator = [[loginItemDict objectForKey:@"AutoLaunchedApplicationDictionary"] objectEnumerator];

	while ((obj = [loginItemEnumerator nextObject])) {
		if ([[obj objectForKey:@"Path"] isEqualTo:memoryMonitorPath])
			return (YES);
	}
	return (NO);
}


- (unsigned)systemVersion
// returns the system version normally retrieved with Gestalt(gestaltSystemVersion, &systemVersion)
{
	const char	*p;
	
	unsigned version = 0;
	
	for (p = [[[NSDictionary dictionaryWithContentsOfFile:@"/System/Library/CoreServices/SystemVersion.plist"]
		objectForKey:@"ProductVersion"] cString]; *p; p++) {
		if (*p != '.')
			version = (version << 4) | (*p - '0');
	}
	if (version < 0x1000)	// for 10.0, 10.1
		version <<= 4;
	return (version);
}


- (BOOL)updateFrameName
// calculate the frameName used to save the window position; return TRUE iff the name changed,
// i. e. the display configuration changed since last call of this method
{
	NSRect		rect;
	NSScreen	*screen;
	BOOL		nameDidChange;
	
	NSString *string = @"MMWL";	// MemoryMonitorWindowLocation
	NSEnumerator *enumerator = [[NSScreen screens] objectEnumerator];

	while ((screen = [enumerator nextObject])) {
		rect = [screen frame];
		string = [string
			stringByAppendingString:[NSString stringWithFormat:@"%.0f%.0f%.0f%.0f",
			rect.origin.x, rect.origin.y, rect.size.width, rect.size.height]];
	}
	nameDidChange = ! [string isEqualToString:frameName];
	[frameName release];
	frameName = string;
	[frameName retain];
	return (nameDidChange);
}


- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
	preferences = [[Preferences alloc] init];
	memInfo = [[MemInfo alloc] initWithCapacity:GRAPH_SIZE];
	
	displayImage = [[NSImage allocWithZone:[self zone]] initWithSize:NSMakeSize(GRAPH_SIZE, GRAPH_SIZE)];
	graphImage = [[NSImage allocWithZone:[self zone]] initWithSize:NSMakeSize(GRAPH_SIZE, GRAPH_SIZE)];
	iconImage = [[NSImage allocWithZone:[self zone]] initWithSize:NSMakeSize(GRAPH_SIZE, GRAPH_SIZE)];
	[self drawComplete];

	window = [[TranslucentWindow allocWithZone:[self zone]]
		initWithContentRect:NSMakeRect(0.0, 0.0, GRAPH_SIZE, GRAPH_SIZE)
		styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:NO];
	[window setReleasedWhenClosed:NO];
	[window setBackgroundColor:[NSColor clearColor]];
	[self updateFrameName];
	if (! [window setFrameUsingName:frameName]) {
		// for compatibility with version 1.1 preferences file
		[window setFrameUsingName:@"MemoryMonitorWindowLocation"];
		[NSWindow removeFrameUsingName:@"MemoryMonitorWindowLocation"];
		[window saveFrameUsingName:frameName];
	}
	[window setDelegate:self];

	view = [[TranslucentView allocWithZone:[self zone]] initWithFrame:NSMakeRect(0.0, 0.0, GRAPH_SIZE, GRAPH_SIZE)];
	[window setContentView:view];
	[view setContentDrawer:self method:@selector(drawImageOnWindow)];
	[view setAutoresizingMask:(NSViewHeightSizable | NSViewWidthSizable)];
	[view setToolTip:@"Memory Monitor"];
	
	
	[self showHideWindow];

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showHideWindow) name:PREFERENCES_CHANGED object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateGraph) name:PREFERENCES_CHANGED object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setTimer) name:PREFERENCES_CHANGED object:nil];

	if ([self systemVersion] < 0x1010 && [self isLoginItem])
		[NSTimer scheduledTimerWithTimeInterval:30 target:self selector:@selector(setTimer) userInfo:nil repeats:NO];
	else
		[self setTimer];
}


- (void)applicationWillTerminate:(NSNotification *)aNotification 
{
	if (timer) {
		[timer invalidate];
		[timer release];
		timer = nil;
	}
	[preferences savePreferences];
	[NSApp setApplicationIconImage:[NSImage imageNamed:@"MemoryMonitor.icns"]];	
}


- (void)applicationDidChangeScreenParameters:(NSNotification *)aNotification
{
	[self updateFrameName];
	[window setFrameUsingName:frameName];
}


- (void)windowDidMove:(NSNotification *)aNotification
{
	if (! [self updateFrameName])
		[window saveFrameUsingName:frameName];
}


@end
