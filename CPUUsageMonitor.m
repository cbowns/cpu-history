//
//  CPUUsageMonitor.m
//  CPU Usage
//
//  Created by Peter Hosey on 2006-06-21.
//  Copyright 2006 Peter Hosey. All rights reserved.
//

#import "CPUUsageMonitor.h"

#import "CPUUsageView.h"
#import "NSString+Percentage.h"

#import "BZGridEnumerator.h"

#include <sys/types.h>
//sqrtf, ceilf
#include <math.h>
//sysctl and its parameters
#include <sys/sysctl.h>
//errno, strerror
#include <sys/errno.h>
#include <string.h>

#define DOCK_ICON_SIZE 128.0f

@interface CPUUsageMonitor (PRIVATE)

- (void)layOutCellsInWindow:(NSWindow *)thisWindow;

@end

@implementation CPUUsageMonitor

+ (void)initialize {
	[self exposeBinding:@"backgroundColor"];
	[self exposeBinding:@"cellWidth"];
	[self exposeBinding:@"cellHeight"];
	[self exposeBinding:@"shouldDrawToDockIcon"];
	[self exposeBinding:@"shouldDrawToWindow"];
}

- init {
	if((self = [super init])) {
		NSNumber *thirtyTwo = [NSNumber numberWithFloat:32.0f];
		NSDictionary *defaultPrefs = [NSDictionary dictionaryWithObjectsAndKeys:
			[NSArchiver archivedDataWithRootObject:[NSColor whiteColor]], @"Floater text color",
			[NSNumber numberWithFloat:0.0f], @"Floater text opacity",
			[NSArchiver archivedDataWithRootObject:[NSColor whiteColor]], @"Dock icon text color",
			[NSNumber numberWithFloat:1.0f], @"Dock icon text opacity",
			[NSArchiver archivedDataWithRootObject:[NSColor redColor]], @"Background color",
			thirtyTwo, @"Cell width",
			thirtyTwo, @"Cell height",
			[NSNumber numberWithBool:YES], @"Draw CPU usage to window",
			[NSNumber numberWithInt:CPUUsageOrientationVertical], @"Window orientation",
			[NSNumber numberWithBool:NO], @"Draw CPU usage to Dock icon",
			nil];

		[[NSUserDefaults standardUserDefaults] registerDefaults:defaultPrefs];
	}
	return self;
}

