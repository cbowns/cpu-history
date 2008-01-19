/*
 *	Memory Monitor
 *
 *	Copyright © 2001-2002 Bernhard Baehr
 *
 *	main.m - main() of Memory Monitor
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


#import <AppKit/AppKit.h>

#include <sys/types.h>
//sqrtf, ceilf
#include <math.h>
//sysctl and its parameters
#include <sys/sysctl.h>
//errno, strerror
#include <sys/errno.h>
#include <string.h>

#include <mach/mach.h>
#include <mach/processor_info.h>
#include <mach/mach_host.h>


typedef struct cpudata {
	double user;
	double sys;
	double nice;
	double idle;
} CPUData, *CPUDataPtr;

int main (int argc, const char *argv[])
{
	return (NSApplicationMain(argc, argv));
	
	
/*	
	processor_info_array_t processorInfo, processorInfoTwo;
	natural_t numProcessors_nobodyCares = 0U;
	mach_msg_type_number_t numProcessorInfo, numProcessorInfoTwo;

	kern_return_t err = host_processor_info(mach_host_self(), PROCESSOR_CPU_LOAD_INFO, (natural_t *)&numProcessors_nobodyCares, (processor_info_array_t *)&processorInfo, (mach_msg_type_number_t *)&numProcessorInfo);
	if(err != KERN_SUCCESS) {
		NSLog(@"getCPUStat: failed to get cpu statistics");
	}
	
	unsigned int inUse, total, user, sys, nice, idle;
	user = processorInfo[CPU_STATE_USER];
	sys  = processorInfo[CPU_STATE_SYSTEM];
	nice = processorInfo[CPU_STATE_NICE];
	idle = processorInfo[CPU_STATE_IDLE];
	
	inUse = user + sys + nice;
	total = inUse + idle;
	
	CPUData testData;	
	testData.user = (double)user / (double)total;
	testData.sys = (double)sys / (double)total;
	testData.nice = (double)nice / (double)total;
	testData.idle = (double)idle / (double)total;
	
	
	
	
	kern_return_t err2 = host_processor_info(mach_host_self(), PROCESSOR_CPU_LOAD_INFO, (natural_t *)&numProcessors_nobodyCares, (processor_info_array_t *)&processorInfoTwo, (mach_msg_type_number_t *)&numProcessorInfoTwo);
	if(err2 != KERN_SUCCESS) {
		NSLog(@"getCPUStat: failed to get cpu statistics");
	}
	
	user = processorInfoTwo[CPU_STATE_USER] - processorInfo[CPU_STATE_USER];
	sys = processorInfoTwo[CPU_STATE_SYSTEM] - processorInfo[CPU_STATE_SYSTEM];
	nice = processorInfoTwo[CPU_STATE_NICE] - processorInfo[CPU_STATE_NICE];
	idle = processorInfoTwo[CPU_STATE_IDLE] - processorInfo[CPU_STATE_IDLE];
	
	inUse = user + sys + nice;
	total = inUse + idle;
		
	testData.user = (double)user / (double)total;
	testData.sys = (double)sys / (double)total;
	testData.nice = (double)nice / (double)total;
	testData.idle = (double)idle / (double)total;
	
	
	return 0;*/
}
