//
//  CPUInfo.m
//  CPU Usage
//
//  Created by Peter Hosey on 2006-06-21.
//  Copyright 2006 Peter Hosey. All rights reserved.
//
//  Modified by Christopher Bowns, starting 2007-1-1.

#ifndef NSLOG_DEBUG
#define NSLOG_DEBUG
#endif

#import "CPUInfo.h"

#include <sys/types.h>
//sqrtf, ceilf
#include <math.h>
//sysctl and its parameters
#include <sys/sysctl.h>
//errno, strerror
#include <sys/errno.h>
#include <string.h>

@implementation CPUInfo

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
		NSLog(@"getCPUStat: failed to get cpu statistics");
	}
}

- (CPUInfo *) initWithCapacity:(unsigned)numItems
{
	self = [super init];
	
	/*
		from CPU usage
	*/	
	//We could get the number of processors the same way that we get the CPU usage info, but that allocates memory.
/*	enum { miblen = 2U };
	int mib[miblen] = { CTL_HW, HW_NCPU };
	size_t sizeOfNumCPUs = sizeof(numCPUs);
	int status = sysctl(mib, miblen,
		   &numCPUs, &sizeOfNumCPUs,
*/		   /*newp*/ // NULL, /*newlen*/ 0U);
//	if(status != 0) {
		numCPUs = 1; // TODO we're going to assume one CPU for the moment.
//		NSLog(@"%s error status, assuming one CPU", _cmd);
//	}	
	/*
		from meminfo
	*/
	size = numItems;
	cpudata = calloc(numItems, sizeof(CPUData));
	if (cpudata == NULL) {
		NSLog (@"Failed to allocate buffer for CPUInfo");
		return (nil);
	}
	inptr = 0;
	outptr = -1;
	getCPUStat (lastcpustat);

	return (self);
}

- (void)refresh
{
	processor_info_array_t cpustat;
		
	getCPUStat (cpustat);
	/*
		TODO make this multicore. First, we're gonna need a multicore machine to test it on.
	*/
	// for(unsigned i = 0U; i < numCPUs; ++i) {
	unsigned i = 0U;
	
	double inUse, total, user, sys, nice, idle;
	user = cpustat[CPU_STATE_USER];
	sys  = cpustat[CPU_STATE_SYSTEM];
	nice = cpustat[CPU_STATE_NICE];
	idle = cpustat[CPU_STATE_IDLE];
	
	inUse = user + sys + nice;
	total = inUse + idle;
	
	#ifdef NSLOG_DEBUG
	NSLog(@"%s in use: %f   idle: %f", _cmd, inUse, idle);
	#endif
	
	cpudata[inptr].user = (double)user;
	cpudata[inptr].sys = (double)sys;
	cpudata[inptr].nice = (double)nice;
	cpudata[inptr].idle = (double)idle;
	lastcpustat = cpustat;
	if (++inptr >= size) // advance our data ptr
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
