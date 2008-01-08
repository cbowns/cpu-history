//
//  CPUUsageMonitor.h
//  CPU Usage
//
//  Created by Peter Hosey on 2006-06-21.
//  Copyright 2006 Peter Hosey. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#include <mach/mach.h>
#include <mach/processor_info.h>
#include <mach/mach_host.h>

enum CPUUsageOrientation {
	CPUUsageOrientationVertical,
	CPUUsageOrientationHorizontal,
	CPUUsageOrientationRectangular
};

@interface CPUUsageMonitor : NSObject {
	NSWindow *window;
	NSPanel *dockIconWindow; //Dock icon view is put in here.

	//Preferences views.
	IBOutlet NSPanel *preferencesPanel;
	NSColor *backgroundColor;
	float cellWidth, cellHeight;
	IBOutlet NSTextField *widthField, *heightField;
	IBOutlet NSButton *horizontalButton, *verticalButton, *rectangularButton;

	IBOutlet NSMenu *contextualMenu;

	NSMutableArray *usageViews, *dockIconUsageViews;
	NSView *dockIconUsageViewsContainingView;
	enum CPUUsageOrientation orientation;
	BOOL shouldDrawToDockIcon, shouldDrawToWindow;

	NSTimer *updateTimer;
	processor_info_array_t lastProcessorInfo;
	mach_msg_type_number_t numLastProcessorInfo;
	unsigned numCPUs;
	float *CPUUsage;
	NSLock *CPUUsageLock, *deathLock;
	unsigned threadsRemainingToDie;
	BOOL threadsShouldExit;

	//Saved preferences, for restoration after Cancel.
	NSColor *savedBackgroundColor;
	NSSize   savedCellSize;
	enum CPUUsageOrientation savedOrientation;
}

#pragma mark Accessors

- (NSColor *)backgroundColor;
- (void)setBackgroundColor:(NSColor *)newBackgroundColor;

- (float)cellWidth;
- (void)setCellWidth:(float)newCellWidth;

- (float)cellHeight;
- (void)setCellHeight:(float)newCellHeight;

- (BOOL)shouldDrawToDockIcon;
- (void)setShouldDrawToDockIcon:(BOOL)flag;

- (BOOL)shouldDrawToWindow;
- (void)setShouldDrawToWindow:(BOOL)flag;

#pragma mark Actions

- (IBAction)setOrientationToVertical:sender;
- (IBAction)setOrientationToHorizontal:sender;
- (IBAction)setOrientationToRectangular:sender;

@end
