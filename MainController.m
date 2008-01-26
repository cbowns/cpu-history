/*
 *	CPU History
 *	Christopher Bowns, 2008
 *	
 *	Formerly: Memory Monitor, by Bernhard Baehr
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
#define GRAPH_WIDTH	8

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


- (void)drawComplete
// completely redraw graphImage, put graph into displayImage
{	
	CPUData			cpudata;
	
	
	int				x;
	float			y, yy;
	
	// double interval = 0.1 * [[preferences objectForKey:UPDATE_FREQUENCY_KEY] floatValue];
	
	[graphImage lockFocus];

	// draw the cpu usage graph
	[cpuInfo startIterate];
	// for (x = 0; [memInfo getNext:&vmdata]; x++) {
	for (x = 0; [cpuInfo getNext:&cpudata]; x+=GRAPH_WIDTH) {
		
		// y += vmdata.active * GRAPH_SIZE;
		y = cpudata.sys * GRAPH_SIZE;
		[[preferences objectForKey:SYS_COLOR_KEY] set];
		NSRectFill (NSMakeRect(x - GRAPH_WIDTH, 0.0, x, y));
		yy = y;
		// y += vmdata.inactive * GRAPH_SIZE;
		y += cpudata.nice * GRAPH_SIZE;
		[[preferences objectForKey:NICE_COLOR_KEY] set];
		NSRectFill (NSMakeRect(x - GRAPH_WIDTH, yy, x, y));
		// y = vmdata.wired * GRAPH_SIZE;
		yy = y;
		
		y += cpudata.user * GRAPH_SIZE;
		[[preferences objectForKey:USER_COLOR_KEY] set];
		NSRectFill (NSMakeRect(x - GRAPH_WIDTH, yy, x, y));
		
		// free data here
		[[preferences objectForKey:IDLE_COLOR_KEY] set];
		NSRectFill (NSMakeRect(x - GRAPH_WIDTH, y, x, GRAPH_SIZE));
	}
	
	// transfer graph image to icon image
	[graphImage unlockFocus];
	[displayImage lockFocus];	
	[graphImage compositeToPoint:NSMakePoint(0.0, 0.0) operation:NSCompositeCopy];
		
	[displayImage unlockFocus];
}


- (void)drawDelta
// update graphImage (based on previous graphImage), put graph into displayImage
{	
	// VMData			vmdata, vmdata0;
	CPUData			cpudata, cpudata0;
	float			y, yy;
	
	// double interval = 0.1 * [[preferences objectForKey:UPDATE_FREQUENCY_KEY] floatValue];
	
	[graphImage lockFocus];

	// offset the old graph image
	[graphImage compositeToPoint:NSMakePoint(-GRAPH_WIDTH, 0) operation:NSCompositeCopy];
		
	// [memInfo getLast:&vmdata0];
	[cpuInfo getLast:&cpudata0];
	// [memInfo getCurrent:&vmdata];
	[cpuInfo getCurrent:&cpudata];
	
	// draw chronological graph into graph image
	
	// y += vmdata.active * GRAPH_SIZE;
	y = cpudata.sys * GRAPH_SIZE;
	[[preferences objectForKey:SYS_COLOR_KEY] set];
	NSRectFill (NSMakeRect(GRAPH_SIZE - GRAPH_WIDTH, 0.0, GRAPH_SIZE - GRAPH_WIDTH, y));
	yy = y;
	
	// y += vmdata.inactive * GRAPH_SIZE;
	y += cpudata.nice * GRAPH_SIZE;
	[[preferences objectForKey:NICE_COLOR_KEY] set];
	NSRectFill (NSMakeRect(GRAPH_SIZE - GRAPH_WIDTH, yy, GRAPH_SIZE - GRAPH_WIDTH, y));
	yy = y;
	
	// y = vmdata.wired * GRAPH_SIZE;
	y += cpudata.user * GRAPH_SIZE;
	[[preferences objectForKey:USER_COLOR_KEY] set];
	NSRectFill (NSMakeRect(GRAPH_SIZE - GRAPH_WIDTH, yy, GRAPH_SIZE - GRAPH_WIDTH, y));

	// free data here
	[[preferences objectForKey:IDLE_COLOR_KEY] set];
	NSRectFill (NSMakeRect(GRAPH_SIZE - GRAPH_WIDTH, y, GRAPH_SIZE - GRAPH_WIDTH, GRAPH_SIZE));


	// transfer graph image to icon image
	[graphImage unlockFocus];
	[displayImage lockFocus];
	[graphImage compositeToPoint:NSMakePoint(0.0, 0.0) operation:NSCompositeCopy];

	[displayImage unlockFocus];
}


- (void)setApplicationIcon
// set the (scaled) application icon
{
	float inc = GRAPH_SIZE * (1.0 - [[preferences objectForKey:DOCK_ICON_SIZE_KEY] floatValue]); // icon scaling
	[iconImage lockFocus];
	[displayImage drawInRect:NSMakeRect(inc, inc, GRAPH_SIZE - 2 * inc, GRAPH_SIZE - 2 * inc) fromRect:NSMakeRect(0, 0, GRAPH_SIZE, GRAPH_SIZE) operation:NSCompositeCopy fraction:1.0];
	[iconImage unlockFocus];
	[NSApp setApplicationIconImage:iconImage];
}


- (void)refreshGraph
// get a new sample and refresh the graph
{
	// [memInfo refresh];
	[cpuInfo refresh];
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
	
	NSString *cpuHistoryPath = [[NSBundle mainBundle] bundlePath];
	NSDictionary *loginItemDict = [NSDictionary dictionaryWithContentsOfFile:[NSString stringWithFormat:@"%@/Library/Preferences/loginwindow.plist", NSHomeDirectory()]];
	NSEnumerator *loginItemEnumerator = [[loginItemDict objectForKey:@"AutoLaunchedApplicationDictionary"] objectEnumerator];

	while ((obj = [loginItemEnumerator nextObject])) {
		if ([[obj objectForKey:@"Path"] isEqualTo:cpuHistoryPath])
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
	
	NSString *string = @"CHWL";	// CPUHistoryWindowLocation
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
	[NSApp setApplicationIconImage:[NSImage imageNamed:@"CPUHistory.icns"]];
	
	preferences = [[Preferences alloc] init];
	// memInfo = [[MemInfo alloc] initWithCapacity:GRAPH_SIZE];
	cpuInfo = [[CPUInfo alloc] initWithCapacity:GRAPH_SIZE];
	if (nil == cpuInfo) //then we need to bomb out. We can't do anything else.
	{
		NSLog(@"%s failed to create CPUInfo object!", _cmd);
		NSString *errorStr = [[NSString alloc] initWithFormat:@"There's not enough memory to allocate the CPU data array. Sorry, but I have to quit now."];
		/* now display error dialog and quit */
		int choice = NSRunAlertPanel(@"Error", errorStr, @"OK", nil, nil);
		[errorStr release];
		[preferences release];
		[NSApp terminate:nil];
	}
	
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
		[window setFrameUsingName:@"CPUHistoryWindowLocation"];
		[NSWindow removeFrameUsingName:@"CPUHistoryWindowLocation"];
		[window saveFrameUsingName:frameName];
	}
	[window setDelegate:self];

	view = [[TranslucentView allocWithZone:[self zone]] initWithFrame:NSMakeRect(0.0, 0.0, GRAPH_SIZE, GRAPH_SIZE)];
	[window setContentView:view];
	[view setContentDrawer:self method:@selector(drawImageOnWindow)];
	[view setAutoresizingMask:(NSViewHeightSizable | NSViewWidthSizable)];
	[view setToolTip:@"CPU History"];
	
	
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
	[NSApp setApplicationIconImage:[NSImage imageNamed:@"CPUHistory.icns"]];
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
