/*
 *	CPU History
 *	Christopher Bowns, 2008
 *	
 *	Formerly: Memory Monitor, by Bernhard Baehr
 *
 *	Copyright © 2001-2003 Bernhard Baehr
 *
 *	Preferences.m - Preferences Controller Class
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


#import "Preferences.h"


@implementation Preferences


+ (NSMutableDictionary *)defaultPreferences
{
	return ([[NSMutableDictionary alloc] initWithObjectsAndKeys:
/*		[[NSColor yellowColor] colorWithAlphaComponent:0.8], WIRED_COLOR_KEY,
		[[NSColor magentaColor] colorWithAlphaComponent:0.8], ACTIVE_COLOR_KEY,
		[[NSColor cyanColor] colorWithAlphaComponent:0.8], INACTIVE_COLOR_KEY,
		[[NSColor blueColor] colorWithAlphaComponent:0.8], FREE_COLOR_KEY,
		
		[NSColor whiteColor], PAGEIN_COLOR_KEY,
		[NSColor blackColor], PAGEOUT_COLOR_KEY,
		[NSNumber numberWithInt:250], PAGING_SCALE_MAX_KEY,
		[NSNumber numberWithBool:YES], PAGEIN_ATOP_PAGEOUT_KEY,
		[NSNumber numberWithBool:YES], SHOW_PAGING_RATE_KEY,
*/		
		
		// Colors taken from samples of 10.5's Activity Monitor
		[NSColor colorWithCalibratedRed:0.304875 green:0.931411 blue:0.294072 alpha:1.0 ], USER_COLOR_KEY,
		[NSColor colorWithCalibratedRed:0.933211 green:0.219913 blue:0.200565 alpha:1.0 ], SYS_COLOR_KEY,
		[NSColor colorWithCalibratedRed:0.200638 green:0.000533 blue:1.0 alpha:1.0 ], NICE_COLOR_KEY,
		[[NSColor blackColor] colorWithAlphaComponent:1.0], IDLE_COLOR_KEY,
		
		
		[NSNumber numberWithInt:10], UPDATE_FREQUENCY_KEY,	/* unit is 1/10 second */
		[NSNumber numberWithBool:NO], SHOW_GRAPH_WINDOW_KEY,
		[NSNumber numberWithBool:NO], GRAPH_WINDOW_ON_TOP_KEY,
		[NSNumber numberWithInt:128], GRAPH_WINDOW_SIZE_KEY,
		[NSNumber numberWithFloat:1.0], DOCK_ICON_SIZE_KEY,
		nil]);
}


- (id)init
{
#define SCANCOLOR(key)	\
	if ((obj = [defaults objectForKey:key])) { \
		a = transparency; \
		sscanf ([obj cString], "%f %f %f %f", &r, &g, &b, &a); \
		obj = [NSColor colorWithCalibratedRed:r green:g blue:b alpha:a]; \
		[currentSettings setObject:obj forKey:key]; \
	}
#define GETNUMBER(key)	\
	if ((obj = [defaults objectForKey:key])) \
		[currentSettings setObject:obj forKey:key];

	id	obj;
	float	r, g, b, a, transparency = 0.0;

	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	
	self = [super init];
        currentSettings = [Preferences defaultPreferences];
/*	SCANCOLOR (WIRED_COLOR_KEY);
	SCANCOLOR (ACTIVE_COLOR_KEY);
	SCANCOLOR (INACTIVE_COLOR_KEY);
	SCANCOLOR (FREE_COLOR_KEY);
	SCANCOLOR (PAGEIN_COLOR_KEY);
	SCANCOLOR (PAGEOUT_COLOR_KEY);
	GETNUMBER (PAGING_SCALE_MAX_KEY);
	GETNUMBER (PAGEIN_ATOP_PAGEOUT_KEY);
	GETNUMBER (SHOW_PAGING_RATE_KEY);
*/
	// transparency = 1.0;			/* paging was drawn without transparency in version 1.1 */
	// GETNUMBER (OLD_TRANSPARENCY_KEY);

	SCANCOLOR (USER_COLOR_KEY);
	SCANCOLOR (SYS_COLOR_KEY);
	SCANCOLOR (NICE_COLOR_KEY);
	SCANCOLOR (IDLE_COLOR_KEY);
	GETNUMBER (UPDATE_FREQUENCY_KEY);
	GETNUMBER (SHOW_GRAPH_WINDOW_KEY);
	GETNUMBER (GRAPH_WINDOW_ON_TOP_KEY);
	GETNUMBER (GRAPH_WINDOW_SIZE_KEY);
	GETNUMBER (DOCK_ICON_SIZE_KEY);
	transparency = obj ? [obj floatValue] : 0.8;	/* global transparency setting of version 1.1 */
	[[NSColorPanel sharedColorPanel] setShowsAlpha:YES];
	return (self);
}


