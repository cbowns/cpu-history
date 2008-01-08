/*
 *	Memory Monitor
 *
 *	Copyright © 2001-2002 Bernhard Baehr
 *
 *	MemInfo.m - Memory Usage History Container Class
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


#import "mach/mach_host.h"
#import "MemInfo.h"


@implementation MemInfo


static void getVMStat (vm_statistics_t vmstat)
{
	unsigned count = HOST_VM_INFO_COUNT;
	
	if (host_statistics(mach_host_self(), HOST_VM_INFO, (host_info_t) vmstat, &count) != KERN_SUCCESS)
		NSLog (@"Failed to get VM statistics.");
}


- (MemInfo *) initWithCapacity:(unsigned)numItems
{
	self = [super init];
	size = numItems;
	vmdata = calloc(numItems, sizeof(VMData));
	if (vmdata == NULL) {
		NSLog (@"Failed to allocate buffer for MemInfo");
		return (nil);
	}
	inptr = 0;
	outptr = -1;
	getVMStat (&lastvmstat);
	return (self);
}


- (void)refresh
{
	vm_statistics_data_t	vmstat;
	double			total;
	
	getVMStat (&vmstat);
	total = vmstat.wire_count + vmstat.active_count + vmstat.inactive_count + vmstat.free_count;
	vmdata[inptr].wired = vmstat.wire_count / total;
	vmdata[inptr].active = vmstat.active_count / total;
	vmdata[inptr].inactive = vmstat.inactive_count / total;
	vmdata[inptr].free = vmstat.free_count / total;
	vmdata[inptr].pageins =  vmstat.pageins - lastvmstat.pageins;
	vmdata[inptr].pageouts = vmstat.pageouts - lastvmstat.pageouts;
	lastvmstat = vmstat;
	if (++inptr >= size)
		inptr = 0;
}


- (void)startIterate
{
	outptr = inptr;
}


- (BOOL)getNext:(VMDataPtr)ptr
{
	if (outptr == -1)
		return (FALSE);
	*ptr = vmdata[outptr++];
	if (outptr >= size)
		outptr = 0;
	if (outptr == inptr)
		outptr = -1;
	return (TRUE);
}


- (void)getCurrent:(VMDataPtr)ptr
{
	*ptr = vmdata[inptr ? inptr - 1 : size - 1];
}


- (void)getLast:(VMDataPtr)ptr
{
	*ptr = vmdata[inptr > 1 ? inptr - 2 : size + inptr - 2];
}


- (int)getSize
{
	return (size);
}


@end
