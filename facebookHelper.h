//
// Created by sdikarev on 4/11/13.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <Foundation/Foundation.h>

typedef void (^RCCompleteBlockWithResult)  (BOOL result, NSError *error);

@interface facebookHelper : NSObject




@property (nonatomic, strong) NSMutableArray *checkins;
@property (nonatomic, strong) NSMutableArray *userCheckins;
@property (nonatomic, strong) NSMutableArray *places;
@property (nonatomic, strong) NSMutableArray *userPlaces;
@property (nonatomic, strong) NSMutableDictionary *resultUserCheckins;
@property (nonatomic, strong) NSMutableDictionary *resultFriendsCheckins;
@property (nonatomic, strong)  NSArray* friends;






+(id)sharedInstance;
-(void)getFacebookQuery:(RCCompleteBlockWithResult)completionBlock;
@end