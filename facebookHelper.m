//
// Created by sdikarev on 4/11/13.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "facebookHelper.h"
#import <FacebookSDK/FacebookSDK.h>


@implementation facebookHelper {
    int iterations;
    int maxIterations;
}

-(void)recursiveQuery:(int)offset completionBlock:(RCCompleteBlockWithResult)completionBlock
{
    NSString *query = [NSString stringWithFormat:
            @"{"
                    @"'query1':'SELECT uid2 FROM friend WHERE uid1 = me() LIMIT 300 OFFSET %i',"
                    @"'query2':'SELECT coords, author_uid, page_id FROM checkin WHERE author_uid IN (SELECT uid2 FROM #query1)',"
                    @"'query3':'SELECT page_id, name FROM place WHERE page_id IN (SELECT page_id FROM #query2)',"
                    @"}", offset];


    //NSString *query = [NSString stringWithFormat:@"SELECT coords, author_uid, page_id FROM checkin WHERE author_uid IN (SELECT uid2 FROM friend WHERE uid1 = me()) LIMIT 300 OFFSET %i", offset];

    // Set up the query parameter
    NSDictionary *queryParam =
            [NSDictionary dictionaryWithObjectsAndKeys:query, @"q", nil];
    // Make the API request that uses FQL

    FBRequest *postRequest = [FBRequest requestWithGraphPath:@"/fql" parameters:queryParam HTTPMethod:@"GET"];
    postRequest.session = FBSession.activeSession;

    [postRequest startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        if(!error)
        {
            NSLog(@"step recursiveQuery %i", iterations);
            iterations++;
            //NSLog(@"getFacebookQuery > 300: %@", [result objectForKey:@"data"]);
            [self buildArrays:[result objectForKey:@"data"]];

            if(iterations <= maxIterations)
            {
                [self recursiveQuery:iterations * 300 completionBlock:completionBlock];

            }
            else
            {
                [self buildResult];
                NSLog(@"end query %@", [NSDate date]);

                if(completionBlock)
                {
                    completionBlock(YES, nil);
                }
            }
        }
        else
        {
            NSLog(@"error: %@", [error description]);
            if(completionBlock)
            {
                completionBlock(NO, error);
            }
        }
    }];
}

-(void)getFacebookQuery:(RCCompleteBlockWithResult)completionBlock
{

    RCCompleteBlockWithResult completeBlockWithResult = completionBlock;

    iterations = 0;
    maxIterations = 3;
    NSLog(@"start query %@", [NSDate date]);


    FBRequest* friendsRequest = [FBRequest requestForMyFriends];
    friendsRequest.session = FBSession.activeSession;

    [friendsRequest startWithCompletionHandler: ^(FBRequestConnection *connection,
            NSDictionary* result,
            NSError *error) {
        _friends = [result objectForKey:@"data"];
        NSLog(@"Found: %i friends", _friends.count);
        //NSLog(@"friends: %@", result);
        maxIterations = _friends.count / 300;

        [self getFacebookUserCheckins:^(BOOL res, NSError *error) {
            if(res)
            {
                if(_friends.count > 300)
                {
                    [self recursiveQuery:iterations * 300 completionBlock:completeBlockWithResult];
                }
                else
                {
                    NSString *query =
                            @"{"
                                    @"'query1':'SELECT uid2 FROM friend WHERE uid1 = me()',"
                                    @"'query2':'SELECT coords, author_uid, page_id FROM checkin WHERE author_uid IN (SELECT uid2 FROM #query1)',"
                                    @"'query3':'SELECT page_id, name FROM place WHERE page_id IN (SELECT page_id FROM #query2)',"
                                    @"}";

                    // Set up the query parameter
                    NSDictionary *queryParam =
                            [NSDictionary dictionaryWithObjectsAndKeys:query, @"q", nil];
                    // Make the API request that uses FQL

                    FBRequest *postRequest = [FBRequest requestWithGraphPath:@"/fql" parameters:queryParam HTTPMethod:@"GET"];
                    postRequest.session = FBSession.activeSession;

                    [postRequest startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                        if(!error)
                        {
                            //NSLog(@"getFacebookQuery < 300 : %@", [result objectForKey:@"data"]);
                            NSLog(@"end query %@", [NSDate date]);
                            [self buildArrays:[result objectForKey:@"data"]];
                            [self buildResult];

                            if(completeBlockWithResult)
                            {
                                completeBlockWithResult(YES, nil);
                            }

                        }
                        else
                        {
                            NSLog(@"error: %@", [error description]);
                            if(completeBlockWithResult)
                            {
                                completeBlockWithResult(NO, error);
                            }
                        }
                    }];
                }
            }
        }];

    }];

}


-(void)buildArrays:(NSDictionary *)dict
{


    for(NSDictionary *sub in dict)
    {
        if([[sub objectForKey:@"name"] isEqualToString:@"query2"])
        {
            [_checkins addObjectsFromArray:[sub objectForKey:@"fql_result_set"]];
        }
        if([[sub objectForKey:@"name"] isEqualToString:@"query3"])
        {
            [_places addObjectsFromArray:[sub objectForKey:@"fql_result_set"]];
        }
    }

    NSLog(@"result arrays :%i   %i", _checkins.count, _places.count);


}