#pragma mark NSApplication delegate conformance

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
	//Set up us the properties of new cells.
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSData *data = [defaults dataForKey:@"Background color"];
	NSColor *color = data ? [NSUnarchiver unarchiveObjectWithData:data] : [NSColor redColor];
	[self setBackgroundColor:color];

	[self setCellWidth:[defaults floatForKey:@"Cell width"]];
	[self setCellHeight:[defaults floatForKey:@"Cell height"]];

	//Sign up for notifications of pref changes.
	NSUserDefaultsController *udc = [NSUserDefaultsController sharedUserDefaultsController];
	NSDictionary *colorBindingOptions = [NSDictionary dictionaryWithObject:@"NSUnarchiveFromData" forKey:NSValueTransformerNameBindingOption];
	[self bind:@"backgroundColor"      toObject:udc withKeyPath:@"values.Background color"            options:colorBindingOptions];
	[self bind:@"cellWidth"            toObject:udc withKeyPath:@"values.Cell width"                  options:nil];
	[self bind:@"cellHeight"           toObject:udc withKeyPath:@"values.Cell height"                 options:nil];
	[self bind:@"shouldDrawToDockIcon" toObject:udc withKeyPath:@"values.Draw CPU usage to Dock icon" options:nil];
	[self bind:@"shouldDrawToWindow"   toObject:udc withKeyPath:@"values.Draw CPU usage to window"    options:nil];

	//Fetch the orientation from prefs.
	orientation = [defaults integerForKey:@"Window orientation"];

	//Set up the orientation buttons.
	int buttonStates[2] = { NSOffState, NSOnState };
	[horizontalButton  setState:buttonStates[(orientation == CPUUsageOrientationHorizontal )]];
	[verticalButton    setState:buttonStates[(orientation == CPUUsageOrientationVertical   )]];
	[rectangularButton setState:buttonStates[(orientation == CPUUsageOrientationRectangular)]];

	//We could get the number of processors the same way that we get the CPU usage info, but that allocates memory.
	enum { miblen = 2U };
	int mib[miblen] = { CTL_HW, HW_NCPU };
	size_t sizeOfNumCPUs = sizeof(numCPUs);
	int status = sysctl(mib, miblen,
		   &numCPUs, &sizeOfNumCPUs,
		   /*newp*/ NULL, /*newlen*/ 0U);
	if(status != 0)
		numCPUs = 1; //XXX Should probably error out instead…

	//Set up our display destinations.
	//First, the Dock icon window. We'll copy the content view into an image, which we set as the application icon.
	NSRect dockIconRect = { NSZeroPoint, { DOCK_ICON_SIZE, DOCK_ICON_SIZE } };
	dockIconWindow = [[NSPanel alloc] initWithContentRect:dockIconRect
												styleMask:NSBorderlessWindowMask
												  backing:NSBackingStoreBuffered
													defer:YES];
	[dockIconWindow setTitle:@"CPU Usage hidden Dock-icon window"];
	[dockIconWindow setOpaque:NO];
	[dockIconWindow setAcceptsMouseMovedEvents:NO];
	[dockIconWindow setMovableByWindowBackground:YES];
	[dockIconWindow setHasShadow:NO];
	[dockIconWindow setIgnoresMouseEvents:YES];
	[dockIconWindow setReleasedWhenClosed:YES];
	[dockIconWindow setOneShot:NO];
	[dockIconWindow setBackgroundColor:[NSColor clearColor]];
	//We need to order the window in so that the views can draw. But we only want the user to see the Dock icon, not the window. So we set the alpha to 0.
	[dockIconWindow setAlphaValue:0.0f];
	[dockIconWindow orderBack:nil];

	dockIconUsageViewsContainingView = [dockIconWindow contentView];

	dockIconUsageViews = [[NSMutableArray alloc] initWithCapacity:numCPUs];
	[self layOutCellsInWindow:dockIconWindow];

	//Second, create the floater.
	float numCPUsFloat = numCPUs;
	float numViewsX, numViewsY;
	if(orientation == CPUUsageOrientationHorizontal) {
		numViewsX = numCPUsFloat;
		numViewsY = 1.0f;
	} else if(orientation == CPUUsageOrientationVertical) {
		numViewsX = 1.0f;
		numViewsY = numCPUsFloat;
	} else {
		numViewsX = ceilf(sqrtf(numCPUsFloat));
		numViewsY = ceilf(numCPUsFloat / numViewsX);
	}
	float numCellsMissing = ((numViewsX * numViewsY) - numCPUsFloat);

	//Here, these enumerators are used only to compute the frame of the window. No actual enumeration is done.
	BZGridEnumerator *floaterOddCellsEnum = nil;
	BZGridEnumerator *floaterCellsEnum = [[BZGridEnumerator alloc] initWithCellSize:(NSSize){ cellWidth, cellHeight }
																	numberOfColumns:numViewsX
																	   numberOfRows:numViewsY];
	NSRect frame = [floaterCellsEnum overallRect];
	if(numCellsMissing) {
		float numOddCells = numCellsMissing ? numViewsX - numCellsMissing : 0.0f;
		/*oddCellsWidth is the fraction of the total frame width used by odd cells.
		 *total = X*Y
		 *numEmptySpaces = total - numCPUs
		 *numOddCPUs = X - numEmptySpaces
		 *oddCellsWidth = numOddCPUs / X
		 */
		float oddCellsWidth = numOddCells / numViewsX;
		float oddCellWidth = oddCellsWidth / numOddCells;
			
		floaterOddCellsEnum = [[BZGridEnumerator alloc] initWithCellSize:(NSSize){ frame.size.width * oddCellWidth, cellHeight }
																  offset:(NSPoint){ 0.0f, cellHeight * numViewsY }
														 numberOfColumns:numOddCells
															numberOfRows:1U];
		frame.size.height += [floaterOddCellsEnum overallRect].size.height;
	}

	window = [[NSWindow alloc] initWithContentRect:frame
										 styleMask:NSBorderlessWindowMask
										   backing:NSBackingStoreBuffered
											 defer:YES];
	[window setTitle:@"CPU Usage"];
	[window setOpaque:NO];
	[window setAcceptsMouseMovedEvents:NO];
	[window setMovableByWindowBackground:YES];
	[window setLevel:kCGDesktopWindowLevel + 2];
	[window setHasShadow:NO];
	[window setIgnoresMouseEvents:YES];
	[window setReleasedWhenClosed:YES];
	if(orientation != CPUUsageOrientationRectangular) {
		BOOL isHorizontal = (orientation == CPUUsageOrientationHorizontal);
		[window setResizeIncrements:(NSSize){ numCPUs * isHorizontal, numCPUs * !isHorizontal }];
	}
	[window setBackgroundColor:[NSColor clearColor]];

	usageViews = [[NSMutableArray alloc] initWithCapacity:numCPUs];
	[self layOutCellsInWindow:window];

	[window setFrameAutosaveName:@"CPU usage window"];
	if(![window setFrameUsingName:@"CPU usage window"])
		[window center];
	else {
		frame.origin = [window frame].origin;
		[window setFrame:frame display:NO];
	}
	[preferencesPanel center];

	CPUUsageLock = [[NSLock alloc] init];
	CPUUsage = NSZoneMalloc([self zone], numCPUs * sizeof(float));

	updateTimer = [[NSTimer scheduledTimerWithTimeInterval:0.5
													target:self
												  selector:@selector(updateCPUUsageButNotViews:)
												  userInfo:nil
												   repeats:YES] retain];
	[updateTimer fire];

	//Launch the threaded timers that sweep our CPU usage array looking for views.
	for(unsigned i = 0U; i < numCPUs; ++i) {
		[NSThread detachNewThreadSelector:@selector(threadedLaunchTimer:)
								 toTarget:self
							   withObject:[NSNumber numberWithUnsignedInt:i]];
	}

	if(shouldDrawToWindow)
		[window orderFront:nil];
}

