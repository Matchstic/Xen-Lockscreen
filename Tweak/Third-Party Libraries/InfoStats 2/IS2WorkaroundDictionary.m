//
//  IS2WorkaroundDictionary.m
//  
//
//  Created by Matt Clarke on 28/12/2015.
//
//  This is O(n) overall, so is a bit crap. Seems WebCycript though throws a fit
//  when bloom filters are in use. Oh, and this method will give a nicely ordered
//  dictionary. Yay.

#import "IS2WorkaroundDictionary.h"

@implementation XENWorkaroundDictionary

+(id)dictionary {
    return [[XENWorkaroundDictionary alloc] init];
}

-(id)init {
    self = [super init];
    
    if (self) {
        _keys = [NSMutableArray array];
        _values = [NSMutableArray array];
    }
    
    return self;
}

-(void)setObject:(id)object forKey:(id)key {
    if ([_keys containsObject:key]) {
        // Hold on, why is that being added twice+?
        int index = (int)[_keys indexOfObject:key];
        [_keys removeObject:key];
        [_values removeObjectAtIndex:index];
    }
    
    [_keys addObject:key];
    [_values addObject:object];
    
}

-(void)removeObjectForKey:(id)key {
    int index = (int)[_keys indexOfObject:key];
    if (![_keys containsObject:key]) {
        // Do nothing.
    } else {
        [_keys removeObjectAtIndex:index];
        [_values removeObjectAtIndex:index];
    }
}

-(id)objectForKey:(id)key {
    int index = (int)[_keys indexOfObject:key];
    return [_values objectAtIndex:index];
}

-(id)allKeys {
    return _keys;
}

-(id)allValues {
    return _values;
}

-(void)dealloc {
    [_keys removeAllObjects];
    _keys = nil;
    
    [_values removeAllObjects];
    _values = nil;
}

@end
