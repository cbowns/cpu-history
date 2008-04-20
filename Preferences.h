/*
 *	CPU History
 *	Christopher Bowns, 2008
 *	
 *	Formerly: Memory Monitor, by Bernhard Baehr
 *
 *	Copyright © 2001-2003 Bernhard Baehr
 *
 *	Preferences.h - Preferences Controller Class
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


#import <Cocoa/Cocoa.h>

#define USER_COLOR_KEY            @"UserColor"
#define SYS_COLOR_KEY             @"SysColor"
#define NICE_COLOR_KEY            @"NiceColor"
#define IDLE_COLOR_KEY            @"IdleColor"

#define UPDATE_FREQUENCY_KEY      @"UpdateFrequency"
#define SHOW_GRAPH_WINDOW_KEY     @"ShowGraphWindow"
#define GRAPH_WINDOW_ON_TOP_KEY   @"GraphWindowOnTop"
#define GRAPH_WINDOW_SIZE_KEY     @"GraphWindowSize"
#define DOCK_ICON_SIZE_KEY        @"DockIconSize"
#define BAR_WIDTH_SIZE_KEY        @"BarWidthSize"

#define GRAPH_SPACER_WIDTH        @"GraphSpacerWidth"

#define PREFERENCES_CHANGED       @"PrefsChanged"


@interface Preferences : NSObject
{
	IBOutlet id		userColor;
	IBOutlet id		sysColor;
	IBOutlet id		niceColor;
	IBOutlet id		idleColor;
	
	IBOutlet id		panel;
	IBOutlet id		updateFrequency;
	IBOutlet id		updateFrequencySlider;
	IBOutlet id		showGraphWindow;
	IBOutlet id		graphWindowOnTop;
	IBOutlet id		graphWindowSize;
	IBOutlet id		graphWindowOptionsView;
	IBOutlet id		dockIconSizeSlider;
	IBOutlet id		barWidthSlider;
	IBOutlet id		graphSpacerSlider;
	
	NSMutableDictionary	*currentSettings;
}

- (IBAction)showPreferences:(id)sender;
- (IBAction)revertToDefaults:(id)sender;
- (IBAction)preferencesChanged:(id)sender;
- (void)savePreferences;
- (id)objectForKey:(id)key;
- (int)windowNumber;

@end