- (void)applicationWillTerminate:(NSNotification *)notification {
	//First, fade out the window.
	NSDictionary *animDict = [NSDictionary dictionaryWithObjectsAndKeys:
		window, NSViewAnimationTargetKey,
		NSViewAnimationFadeOutEffect, NSViewAnimationEffectKey,
		nil];
	NSViewAnimation *anim = [[NSViewAnimation alloc] initWithViewAnimations:[NSArray arrayWithObject:animDict]];
	[anim setDuration:0.5];
	[anim setAnimationBlockingMode:NSAnimationNonblockingThreaded];

	//Tell the threads to stop, then wait for them to comply.
//	threadsShouldExit = YES;
	threadsRemainingToDie = [usageViews count];
	[anim startAnimation];

	unsigned sleepCount = 100U; //Wait no more than this many seconds.
	while(threadsRemainingToDie && sleepCount--)
		[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];

	//Wait for the animation to run out.
	while([anim isAnimating])
		[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];

	[updateTimer invalidate];
	[updateTimer release];

	[usageViews release];

	[backgroundColor release];

	[window close];

	NSZoneFree([self zone], CPUUsage);

	[NSApp setApplicationIconImage:[NSImage imageNamed:@"CPUUsageIcon"]];
}

- (void)applicationDidBecomeActive:(NSNotification *)notification {
	NSEnumerator *usageViewsEnum = [usageViews objectEnumerator];
	CPUUsageView *usageView;
	while((usageView = [usageViewsEnum nextObject])) {
		[usageView setDrawsFrame:YES];
		[usageView setNeedsDisplay:YES];
	}

	[window setIgnoresMouseEvents:NO];
}
- (void)applicationWillResignActive:(NSNotification *)notification {
	NSEnumerator *usageViewsEnum = [usageViews objectEnumerator];
	CPUUsageView *usageView;
	while((usageView = [usageViewsEnum nextObject])) {
		[usageView setDrawsFrame:NO];
		[usageView setNeedsDisplay:YES];
	}
	
	[window setIgnoresMouseEvents:YES];
}

#pragma mark Stuff

- (void)drawToDockIcon {
	NSRect dockIconRect = { NSZeroPoint, { DOCK_ICON_SIZE, DOCK_ICON_SIZE } };

	[dockIconUsageViewsContainingView lockFocus];
	NSBitmapImageRep *rep = [[NSBitmapImageRep alloc] initWithFocusedViewRect:dockIconRect];
	[dockIconUsageViewsContainingView unlockFocus];

	NSImage *image = [[NSImage alloc] initWithSize:dockIconRect.size];
	[image addRepresentation:rep];
	[rep release];

	//Add a border.
	[image lockFocus];
	[backgroundColor set];
	NSFrameRectWithWidth([dockIconUsageViewsContainingView frame], 2.0f);
	[image unlockFocus];

	[NSApp setApplicationIconImage:image];
	[image release];
}

