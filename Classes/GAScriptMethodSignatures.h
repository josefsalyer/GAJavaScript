/*
 Copyright (c) 2011 Andrew Goodale. All rights reserved.
 
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

#import <Foundation/Foundation.h>


@interface GAScriptMethodSignatures : NSObject 
{
}

/**
 * Adds method signatures from the given class to the list of known signatures.
 */
+ (void)addMethodSignaturesForClass:(Class)clazz;

/**
 * Used by the script object to find a method signature for the given selector.
 */
+ (NSMethodSignature *)findMethodSignatureForSelector:(SEL)aSelector;

#pragma mark Common methods

- (NSUInteger)length;

- (id)item:(NSInteger)index;

#pragma mark DOM Methods

- (id)getElementById:(NSString *)elementId;

- (id)getElementsByTagName:(NSString *)tagName;

- (id)getElementsByClassName:(NSString *)className;

- (id)querySelector:(NSString *)selector;

- (id)querySelectorAll:(NSString *)selector;

#pragma mark View methods

- (id)getComputedStyle:(id)element;

@end
