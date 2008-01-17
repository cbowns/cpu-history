//
//  CPUInfo.m
//  CPU Usage
//
//  Created by Peter Hosey on 2006-06-21.
//  Copyright 2006 Peter Hosey. All rights reserved.
//
//  Modified by Christopher Bowns, starting 2007-1-1.

#import "CPUInfo.h"

#import "BZGridEnumerator.h"

#include <sys/types.h>
//sqrtf, ceilf
#include <math.h>
//sysctl and its parameters
#include <sys/sysctl.h>
//errno, strerror
#include <sys/errno.h>
#include <string.h>

@implementation CPUInfo

- (void)init {

	//We could get the number of processors the same way that we get the CPU usage info, but that allocates memory.
	enum { miblen = 2U };
	int mib[miblen] = { CTL_HW, HW_NCPU };
	size_t sizeOfNumCPUs = sizeof(numCPUs);
	int status = sysctl(mib, miblen,
		   &numCPUs, &sizeOfNumCPUs,
		   /*newp*/ NULL, /*newlen*/ 0U);
	if(status != 0)
		numCPUs = 1; //XXX Should probably error out instead…


	CPUUsageLock = [[NSLock alloc] init];
	CPUUsage = NSZoneMalloc([self zone], numCPUs * sizeof(float));

}

- (void)dealloc {
	NSZoneFree([self zone], CPUUsage);
	[CPUUsageLock release];
}

//Main thread.
// - (void)updateCPUUsage {
static void getCPUStat (processor_info_array_t cpustat)
{
	processor_info_array_t processorInfo;
	natural_t numProcessors_nobodyCares = 0U;
	mach_msg_type_number_t numProcessorInfo;

	kern_return_t err = host_processor_info(mach_host_self(), PROCESSOR_CPU_LOAD_INFO, &numProcessors_nobodyCares, &processorInfo, &numProcessorInfo);
	if(err == KERN_SUCCESS) {
		cpustat = processorInfo;
	}
	else {
		NSLog(@"%s failed to get cpu statistics", _cmd);
	}
}

/*
		{
		vm_map_t target_task = mach_task_self();

		// [CPUUsageLock lock];

		for(unsigned i = 0U; i < numCPUs; ++i) {
			//We only want the last $REFRESH_TIME seconds' worth of data, not all time.
			float inUse, total, user, sys, nice, idle;
			if(lastProcessorInfo) {
				inUse = (
				  (processorInfo[(CPU_STATE_MAX * i) + CPU_STATE_USER]   - lastProcessorInfo[(CPU_STATE_MAX * i) + CPU_STATE_USER])
				+ (processorInfo[(CPU_STATE_MAX * i) + CPU_STATE_SYSTEM] - lastProcessorInfo[(CPU_STATE_MAX * i) + CPU_STATE_SYSTEM])
				+ (processorInfo[(CPU_STATE_MAX * i) + CPU_STATE_NICE]   - lastProcessorInfo[(CPU_STATE_MAX * i) + CPU_STATE_NICE])
				);
				total = inUse + (processorInfo[(CPU_STATE_MAX * i) + CPU_STATE_IDLE] - lastProcessorInfo[(CPU_STATE_MAX * i) + CPU_STATE_IDLE]);
				user = (processorInfo[(CPU_STATE_MAX * i) + CPU_STATE_USER] - lastProcessorInfo[(CPU_STATE_MAX * i) + CPU_STATE_USER]);
				sys = (processorInfo[(CPU_STATE_MAX * i) + CPU_STATE_SYSTEM] - lastProcessorInfo[(CPU_STATE_MAX * i) + CPU_STATE_SYSTEM]);
				nice = (processorInfo[(CPU_STATE_MAX * i) + CPU_STATE_NICE] - lastProcessorInfo[(CPU_STATE_MAX * i) + CPU_STATE_NICE]);
				idle = (processorInfo[(CPU_STATE_MAX * i) + CPU_STATE_IDLE] - lastProcessorInfo[(CPU_STATE_MAX * i) + CPU_STATE_IDLE]);
			}
			else {
				user = processorInfo[(CPU_STATE_MAX * i) + CPU_STATE_USER];
				sys = processorInfo[(CPU_STATE_MAX * i) + CPU_STATE_SYSTEM];
				nice = processorInfo[(CPU_STATE_MAX * i) + CPU_STATE_NICE];
				idle = processorInfo[(CPU_STATE_MAX * i) + CPU_STATE_IDLE];
				
				inUse = processorInfo[(CPU_STATE_MAX * i) + CPU_STATE_USER] + processorInfo[(CPU_STATE_MAX * i) + CPU_STATE_SYSTEM] + processorInfo[(CPU_STATE_MAX * i) + CPU_STATE_NICE];
				total = inUse + processorInfo[(CPU_STATE_MAX * i) + CPU_STATE_IDLE];
			}
			if (total - user - sys - nice - idle > 0.001 ) 
			{
				NSLog(@"%s total is not equal to user + sys + nice + idle", _cmd);
			}

			CPUUsage[i] = inUse / total;
		}

		// [CPUUsageLock unlock];

		if(lastProcessorInfo) {
			size_t lastProcessorInfoSize = sizeof(integer_t) * numLastProcessorInfo;
			vm_deallocate(target_task, (vm_address_t)lastProcessorInfo, lastProcessorInfoSize);
		}

		lastProcessorInfo = processorInfo;
		numLastProcessorInfo = numProcessorInfo;
	}
	else {
		NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
			NSLocalizedString(@"Could not get CPU load information", // comment
			nil), NSLocalizedDescriptionKey,
			NSLocalizedString(@"Do you have a CPU in your computer? (Just kidding. I have no idea how to get a useful string from a kernel error code. --The Author)", // comment
			 nil), NSLocalizedRecoverySuggestionErrorKey,
			nil];
		[NSApp presentError:[NSError errorWithDomain:NSMachErrorDomain code:err userInfo:dict]];
		[NSApp terminate:nil];
	}
} */