#pragma mark Timer

- (void)threadedUpdateCPUUsageView:(NSTimer *)timer {
	unsigned i = [[timer userInfo] unsignedIntValue];

	CPUUsageView *view = [usageViews objectAtIndex:i];
	CPUUsageView *viewInDockIcon = [dockIconUsageViews objectAtIndex:i];

	[CPUUsageLock lock];
	[view setCPUUsage:CPUUsage[i]];
	[viewInDockIcon setCPUUsage:CPUUsage[i]];
	[CPUUsageLock unlock];

	if(shouldDrawToWindow)
		[view display];
	if(shouldDrawToDockIcon)
		[viewInDockIcon display];

	if(threadsRemainingToDie) {
		[timer invalidate];

		[deathLock lock];
		--threadsRemainingToDie;
		[deathLock unlock];
	}
}
- (void)threadedLaunchTimer:(NSNumber *)CPUIndexNum {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	NSRunLoop *runLoop = [NSRunLoop currentRunLoop];

	NSTimer *timer = [NSTimer timerWithTimeInterval:0.5
											 target:self
										   selector:@selector(threadedUpdateCPUUsageView:)
										   userInfo:CPUIndexNum //userInfo
											repeats:YES];
	[timer setFireDate:[NSDate dateWithTimeIntervalSinceNow:0.25]];

	[runLoop addTimer:timer forMode:NSDefaultRunLoopMode];
	[runLoop run];

	[pool release];
}

//Main thread.
- (void)updateCPUUsageButNotViews:(NSTimer *)timer {
	if(shouldDrawToDockIcon)
		[self drawToDockIcon];

	natural_t numProcessors_nobodyCares = 0U;
	processor_info_array_t processorInfo;
	mach_msg_type_number_t numProcessorInfo;

	kern_return_t err = host_processor_info(mach_host_self(), PROCESSOR_CPU_LOAD_INFO, &numProcessors_nobodyCares, &processorInfo, &numProcessorInfo);
	if(err == KERN_SUCCESS) {
		vm_map_t target_task = mach_task_self();

		[CPUUsageLock lock];

		for(unsigned i = 0U; i < numCPUs; ++i) {
			//We only want the last $REFRESH_TIME seconds' worth of data, not all time.
			float inUse, total;
			if(lastProcessorInfo) {
				inUse = (
				  (processorInfo[(CPU_STATE_MAX * i) + CPU_STATE_USER]   - lastProcessorInfo[(CPU_STATE_MAX * i) + CPU_STATE_USER])
				+ (processorInfo[(CPU_STATE_MAX * i) + CPU_STATE_SYSTEM] - lastProcessorInfo[(CPU_STATE_MAX * i) + CPU_STATE_SYSTEM])
				+ (processorInfo[(CPU_STATE_MAX * i) + CPU_STATE_NICE]   - lastProcessorInfo[(CPU_STATE_MAX * i) + CPU_STATE_NICE])
				);
				total = inUse + (processorInfo[(CPU_STATE_MAX * i) + CPU_STATE_IDLE] - lastProcessorInfo[(CPU_STATE_MAX * i) + CPU_STATE_IDLE]);
			} else {
				inUse = processorInfo[(CPU_STATE_MAX * i) + CPU_STATE_USER] + processorInfo[(CPU_STATE_MAX * i) + CPU_STATE_SYSTEM] + processorInfo[(CPU_STATE_MAX * i) + CPU_STATE_NICE];
				total = inUse + processorInfo[(CPU_STATE_MAX * i) + CPU_STATE_IDLE];
			}

			CPUUsage[i] = inUse / total;
		}

		[CPUUsageLock unlock];

		if(lastProcessorInfo) {
			size_t lastProcessorInfoSize = sizeof(integer_t) * numLastProcessorInfo;
			vm_deallocate(target_task, (vm_address_t)lastProcessorInfo, lastProcessorInfoSize);
		}

		lastProcessorInfo = processorInfo;
		numLastProcessorInfo = numProcessorInfo;
	} else {
		NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
			NSLocalizedString(@"Could not get CPU load information", /*comment*/ nil), NSLocalizedDescriptionKey,
			NSLocalizedString(@"Do you have a CPU in your computer? (Just kidding. I have no idea how to get a useful string from a kernel error code. --The Author)", /*comment*/ nil), NSLocalizedRecoverySuggestionErrorKey,
			nil];
		[NSApp presentError:[NSError errorWithDomain:NSMachErrorDomain code:err userInfo:dict]];
		[NSApp terminate:nil];
	}
}

