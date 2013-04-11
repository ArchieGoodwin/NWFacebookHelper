NWFacebookHelper
================

Facebook Helper (iOS) for retrieving user friends, checkins, friends checkins


Using:

After authenticating to Facebook just call 

[[facebookHelper sharedInstance] getFacebookQuery:^(BOOL result, NSError *error) {
  /*results are in 
  @property (nonatomic, strong) NSMutableArray *checkins;
  @property (nonatomic, strong) NSMutableArray *userCheckins;
  @property (nonatomic, strong) NSMutableArray *places;
  @property (nonatomic, strong) NSMutableArray *userPlaces;
  @property (nonatomic, strong) NSMutableDictionary *resultUserCheckins;
  @property (nonatomic, strong) NSMutableDictionary *resultFriendsCheckins;
  @property (nonatomic, strong)  NSArray* friends;
  */

}];