- (void)showUpdateFrequency:(int)freq
{
	[updateFrequency setStringValue:[NSString
		localizedStringWithFormat:NSLocalizedString(@"every\n%.1f sec.", @""), freq / 10.0]];
}


- (void)adjustGraphWindowControls
{	
	id	obj;
	
	BOOL enabled = [[currentSettings objectForKey:SHOW_GRAPH_WINDOW_KEY] boolValue];
	NSColor *color = enabled ? [NSColor controlTextColor] : [NSColor controlHighlightColor];
	NSEnumerator *enumerator = [[graphWindowOptionsView subviews] objectEnumerator];
	
	while ((obj = [enumerator nextObject])) {
		if ([obj isMemberOfClass:[NSTextField class]])
			[obj setTextColor:color];
		else
			[obj setEnabled:enabled];
	}
}


- (IBAction)showPreferences:(id)sender
{
	double	freq;
	
	if (! panel) {
		if ([NSBundle loadNibNamed:@"Preferences" owner:self])
			[panel center];
		else {
			NSLog (@"Failed to load Preferences.nib");
			return;
		}
	}
	
/*	[wiredColor setColor:[currentSettings objectForKey:WIRED_COLOR_KEY]];
	[activeColor setColor:[currentSettings objectForKey:ACTIVE_COLOR_KEY]];
	[inactiveColor setColor:[currentSettings objectForKey:INACTIVE_COLOR_KEY]];
	[freeColor setColor:[currentSettings objectForKey:FREE_COLOR_KEY]];
	[pageinColor setColor:[currentSettings objectForKey:PAGEIN_COLOR_KEY]];
	[pageoutColor setColor:[currentSettings objectForKey:PAGEOUT_COLOR_KEY]];
	[pagingScale selectItemAtIndex:[pagingScale
		indexOfItemWithTag:[[currentSettings objectForKey:PAGING_SCALE_MAX_KEY] intValue]]];
	[pageinAtopPageout selectCellWithTag:[[currentSettings objectForKey:PAGEIN_ATOP_PAGEOUT_KEY] intValue]];
	[showPagingRate setState:[[currentSettings objectForKey:SHOW_PAGING_RATE_KEY] boolValue]];
*/

	[userColor setColor:[currentSettings objectForKey:USER_COLOR_KEY]];
	[sysColor setColor:[currentSettings objectForKey:SYS_COLOR_KEY]];
	[niceColor setColor:[currentSettings objectForKey:NICE_COLOR_KEY]];
	[idleColor setColor:[currentSettings objectForKey:IDLE_COLOR_KEY]];

	freq = [[currentSettings objectForKey:UPDATE_FREQUENCY_KEY] floatValue];
	[self showUpdateFrequency:(int)freq];
	[updateFrequencySlider setFloatValue:1000.0 * log(freq)];
	[showGraphWindow setState:[[currentSettings objectForKey:SHOW_GRAPH_WINDOW_KEY] boolValue]];
	[graphWindowOnTop setState:[[currentSettings objectForKey:GRAPH_WINDOW_ON_TOP_KEY] boolValue]];
	[graphWindowSize setFloatValue:[[currentSettings objectForKey:GRAPH_WINDOW_SIZE_KEY] floatValue]];
	[dockIconSizeSlider setFloatValue:[[currentSettings objectForKey:DOCK_ICON_SIZE_KEY] floatValue]];
	[self adjustGraphWindowControls];
	[panel makeKeyAndOrderFront:nil];
}