#pragma mark Accessors

- (NSColor *)backgroundColor {
	return backgroundColor;
}
- (void)setBackgroundColor:(NSColor *)newBackgroundColor {
	if(backgroundColor != newBackgroundColor) {
		[backgroundColor release];
		backgroundColor = [newBackgroundColor retain];
	}
}

- (float)cellWidth {
	return cellWidth;
}
- (void)setCellWidth:(float)newCellWidth {
	cellWidth = newCellWidth;

	if(window) {
		register float numCPUsFloat = numCPUs;
		float numViewsX, numViewsY;
		if(orientation == CPUUsageOrientationHorizontal) {
			numViewsX = numCPUs;
			numViewsY = 1.0f;
		} else if(orientation == CPUUsageOrientationVertical) {
			numViewsX = 1.0f;
			numViewsY = numCPUs;
		} else {
			numViewsX = ceilf(sqrtf(numCPUsFloat));
			numViewsY = ceilf(numCPUsFloat / numViewsX);
		}

		NSRect oldFrame = [window frame];
		NSRect newFrame = oldFrame;
		newFrame.size.width  = cellWidth  * numViewsX;
		newFrame.size.height = cellHeight * numViewsY;
//		[window setFrame:newFrame display:YES animate:YES]; //For some reason, this blocks dragging the window around. Lucky me — the NSViewAnimation is prettier.
		NSDictionary *animDict = [NSDictionary dictionaryWithObjectsAndKeys:
			window, NSViewAnimationTargetKey,
			[NSValue valueWithRect:oldFrame], NSViewAnimationStartFrameKey,
			[NSValue valueWithRect:newFrame], NSViewAnimationEndFrameKey,
			nil];
		NSViewAnimation *anim = [[NSViewAnimation alloc] initWithViewAnimations:[NSArray arrayWithObject:animDict]];
		[anim startAnimation];
		[anim release];
	}
}

- (float)cellHeight {
	return cellHeight;
}
- (void)setCellHeight:(float)newCellHeight {
	cellHeight = newCellHeight;

	if(window) {
		register float numCPUsFloat = numCPUs;
		float numViewsX, numViewsY;
		if(orientation == CPUUsageOrientationHorizontal) {
			numViewsX = numCPUs;
			numViewsY = 1.0f;
		} else if(orientation == CPUUsageOrientationVertical) {
			numViewsX = 1.0f;
			numViewsY = numCPUs;
		} else {
			numViewsX = ceilf(sqrtf(numCPUsFloat));
			numViewsY = ceilf(numCPUsFloat / numViewsX);
		}

		NSRect oldFrame = [window frame];
		NSRect newFrame = oldFrame;
		newFrame.size.width  = cellWidth  * numViewsX;
		newFrame.size.height = cellHeight * numViewsY;
//		[window setFrame:frame display:YES animate:YES]; //For some reason, this blocks dragging the window around. Lucky me — the NSViewAnimation is prettier.
		NSDictionary *animDict = [NSDictionary dictionaryWithObjectsAndKeys:
			window, NSViewAnimationTargetKey,
			[NSValue valueWithRect:oldFrame], NSViewAnimationStartFrameKey,
			[NSValue valueWithRect:newFrame], NSViewAnimationEndFrameKey,
			nil];
		NSViewAnimation *anim = [[NSViewAnimation alloc] initWithViewAnimations:[NSArray arrayWithObject:animDict]];
		[anim startAnimation];
		[anim release];
	}
}

- (BOOL)shouldDrawToDockIcon {
	return shouldDrawToDockIcon;
}
- (void)setShouldDrawToDockIcon:(BOOL)flag {
	shouldDrawToDockIcon = flag;

	if(!shouldDrawToDockIcon)
		[NSApp setApplicationIconImage:[NSImage imageNamed:@"CPUUsageIcon"]];
}

- (BOOL)shouldDrawToWindow {
	return shouldDrawToWindow;
}
- (void)setShouldDrawToWindow:(BOOL)flag {
	shouldDrawToWindow = flag;

	if(shouldDrawToWindow)
		[window orderFront:nil];
	else
		[window orderOut:nil];
}

#pragma mark Actions