-(void)buildArraysForUser:(NSDictionary *)dict
{


    for(NSDictionary *sub in dict)
    {
        if([[sub objectForKey:@"name"] isEqualToString:@"query1"])
        {
            [_userCheckins addObjectsFromArray:[sub objectForKey:@"fql_result_set"]];
        }
        if([[sub objectForKey:@"name"] isEqualToString:@"query2"])
        {
            [_userPlaces addObjectsFromArray:[sub objectForKey:@"fql_result_set"]];
        }
    }

    NSLog(@"result user arrays :%i   %i", _userCheckins.count, _userPlaces.count);


}


-(NSString *)getPlaceNameFromPlaceId:(id)placeId
{
    for(NSDictionary *place in _places)
    {
        if([[place objectForKey:@"page_id"] isEqual:placeId])
        {
            return [place objectForKey:@"name"];
        }
    }
}

-(NSString *)getPlaceNameFromPlaceIdForUser:(id)placeId
{
    for(NSDictionary *place in _userPlaces)
    {
        if([[place objectForKey:@"page_id"] isEqual:placeId])
        {
            return [place objectForKey:@"name"];
        }
    }
}

-(void)buildResult
{
    for(NSMutableDictionary *checkin in _checkins)
    {
        //NSLog(@"%@", checkin);
        NSString *placeName = [self getPlaceNameFromPlaceId:[checkin objectForKey:@"page_id"]];
        //NSLog(@"%@", placeName);
        [checkin setObject:placeName forKey:@"name"];

    }

    NSLog(@"result for send:  %@", [NSMutableDictionary dictionaryWithObject:_checkins forKey:@"fb_userCheckin"]);
    _resultFriendsCheckins = [NSMutableDictionary dictionaryWithObject:_checkins forKey:@"fb_userCheckin"];
}

-(void)buildResultForUser
{
    for(NSMutableDictionary *checkin in _userCheckins)
    {
        //NSLog(@"%@", checkin);
        NSString *placeName = [self getPlaceNameFromPlaceIdForUser:[checkin objectForKey:@"page_id"]];
        //NSLog(@"%@", placeName);
        [checkin setObject:placeName forKey:@"name"];

    }

    NSLog(@"result for user send:  %@", [NSMutableDictionary dictionaryWithObject:_userCheckins
                                                                           forKey:@"fb_userCheckin"]);
    _resultUserCheckins = [NSMutableDictionary dictionaryWithObject:_userCheckins
                                                            forKey:@"fb_userCheckin"];
}


-(void)getFacebookUserCheckins:(RCCompleteBlockWithResult)completionBlock
{

    RCCompleteBlockWithResult completeBlockWithResult = completionBlock;

    NSString *query = [NSString stringWithFormat:
            @"{"
                    @"'query1':'SELECT coords, author_uid, page_id FROM checkin WHERE author_uid = me()',"
                    @"'query2':'SELECT page_id, name FROM place WHERE page_id IN (SELECT page_id FROM #query1)',"
                    @"}"];

    // Set up the query parameter
    NSDictionary *queryParam =
            [NSDictionary dictionaryWithObjectsAndKeys:query, @"q", nil];
    // Make the API request that uses FQL
    FBRequest *postRequest = [FBRequest requestWithGraphPath:@"/fql" parameters:queryParam HTTPMethod:@"GET"];
    postRequest.session = FBSession.activeSession;
    [postRequest startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        if(!error)
        {

            [self buildArraysForUser:[result objectForKey:@"data"]];
            [self buildResultForUser];
            if(completeBlockWithResult)
            {
                completeBlockWithResult(YES, nil);
            }

        }
        else
        {

            NSLog(@"error: %@", [error description]);
            if(completeBlockWithResult)
            {
                completeBlockWithResult(NO, error);
            }
        }
    }];
}

-(void)getFacebookRecentCheckins {

    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
            @"checkin",@"type",nil];

    FBRequest *postRequest = [FBRequest requestWithGraphPath:@"search" parameters:params HTTPMethod:@"GET"];
    postRequest.session = FBSession.activeSession;

    [postRequest startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        if(!error)
        {
            NSLog(@"getFacebookRecentCheckins: %@", [result objectForKey:@"data"]);

        }
        else
        {
            NSLog(@"error: %@", [error localizedDescription]);
        }
    }];

}

-(void)getFacebookFriends
{

    FBRequest* friendsRequest = [FBRequest requestForMyFriends];
    friendsRequest.session = FBSession.activeSession;

    [friendsRequest startWithCompletionHandler: ^(FBRequestConnection *connection,
            NSDictionary* result,
            NSError *error) {
        NSArray* friends = [result objectForKey:@"data"];
        NSLog(@"Found: %i friends", friends.count);
        NSLog(@"friends: %@", result);
        for (NSDictionary<FBGraphUser>* friend in friends) {
            NSLog(@"I have a friend named %@ with id %@", friend.name, friend.id);
        }
    }];
}










- (id)init {
    self = [super init];


    _checkins = [NSMutableArray new];
    _places = [NSMutableArray new];
    _userCheckins = [NSMutableArray new];
    _userPlaces = [NSMutableArray new];
    _friends = [NSArray new];

#if !(TARGET_IPHONE_SIMULATOR)


#else


#endif

    return self;

}



+(id)sharedInstance
{
    static dispatch_once_t pred;
    static facebookHelper *sharedInstance = nil;
    dispatch_once(&pred, ^{
        sharedInstance = [[facebookHelper alloc] init];
    });
    return sharedInstance;
}

- (void)dealloc
{

    abort();
}


@end