- (CPUInfo *) initWithCapacity:(unsigned)numItems
{
	self = [super init];
	size = numItems;
	cpudata = calloc(numItems, sizeof(CPUData));
	if (cpudata == NULL) {
		NSLog (@"Failed to allocate buffer for CPUUsageMonitor");
		return (nil);
	}
	inptr = 0;
	outptr = -1;
	getCPUStat ( &lastProcessorInfo);
	/*
		TODO done: initWithCapacity:numitems :: do we need to get the initial cpu data here?
	*/
	return (self);
}


- (void)refresh
{
	// vm_statistics_data_t	vmstat;
	processor_info_array_t cpustat;
	double			total;
	
	getCPUStat (&cpustat);
	// getVMStat (&vmstat);
	/*
		TODO make this multicore. First, we're gonna need a multicore machine to test it on.
	*/
	
	// for(unsigned i = 0U; i < numCPUs; ++i) {
		/*
			TODO loop this when we have > 1 cpu core. test with dad and eric?
		*/
	unsigned i = 0U;
	//We only want the last $REFRESH_TIME seconds' worth of data, not all time.
	float inUse, total, user, sys, nice, idle;
	if(lastProcessorInfo) {
		inUse = (
		  (processorInfo[(CPU_STATE_MAX * i) + CPU_STATE_USER]   - lastProcessorInfo[(CPU_STATE_MAX * i) + CPU_STATE_USER])
		+ (processorInfo[(CPU_STATE_MAX * i) + CPU_STATE_SYSTEM] - lastProcessorInfo[(CPU_STATE_MAX * i) + CPU_STATE_SYSTEM])
		+ (processorInfo[(CPU_STATE_MAX * i) + CPU_STATE_NICE]   - lastProcessorInfo[(CPU_STATE_MAX * i) + CPU_STATE_NICE])
		);
		total = inUse + (processorInfo[(CPU_STATE_MAX * i) + CPU_STATE_IDLE] - lastProcessorInfo[(CPU_STATE_MAX * i) + CPU_STATE_IDLE]);
		user = (processorInfo[(CPU_STATE_MAX * i) + CPU_STATE_USER] - lastProcessorInfo[(CPU_STATE_MAX * i) + CPU_STATE_USER]);
		sys = (processorInfo[(CPU_STATE_MAX * i) + CPU_STATE_SYSTEM] - lastProcessorInfo[(CPU_STATE_MAX * i) + CPU_STATE_SYSTEM]);
		nice = (processorInfo[(CPU_STATE_MAX * i) + CPU_STATE_NICE] - lastProcessorInfo[(CPU_STATE_MAX * i) + CPU_STATE_NICE]);
		idle = (processorInfo[(CPU_STATE_MAX * i) + CPU_STATE_IDLE] - lastProcessorInfo[(CPU_STATE_MAX * i) + CPU_STATE_IDLE]);
	}
	else {
		user = processorInfo[(CPU_STATE_MAX * i) + CPU_STATE_USER];
		sys = processorInfo[(CPU_STATE_MAX * i) + CPU_STATE_SYSTEM];
		nice = processorInfo[(CPU_STATE_MAX * i) + CPU_STATE_NICE];
		idle = processorInfo[(CPU_STATE_MAX * i) + CPU_STATE_IDLE];
		
		inUse = processorInfo[(CPU_STATE_MAX * i) + CPU_STATE_USER] + processorInfo[(CPU_STATE_MAX * i) + CPU_STATE_SYSTEM] + processorInfo[(CPU_STATE_MAX * i) + CPU_STATE_NICE];
		total = inUse + processorInfo[(CPU_STATE_MAX * i) + CPU_STATE_IDLE];
	}
	if (total - user - sys - nice - idle > 0.001 ) 
	{
		NSLog(@"%s total is not equal to user + sys + nice + idle", _cmd);
	}

	CPUUsage[i] = inUse / total;
	// }

	// [CPUUsageLock unlock];

	if(lastProcessorInfo) {
		size_t lastProcessorInfoSize = sizeof(integer_t) * numLastProcessorInfo;
		vm_deallocate(target_task, (vm_address_t)lastProcessorInfo, lastProcessorInfoSize);
	}
	
	
	
	
	
	
	
	// total = vmstat.wire_count + vmstat.active_count + vmstat.inactive_count + vmstat.free_count;
	/*
		TODO now that we have usage numbers, update cpudata[] with it, like they do here.
	*/
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


- (BOOL)getNext:(CPUDataPtr)ptr
{
	if (outptr == -1)
		return (FALSE);
	*ptr = cpudata[outptr++];
	if (outptr >= size)
		outptr = 0;
	if (outptr == inptr)
		outptr = -1;
	return (TRUE);
}


- (void)getCurrent:(CPUDataPtr)ptr
{
	*ptr = cpudata[inptr ? inptr - 1 : size - 1];
}


- (void)getLast:(CPUDataPtr)ptr
{
	*ptr = cpudata[inptr > 1 ? inptr - 2 : size + inptr - 2];
}


- (int)getSize
{
	return (size);
}


@end
