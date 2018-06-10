//
//  IS2WorkaroundDictionary.h
//  
//
//  Created by Matt Clarke on 28/12/2015.
//
//

#import <Foundation/Foundation.h>

@interface XENWorkaroundDictionary : NSObject {
    NSMutableArray *_keys;
    NSMutableArray *_values;
}

+(id)dictionary;
-(void)setObject:(id)object forKey:(id)key;
-(void)removeObjectForKey:(id)key;
-(id)objectForKey:(id)key;
-(NSArray*)allKeys;
-(NSArray*)allValues;


@end