- (IBAction)revertToDefaults:(id)sender
{
	[currentSettings release];
	currentSettings = [Preferences defaultPreferences];
	[self showPreferences:sender];
	[[NSNotificationCenter defaultCenter] postNotificationName:PREFERENCES_CHANGED object:nil];
}


- (void)savePreferences
{
	id		obj;
	float		r, g, b, a;
	NSString	*key;
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSEnumerator *enumerator = [currentSettings keyEnumerator];

	while ((key = [enumerator nextObject])) {
		obj = [currentSettings objectForKey:key];
		if ([obj isKindOfClass:[NSColor class]]) {
			[[obj colorUsingColorSpaceName:@"NSCalibratedRGBColorSpace"]
				getRed:&r green:&g blue:&b alpha:&a];
			[obj release];
			obj = [NSString stringWithFormat:@"%f %f %f %f", r, g, b, a];
		}
		[defaults setObject:obj forKey:key];
	}
}


- (id)objectForKey:(id)key
{
	return ([currentSettings objectForKey:key]);
}


- (IBAction)preferencesChanged:(id)sender
{
	int	freq;
	
/*	[currentSettings setObject:[wiredColor color] forKey:WIRED_COLOR_KEY];
	[currentSettings setObject:[activeColor color] forKey:ACTIVE_COLOR_KEY];
	[currentSettings setObject:[inactiveColor color] forKey:INACTIVE_COLOR_KEY];
	[currentSettings setObject:[freeColor color] forKey:FREE_COLOR_KEY];
	[currentSettings setObject:[pageinColor color] forKey:PAGEIN_COLOR_KEY];
	[currentSettings setObject:[pageoutColor color] forKey:PAGEOUT_COLOR_KEY];
	[currentSettings setObject:[NSNumber numberWithInt:[[pagingScale selectedItem] tag]] forKey:PAGING_SCALE_MAX_KEY];
	[currentSettings setObject:[NSNumber numberWithInt:[[pageinAtopPageout selectedCell] tag]] forKey:PAGEIN_ATOP_PAGEOUT_KEY];
	[currentSettings setObject:[NSNumber numberWithInt:[showPagingRate state]] forKey:SHOW_PAGING_RATE_KEY];
*/



	[currentSettings setObject:[userColor color] forKey:USER_COLOR_KEY];
	[currentSettings setObject:[sysColor color] forKey:SYS_COLOR_KEY];
	[currentSettings setObject:[niceColor color] forKey:NICE_COLOR_KEY];
	[currentSettings setObject:[idleColor color] forKey:IDLE_COLOR_KEY];

	freq = exp([updateFrequencySlider doubleValue] / 1000.0);	/* 1..600 == 0.1 sec. to 1 min. */
	[self showUpdateFrequency:freq];
	[currentSettings setObject:[NSNumber numberWithInt:freq] forKey:UPDATE_FREQUENCY_KEY];
	[currentSettings setObject:[NSNumber numberWithInt:[showGraphWindow state]] forKey:SHOW_GRAPH_WINDOW_KEY];
	[currentSettings setObject:[NSNumber numberWithInt:[graphWindowOnTop state]] forKey:GRAPH_WINDOW_ON_TOP_KEY];
	[currentSettings setObject:[NSNumber numberWithInt:[graphWindowSize intValue]] forKey:GRAPH_WINDOW_SIZE_KEY];
	[currentSettings setObject:[NSNumber numberWithFloat:[dockIconSizeSlider floatValue]] forKey:DOCK_ICON_SIZE_KEY];
	[self adjustGraphWindowControls];
	[[NSNotificationCenter defaultCenter] postNotificationName:PREFERENCES_CHANGED object:nil];
}


- (int)windowNumber
{
	return (panel ? [panel windowNumber] : 0);
}


@end
