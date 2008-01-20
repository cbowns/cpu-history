/*
 *	CPU Mon
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


#define WIRED_COLOR_KEY		@"WiredColor"
#define ACTIVE_COLOR_KEY	@"ActiveColor"
#define INACTIVE_COLOR_KEY	@"InactiveColor"
#define FREE_COLOR_KEY		@"FreeColor"
#define PAGEIN_COLOR_KEY	@"PageinColor"
#define PAGEOUT_COLOR_KEY	@"PageoutColor"
#define OLD_TRANSPARENCY_KEY	@"Transparency"		/* for backward compatibility with 1.1 prefs file */
#define UPDATE_FREQUENCY_KEY	@"UpdateFrequency"
#define PAGING_SCALE_MAX_KEY	@"PagingScaleMax"
#define PAGEIN_ATOP_PAGEOUT_KEY	@"PageinAtopPageout"
#define SHOW_PAGING_RATE_KEY	@"ShowPagingRate"
#define SHOW_GRAPH_WINDOW_KEY	@"ShowGraphWindow"
#define GRAPH_WINDOW_ON_TOP_KEY	@"GraphWindowOnTop"
#define GRAPH_WINDOW_SIZE_KEY	@"GraphWindowSize"
#define DOCK_ICON_SIZE_KEY	@"DockIconSize"

#define PREFERENCES_CHANGED	@"PrefsChanged"


@interface Preferences : NSObject
{
	IBOutlet id		wiredColor;
	IBOutlet id		activeColor;
	IBOutlet id		inactiveColor;
	IBOutlet id		freeColor;
	IBOutlet id		pageinColor;
	IBOutlet id		pageoutColor;
	IBOutlet id		pageinAtopPageout;
	IBOutlet id		pagingScale;
	IBOutlet id		panel;
	IBOutlet id		showPagingRate;
	IBOutlet id		updateFrequency;
	IBOutlet id		updateFrequencySlider;
	IBOutlet id		showGraphWindow;
	IBOutlet id		graphWindowOnTop;
	IBOutlet id		graphWindowSize;
	IBOutlet id		graphWindowOptionsView;
	IBOutlet id		dockIconSizeSlider;
	NSMutableDictionary	*currentSettings;
}

- (IBAction)showPreferences:(id)sender;
- (IBAction)revertToDefaults:(id)sender;
- (IBAction)preferencesChanged:(id)sender;
- (void)savePreferences;
- (id)objectForKey:(id)key;
- (int)windowNumber;

@end