- (IBAction)setOrientationToVertical:sender {
	orientation = CPUUsageOrientationVertical;
	[[[NSUserDefaultsController sharedUserDefaultsController] values] setValue:[NSNumber numberWithInt:orientation] forKey:@"Window orientation"];

	[self layOutCellsInWindow:window];

	[verticalButton    setState:NSOnState];
	[horizontalButton  setState:NSOffState];
	[rectangularButton setState:NSOffState];
}
- (IBAction)setOrientationToHorizontal:sender {
	orientation = CPUUsageOrientationHorizontal;
	[[[NSUserDefaultsController sharedUserDefaultsController] values] setValue:[NSNumber numberWithInt:orientation] forKey:@"Window orientation"];

	[self layOutCellsInWindow:window];

	[verticalButton    setState:NSOffState];
	[horizontalButton  setState:NSOnState];
	[rectangularButton setState:NSOffState];
}
- (IBAction)setOrientationToRectangular:sender {
	orientation = CPUUsageOrientationRectangular;
	[[[NSUserDefaultsController sharedUserDefaultsController] values] setValue:[NSNumber numberWithInt:orientation] forKey:@"Window orientation"];

	[self layOutCellsInWindow:window];

	[verticalButton    setState:NSOffState];
	[horizontalButton  setState:NSOffState];
	[rectangularButton setState:NSOnState];
}

@end

@implementation CPUUsageMonitor (PRIVATE)

