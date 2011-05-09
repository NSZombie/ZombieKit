//
// Copyright 2011 Jason Foreman and Josh Weinberg.
// 
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "ZMBViewController.h"

#import <objc/runtime.h>


@interface ZMBViewController ()
@property (retain) NSMutableSet *managedOutlets;
@end


@implementation ZMBViewController

@synthesize managedOutlets;

- (void) dealloc;
{
	// Set all outlets to nil using KVC
	[self.managedOutlets enumerateObjectsUsingBlock:^(id key, BOOL *stop) {
		[self setValue:nil forKey:key];
	}];
	self.managedOutlets = nil;
    [super dealloc];
}

- (void) loadView;
{
	// Swizzle in our version of setValue:forKey: that tracks KVO
	Method orig = class_getInstanceMethod([self class], @selector(setValue:forKey:));
	Method mine = class_getInstanceMethod([self class], @selector(zmb_setValue:forKey:));
	method_exchangeImplementations(orig, mine);
	
	self.managedOutlets = [NSMutableSet set];
	[super loadView];
	
	// We don't need to track the view outlet, as this will be handled by UIViewController
	[self.managedOutlets removeObject:@"view"];
	
	// put the original setValue:forKey: back like nothing ever happened.
	method_exchangeImplementations(orig, mine);
}

- (void) viewDidUnload;
{
	[super viewDidUnload];
	
	// Set all outlets to nil using KVC
	[self.managedOutlets enumerateObjectsUsingBlock:^(id key, BOOL *stop) {
		[self setValue:nil forKey:key];
	}];
	self.managedOutlets = nil;
}

- (void) zmb_setValue:(id)value forKey:(NSString *)key;
{
	[self.managedOutlets addObject:key];
	
	// this will call the original setValue:forKey
	// once they are swizzled
	[self zmb_setValue:value forKey:key];
}

@end
