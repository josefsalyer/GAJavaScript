/*
 Copyright (c) 2010 Andrew Goodale. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are
 permitted provided that the following conditions are met:
 
 1. Redistributions of source code must retain the above copyright notice, this list of
 conditions and the following disclaimer.
 
 2. Redistributions in binary form must reproduce the above copyright notice, this list
 of conditions and the following disclaimer in the documentation and/or other materials
 provided with the distribution.
 
 THIS SOFTWARE IS PROVIDED BY ANDREW GOODALE "AS IS" AND ANY EXPRESS OR IMPLIED
 WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
 FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL <COPYRIGHT HOLDER> OR
 CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
 ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 
 The views and conclusions contained in the software and documentation are those of the
 authors and should not be interpreted as representing official policies, either expressed
 or implied, of Andrew Goodale.
*/ 

#import "GAScriptObject.h"
#import "NSObject+GAJavaScript.h"

typedef struct /* GAScriptObjectEnumState */
{
    unsigned long	state;
    id *			itemsPtr;
    unsigned long *	mutationsPtr;
    unsigned long	extra_0;
    NSArray *		propNames;
    unsigned long	extra_2;
    unsigned long	extra_3;
    unsigned long	extra_4;
} GAScriptObjectEnumState;

static NSString* const GAJavaScriptErrorDomain = @"GAJavaScriptException";

@interface GAScriptObject ()

- (void)releaseReference;

- (id)convertScriptResult:(NSString *)result reference:(NSString *)reference;

- (NSArray *)arrayFromJavaScript:(NSString *)result reference:(NSString *)reference;

@end

#pragma mark -

@implementation GAScriptObject

static NSNumberFormatter* kNumFormatter = nil;

- (id)initForReference:(NSString *)reference view:(UIWebView *)webView
{
	if ((self = [super init]))
	{
		m_webView = webView;
		m_objReference = [reference retain];
	}
	
	if (kNumFormatter == nil)
		kNumFormatter = [[NSNumberFormatter alloc] init];
	
	return self;
}

- (void)dealloc
{
	[self releaseReference];
	[m_objReference release];
	
	[super dealloc];
}

- (void)releaseReference
{
	if ([m_objReference length] < 18)
		return;
	
	if ([[m_objReference substringToIndex:17] isEqualToString:@"GAJavaScript.ref["])
	{
		NSString* js = [NSString stringWithFormat:@"delete %@", m_objReference];
		[m_webView stringByEvaluatingJavaScriptFromString:js];
	}
}

/*
 * Override the default implementation to handle comparisons with other GAScriptObjects.
 * Note that we can also compare with NSNull easily here. 
 */
- (BOOL)isEqual:(id)object
{
	if (object == self)
		return YES;
	
	if (object == [NSNull null])
	{
		NSString* js = [NSString stringWithFormat:@"%@ == null", m_objReference];
		NSString* result = [m_webView stringByEvaluatingJavaScriptFromString:js];
		
		return [result isEqualToString:@"true"];
	}
	
	if ([object isKindOfClass:[GAScriptObject class]])
	{
		if ([m_objReference isEqualToString:[object stringForJavaScript]])
			return YES;
		
		// The references may be different string values, but still refer to the same object.
		// For example, "document" and "window.document"
		//
		NSString* js = [NSString stringWithFormat:@"%@ == %@", m_objReference, [object stringForJavaScript]];
		NSString* result = [m_webView stringByEvaluatingJavaScriptFromString:js];
		
		return [result isEqualToString:@"true"];		
	}
	
	return [super isEqual:object];
}

/*
 * Override the default implementation and return our object reference.
 */
- (NSString *)stringForJavaScript
{
	return m_objReference;
}

- (NSArray *)allKeys
{	
	NSString* js = [NSString stringWithFormat:@"GAJavaScript.propsOf(%@)", m_objReference];
	NSString* result = [m_webView stringByEvaluatingJavaScriptFromString:js];
	//	NSLog(@"JS allKeys: %@", result);
	
	if ([result length] == 0)	// If the result is '', then we just return an empty array. 
		return [NSArray array];
	
	// Will come back as a comma-delimited list of names
	//
	return [result componentsSeparatedByString:@","];	
}

- (id)callFunction:(NSString *)functionName
{	
	NSString* js = [NSString stringWithFormat:@"GAJavaScript.valueToString(%@.%@())", 
					m_objReference, functionName];
	NSString* result = [m_webView stringByEvaluatingJavaScriptFromString:js];	
	
	return [self convertScriptResult:result reference:m_objReference];
}

- (id)callFunction:(NSString *)functionName withObject:(id)argument
{	
	NSString* js = [NSString stringWithFormat:@"GAJavaScript.valueToString(%@.%@(%@))", 
					m_objReference, functionName, [argument stringForJavaScript]];
	NSString* result = [m_webView stringByEvaluatingJavaScriptFromString:js];	
	
	return [self convertScriptResult:result reference:m_objReference];
}

