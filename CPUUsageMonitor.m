//
//  CPUUsageMonitor.m
//  CPU Usage
//
//  Created by Peter Hosey on 2006-06-21.
//  Copyright 2006 Peter Hosey. All rights reserved.
//

#import "CPUUsageMonitor.h"


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


@implementation CPUUsageMonitor

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
}

//Main thread.
- (void)updateCPUUsage {
	
	natural_t numProcessors_nobodyCares = 0U;
	processor_info_array_t processorInfo;
	mach_msg_type_number_t numProcessorInfo;

	kern_return_t err = host_processor_info(mach_host_self(), PROCESSOR_CPU_LOAD_INFO, &numProcessors_nobodyCares, &processorInfo, &numProcessorInfo);
	if(err == KERN_SUCCESS) {
		vm_map_t target_task = mach_task_self();

		// [CPUUsageLock lock];

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

		// [CPUUsageLock unlock];

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

@end