- (void)layOutCellsInWindow:(NSWindow *)thisWindow {
	[thisWindow disableScreenUpdatesUntilFlush];

	//Each cell in the Dock icon is square, so this rectangle may not be square. Consider a dual-proc machine.
	//And of course, the floater is non-square in most configurations.
	/*numCPUs = 8
	 *+--+--+
	 *|1 | 2|
	 *+-+-+-+
	 *|3|4|5|
	 *+-+-+-+
	 *|6|7|8|
	 *+-+-+-+
	 */
	register float numCPUsFloat = numCPUs;
	float numViewsX, numViewsY;
	if((thisWindow == window) && (orientation == CPUUsageOrientationHorizontal)) {
		numViewsX = numCPUsFloat;
		numViewsY = 1.0f;
	} else if((thisWindow == window) && (orientation == CPUUsageOrientationVertical)) {
		numViewsX = 1.0f;
		numViewsY = numCPUsFloat;
	} else {
		numViewsX = ceilf(sqrtf(numCPUsFloat));
		numViewsY = ceilf(numCPUsFloat / numViewsX);
	}
	BOOL drawingToDock = (thisWindow == dockIconWindow);

	NSSize cellSize;
	if(drawingToDock) {
		cellSize.width  = DOCK_ICON_SIZE / numViewsX;
		cellSize.height = DOCK_ICON_SIZE / numViewsY;
	} else {
		cellSize.width  = cellWidth;
		cellSize.height = cellHeight;
	}

	//Handle odd cells (1 and 2 above).
	//The number of cells missing from the row with the odd cells (in the example above, this = 1).
	float numCellsMissing = ((numViewsX * numViewsY) - numCPUsFloat);
	float numOddCellsFloat = numCellsMissing ? numViewsX - numCellsMissing : 0.0f;
	unsigned numOddCells = numOddCellsFloat;
	unsigned numNotOddCells = numCPUs - numOddCells;
	
	BZGridEnumerator *floaterOddCellsEnum = nil;
	BZGridEnumerator *floaterCellsEnum = [[BZGridEnumerator alloc] initWithCellSize:cellSize
																	numberOfColumns:numViewsX
																	   numberOfRows:numViewsY];
	NSRect frame = [floaterCellsEnum overallRect];
	if(numCellsMissing) {
		/*oddCellsWidth is the fraction of the total frame width used by odd cells.
		 *total = X*Y
		 *numEmptySpaces = total - numCPUs
		 *numOddCPUs = X - numEmptySpaces
		 *oddCellsWidth = numOddCPUs / X
		 */
		float oddCellsWidth = numOddCellsFloat / numViewsX;
		float oddCellWidth = oddCellsWidth / numOddCellsFloat;
		floaterOddCellsEnum = [[BZGridEnumerator alloc] initWithCellSize:(NSSize){ frame.size.width * oddCellWidth, cellSize.height }
																  offset:(NSPoint){ 0.0f, cellSize.height * numViewsY }
														 numberOfColumns:numOddCells
															numberOfRows:1U];
		frame.size.height += [floaterOddCellsEnum overallRect].size.height;
	}
	frame.origin = [thisWindow frame].origin;
	[thisWindow setFrame:frame display:NO];
	float offsetY = drawingToDock ? ((DOCK_ICON_SIZE - frame.size.height) * 0.5f) : 0.0f;

	//Sign up for notifications of pref changes.
	NSUserDefaultsController *udc = [NSUserDefaultsController sharedUserDefaultsController];
	NSDictionary *colorBindingOptions = [NSDictionary dictionaryWithObject:@"NSUnarchiveFromData" forKey:NSValueTransformerNameBindingOption];

	NSMutableArray *usageViewsArray = (thisWindow == window) ? usageViews : dockIconUsageViews;
	unsigned usageViewsArrayCount = [usageViewsArray count];

	//We need this information to set drawsFrame of every view to the correct value.
	//We don't need to retrieve it every time, so we get it once here and cache it in a variable.
	//The Dock icon window never has per-cell frames.
	BOOL shouldDrawFrame = [NSApp isActive] && (thisWindow == window);

	//Add CPU usage views.
	unsigned numCols = numViewsX, numRows = numViewsY;
	NSView *contentView = [thisWindow contentView];
	unsigned CPUNum = 0U;
	if(numCellsMissing) {
		while(numOddCells--) {
			NSRect oddCellRect = [floaterOddCellsEnum nextRect];
			oddCellRect.origin.y += offsetY;

			CPUUsageView *usageView;
			if(CPUNum >= usageViewsArrayCount) {
				usageView = [[[CPUUsageView alloc] initWithFrame:oddCellRect] autorelease];
				[contentView addSubview:usageView];
				[usageViewsArray addObject:usageView];
				++usageViewsArrayCount;
			} else {
				usageView = [usageViewsArray objectAtIndex:CPUNum];
				[usageView setFrame:oddCellRect];
			}

			[usageView setDrawsFrame:shouldDrawFrame];
			[usageView setCPUUsage:8.88f]; //XXX TEMP - Should just not update the Dock icon until after all samples anyway
			if(numCPUs > 1)
				[usageView setCPUNumber:++CPUNum];

			[usageView bind:@"textColor"
				   toObject:udc
				withKeyPath:@"values.Dock icon text color"
					options:colorBindingOptions];
			[usageView bind:@"textOpacity"
				   toObject:udc
				withKeyPath:@"values.Dock icon text opacity"
					options:nil];
			[usageView bind:@"backgroundColor"
				   toObject:self
				withKeyPath:@"backgroundColor"
					options:nil];

			oddCellRect.origin.x += oddCellRect.size.width;
		}
	}
	while(numNotOddCells--) {
		frame = [floaterCellsEnum nextRect];
		frame.origin.y += offsetY;
		unsigned col = CPUNum % numCols, row = CPUNum / numRows;

		CPUUsageView *usageView;
		if(CPUNum >= usageViewsArrayCount) {
			usageView = [[[CPUUsageView alloc] initWithFrame:frame] autorelease];
			[contentView addSubview:usageView];
			[usageViewsArray addObject:usageView];
			++usageViewsArrayCount;
		} else {
			usageView = [usageViewsArray objectAtIndex:CPUNum];
			[usageView setFrame:frame];
		}
		unsigned mask = NSViewWidthSizable | NSViewHeightSizable
			| (NSViewMinXMargin * (col  > 0U)           )
			| (NSViewMaxXMargin * (col < (numCols - 1U)))
			| (NSViewMaxYMargin * (row  > 0U)           )
			| (NSViewMinYMargin * (row < (numRows - 1U)))
			;
		[usageView setAutoresizingMask:mask];
		[usageView setMenu:contextualMenu];

		[usageView setDrawsFrame:shouldDrawFrame];
		if(numCPUs > 1)
			[usageView setCPUNumber:++CPUNum];

		[usageView bind:@"textColor"
			   toObject:udc
			withKeyPath:@"values.Floater text color"
				options:colorBindingOptions];
		[usageView bind:@"textOpacity"
			   toObject:udc
			withKeyPath:@"values.Floater text opacity"
				options:nil];
		[usageView bind:@"backgroundColor"
			   toObject:self
			withKeyPath:@"backgroundColor"
				options:nil];
	}

	[floaterOddCellsEnum release];
	[floaterCellsEnum release];
}

@end