- (id)callFunction:(NSString *)functionName withArguments:(NSArray *)arguments
{
	NSString* strArgs = [arguments stringForJavaScript];	// "new Array(a,b,c)"
	strArgs = [strArgs substringWithRange:NSMakeRange(10, [strArgs length] - 11)];
	
	NSString* js = [NSString stringWithFormat:@"GAJavaScript.valueToString(%@.%@(%@))", 
					m_objReference, functionName, strArgs];
	NSString* result = [m_webView stringByEvaluatingJavaScriptFromString:js];	
	
	return [self convertScriptResult:result reference:m_objReference];	
}

#pragma mark GAScriptObject (NSKeyValueCoding)

/*
 * We use the bracket syntax because it supports a wider range of characters in the key names.
 */
- (id)valueForKey:(NSString *)key
{	
	key = [key stringForJavaScript];
	
	NSString* js = [NSString stringWithFormat:@"GAJavaScript.valueToString(%@[%@])", m_objReference, key];
	NSString* result = [m_webView stringByEvaluatingJavaScriptFromString:js];
	
	return [self convertScriptResult:result reference:key];	
}

- (void)setValue:(id)value forKey:(NSString *)key
{
	key = [key stringForJavaScript];

	if (value == nil)
		value = [[NSNull null] stringForJavaScript];		
	else 
		value = [value stringForJavaScript];
	
	NSString* js = [NSString stringWithFormat:@"%@[%@] = %@", m_objReference, key, value];
	[m_webView stringByEvaluatingJavaScriptFromString:js];
}

- (id)valueForKeyPath:(NSString *)keyPath
{
	NSString* js = [NSString stringWithFormat:@"GAJavaScript.valueToString(%@.%@)", m_objReference, keyPath];
	NSString* result = [m_webView stringByEvaluatingJavaScriptFromString:js];
	
	return [self convertScriptResult:result reference:keyPath];		
}

/*
 * Return a marker value for 'undefined'
 */
- (id)valueForUndefinedKey:(NSString *)key
{
	return @"undefined";
}

#pragma mark Private

- (id)convertScriptResult:(NSString *)result reference:(NSString *)reference
{
	// An empty result means a syntax error or JS exception was thrown.
	if ([result length] == 0)
		return [NSError errorWithDomain:GAJavaScriptErrorDomain code:101 userInfo:nil];
	
	unichar jstype = [result characterAtIndex:0];
	result = [result substringFromIndex:2];
	
	// Objects don't serialize to a string above.		
	if (jstype == 'o')
	{
		GAScriptObject* subObj = [[GAScriptObject alloc] initForReference:result view:m_webView];
		return [subObj autorelease];
	}
	else if (jstype == 'd')
	{
		NSNumber* timeVal = [kNumFormatter numberFromString:result];
		return [NSDate dateWithTimeIntervalSince1970:[timeVal doubleValue]];
	}
	else if (jstype == 'n')
	{
		return [kNumFormatter numberFromString:result];
	}
	else if (jstype == 'b')
	{
		return [NSNumber numberWithBool:[result isEqualToString:@"true"]];
	}
	else if (jstype == 'a')
	{		
		return [self arrayFromJavaScript:result reference:reference];
	}
	else if (jstype == 'x')
	{
		return [NSNull null];
	}
	
	return result;	
}

- (NSArray *)arrayFromJavaScript:(NSString *)result reference:(NSString *)reference
{
	NSArray* components = [result componentsSeparatedByString:@","];
	NSMutableArray* retVal = [NSMutableArray arrayWithCapacity:[components count]];
	
	for (NSString* jsvalue in components)
	{
		[retVal addObject:[self convertScriptResult:jsvalue reference:reference]];
	}
	
	return retVal;
}

#pragma mark NSFastEnumeration

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state 
								  objects:(id *)stackbuf 
									count:(NSUInteger)len
{
    NSUInteger count = 0;
	GAScriptObjectEnumState* enumState = (GAScriptObjectEnumState *)state;
	
    // This is the initialization condition, so we'll do one-time setup here.
    // Ensure that you never set state->state back to 0, or use another method to detect initialization
    // (such as using one of the values of state->extra).
    if(enumState->state == 0)
    {
        // We are not tracking mutations, so we'll set state->mutationsPtr to point into one of our extra values,
        // since these values are not otherwise used by the protocol.
        // If your class was mutable, you may choose to use an internal variable that is updated when the class is mutated.
        // state->mutationsPtr MUST NOT be NULL.
        enumState->mutationsPtr = &enumState->extra_0;
		enumState->propNames = [self allKeys];
    }
	
	NSUInteger propCount = [enumState->propNames count];
	
    // Now we provide items, which we track with state->state, and determine if we have finished iterating.
    if (enumState->state < propCount)
    {
        // Set state->itemsPtr to the provided buffer.
        // Alternate implementations may set state->itemsPtr to an internal C array of objects.
        // state->itemsPtr MUST NOT be NULL.
        enumState->itemsPtr = stackbuf;
		
        // Fill in the stack array, either until we've provided all items from the list
        // or until we've provided as many items as the stack based buffer will hold.
        while((enumState->state < propCount) && (count < len))
        {
            // For this sample, we generate the contents on the fly.
            // A real implementation would likely just be copying objects from internal storage.
            enumState->itemsPtr[count] = [enumState->propNames objectAtIndex:count];
            enumState->state++;
            count++;
        }
    }
    else
    {
        // We've already provided all our items, so we signal we are done by returning 0.
        count = 0;
    }
	
    return count;
}

@end