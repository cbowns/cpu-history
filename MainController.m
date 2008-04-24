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


// #ifndef NSLOG_DEBUG
// define NSLOG_DEBUG
// #endif

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
		[window orderWindow:NSWindowAbove relativeTo:[preferences windowNumber]];
		[window setLevel:([[preferences objectForKey:GRAPH_WINDOW_ON_TOP_KEY] boolValue] ?
			NSFloatingWindowLevel : NSNormalWindowLevel)];
		[window setFrameAutosaveName:@"CPU History floater"];
		if(![window setFrameUsingName:@"CPU History floater"])
			[window center];
		else {
			NSRect frame = [window frame];
			[window setFrame:frame display:NO];
		}
		// [window center];
	} else
		[window orderOut:self];
}


- (void)drawComplete
// completely redraw graphImage, put graph into displayImage
{	
	
	#ifdef NSLOG_DEBUG
	NSLog(@"%s", _cmd);
	#endif

	CPUData			cpudata;
	unsigned 		cpu, numCPUs = [cpuInfo numCPUs];
	float			graphSpacer = [[preferences objectForKey:GRAPH_SPACER_WIDTH] floatValue];
	float			height = ( GRAPH_SIZE - (graphSpacer * (numCPUs - 1) ) ) / numCPUs; // returns just GRAPH_SIZE on single-core machines.
	float			width = GRAPH_SIZE;
	float			x = 0.0, y = 0.0, ybottom = 0.0;
	float barWidth = (float)[[preferences objectForKey:BAR_WIDTH_SIZE_KEY] floatValue];
	
	[graphImage lockFocus];
	// draw the cpu usage graph
	
	
	for (cpu = 0U; cpu < numCPUs; cpu++ ) {
		[cpuInfo startBackwardIterate];

		// init the base (bottom) of this cpu's graph space.
		float yBase = cpu * (height + graphSpacer);
		ybottom = yBase;
		
		#ifdef NSLOG_DEBUG
		NSLog(@"\n\n%s ybottom: %.2f", _cmd, ybottom);
		NSLog(@"%s cpu %i: drawing starts at %f px high\n\n", _cmd, cpu, ybottom);
		#endif
		
		if (cpu != 0) // we need to draw the transparent spacer
		{
			[[NSColor colorWithCalibratedRed:0.0 green:0.0 blue:0.0 alpha:0.0] set];
			#ifdef NSLOG_DEBUG
			NSLog(@"%s spacer:\t\t(%.2f, %.2f) by (%.2f, %.2f)", _cmd, 0.0, ybottom - graphSpacer, width, graphSpacer);
			NSLog(@"%s y = %.2f, ybottom = %.2f", _cmd, y, ybottom - graphSpacer);
			#endif
			
			NSRectFill (NSMakeRect(0, ybottom - graphSpacer, width, graphSpacer));
		}
		
		// set the idle background
		[[preferences objectForKey:IDLE_COLOR_KEY] set];
		NSRectFill(NSMakeRect(0, ybottom, width, height));
		// loop through the previous CPU data and draw them.
		for (x = width; x > 0.0 && [cpuInfo getPrev:&cpudata forCPU:cpu]; x -= barWidth) {
			#ifdef NSLOG_DEBUG
			NSLog(@"%s width left to draw: %.2f", _cmd, x);
			NSLog(@"CPU %d: User: %.4f, Sys: %.4f, Idle: %.4f", cpu, cpudata.user, cpudata.sys, cpudata.idle);
			#endif
			
			ybottom = yBase;
			y = cpudata.sys * height;
			[[preferences objectForKey:SYS_COLOR_KEY] set];
			#ifdef NSLOG_DEBUG
			NSLog(@"%s system:\t\t(%.2f, %.2f) by (%.2f, %.2f)", _cmd, x - (float)barWidth, ybottom, (float)barWidth, y);
			NSLog(@"%s y = %.2f, ybottom = %.2f", _cmd, y, ybottom);
			#endif
			NSRectFill (NSMakeRect(x - barWidth, ybottom, barWidth, y));
			ybottom += y;
			
			y = cpudata.user * height;
			[[preferences objectForKey:USER_COLOR_KEY] set];
			#ifdef NSLOG_DEBUG
			NSLog(@"%s user:\t\t(%.2f, %.2f) by (%.2f, %.2f)", _cmd, x - barWidth, ybottom, barWidth, y);
			NSLog(@"%s y = %.2f, ybottom = %.2f", _cmd, y, ybottom);
			#endif
			NSRectFill (NSMakeRect(x - barWidth, ybottom, barWidth, y));
			ybottom += y;
			
			y = cpudata.idle * height;
			[[preferences objectForKey:IDLE_COLOR_KEY] set];
			#ifdef NSLOG_DEBUG
			NSLog(@"%s idle:\t\t(%.2f, %.2f) by (%.2f, %.2f)", _cmd, x - barWidth, ybottom, barWidth, y);
			NSLog(@"%s y = %.2f, ybottom = %.2f", _cmd, y, ybottom);
			#endif
			NSRectFill (NSMakeRect(x - barWidth, ybottom, barWidth, y));
			ybottom += y;
		}
		
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

	#ifdef NSLOG_DEBUG
	NSLog(@"%s", _cmd);
	#endif

	CPUData			cpudata, cpudata0;
	unsigned 		cpu, numCPUs = [cpuInfo numCPUs];
	float			graphSpacer = [[preferences objectForKey:GRAPH_SPACER_WIDTH] floatValue];
	float			height = ( GRAPH_SIZE - (graphSpacer * (numCPUs - 1) ) ) / numCPUs;
	float			width = GRAPH_SIZE;
	float			y = 0.0, ybottom = 0.0;
	int barWidth = (int)[[preferences objectForKey:BAR_WIDTH_SIZE_KEY] floatValue];
	// double interval = 0.1 * [[preferences objectForKey:UPDATE_FREQUENCY_KEY] floatValue];
	
	[graphImage lockFocus];

	// offset the old graph image
	[graphImage compositeToPoint:NSMakePoint(-barWidth, 0) operation:NSCompositeCopy];
		
	for (cpu = 0; cpu < numCPUs; cpu++ ) {
		float yBase = cpu * (height + graphSpacer);
		ybottom = yBase;
		
		#ifdef NSLOG_DEBUG
		NSLog(@"%s cpu %i: drawing starts at %f px high\n\n", _cmd, cpu, ybottom);
		#endif
		
		if (cpu != 0)
		{
			[[NSColor colorWithCalibratedRed:0.0 green:0.0 blue:0.0 alpha:0.0] set];
			NSRectFill (NSMakeRect(width - (float)barWidth, ybottom - graphSpacer, (float)barWidth, graphSpacer));
		}
		
		[cpuInfo getLast:&cpudata0 forCPU:cpu];
		[cpuInfo getCurrent:&cpudata forCPU:cpu];
		
		// draw chronological graph into graph image
		#ifdef NSLOG_DEBUG
		NSLog(@"CPU %d: User: %f, Sys: %f, Idle: %f", cpu, cpudata.user, cpudata.sys, cpudata.idle);
		#endif
		
		
		y = cpudata.sys * height;
		[[preferences objectForKey:SYS_COLOR_KEY] set];
		#ifdef NSLOG_DEBUG
		NSLog(@"%s system:\t\t(%.2f, %.2f) by (%.2f, %.2f)", _cmd, width - (float)barWidth, ybottom, (float)barWidth, y);
		NSLog(@"%s y = %.2f, ybottom = %.2f", _cmd, y, ybottom);
		#endif
		NSRectFill (NSMakeRect(width - (float)barWidth, ybottom, (float)barWidth, y));
		ybottom += y;
		
		
		y = cpudata.user * height;
		[[preferences objectForKey:USER_COLOR_KEY] set];
		#ifdef NSLOG_DEBUG
		NSLog(@"%s user:\t\t(%.2f, %.2f) by (%.2f, %.2f)", _cmd, width - (float)barWidth, ybottom, (float)barWidth, y);
		NSLog(@"%s y = %.2f, ybottom = %.2f", _cmd, y, ybottom);
		#endif
		NSRectFill (NSMakeRect(width - (float)barWidth, ybottom, (float)barWidth, y));
		ybottom += y;
		
		
		y = cpudata.idle * height;
		[[preferences objectForKey:IDLE_COLOR_KEY] set];
		#ifdef NSLOG_DEBUG
		NSLog(@"%s idle:\t\t(%.2f, %.2f) by (%.2f, %.2f)", _cmd, width - (float)barWidth, ybottom, (float)barWidth, y);
		NSLog(@"%s y = %.2f, ybottom = %.2f", _cmd, y, ybottom);
		#endif
		NSRectFill (NSMakeRect(width - (float)barWidth, ybottom, (float)barWidth, y));
	}

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
	[cpuInfo refresh];
	[self drawDelta];
	// [self drawComplete];
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
	cpuInfo = [[CPUInfo alloc] initWithCapacity:GRAPH_SIZE];
	if (nil == cpuInfo) //then we need to bomb out. We can't do anything else.
	{
		NSLog(@"%s failed to create CPUInfo object!", _cmd);
		NSString *errorStr = [[NSString alloc] initWithFormat:@"There's not enough memory to allocate the CPU data array. Sorry, but I have to quit now."];
		/* now display error dialog and quit */
		NSRunAlertPanel(@"Error", errorStr, @"OK", nil, nil);
		
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
