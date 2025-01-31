//
//  tripfy_WellcomeViewController.m
//  tripfy
//
//  Created by BM Eser Kalac on 27/02/15.
//  Copyright (c) 2015 tripfy. All rights reserved.
//

#import "tripfy_WellcomeViewController.h"
#import <Parse/Parse.h>
#import <ParseFacebookUtils/PFFacebookUtils.h>
#import "AppDelegate.h"
#import "SevenSwitch.h"


@interface tripfy_WellcomeViewController (){
    AppDelegate *tripfy;
}

@end

@implementation tripfy_WellcomeViewController
@synthesize view_switch,btn_plan,lbl_info;
- (void)viewDidLoad {
    [super viewDidLoad];
    tripfy = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    // Do any additional setup after loading the view.
    [self _loadData];
    SevenSwitch *selectSwitch = [[SevenSwitch alloc] initWithFrame:CGRectMake(0, 4, 70, 35)];
    selectSwitch.center = CGPointMake(30, 22);
    [selectSwitch addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
    selectSwitch.onImage = [UIImage imageNamed:@"passenger.png"];
    selectSwitch.offImage = [UIImage imageNamed:@"taxi.png"];
    selectSwitch.onColor = [UIColor clearColor];
    [selectSwitch setOn:YES];
                            
    selectSwitch.isRounded = NO;
    [self.view_switch addSubview:selectSwitch];
    
    
    btn_plan.layer.cornerRadius = 3;

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (void)switchChanged:(SevenSwitch *)sender {
    NSLog(@"Changed value to: %@", sender.on ? @"ON" : @"OFF");
    [self.view layoutIfNeeded];
    [UIView animateWithDuration:0.3
                     animations:^{
                         if (sender.on) {
                             tripfy.root.isPassenger = YES;
                             self.view.backgroundColor = UIColorFromRGB(0x2D9AE0);
                             btn_plan.backgroundColor = UIColorFromRGB(0x2D9AE0);
                             [btn_plan setTitle:@"Search a Trip" forState:UIControlStateNormal];
                             lbl_info.text = @"You have not get trip any yet. Why dont you search one?";
                         }else{
                             tripfy.root.isPassenger = NO;
                             self.view.backgroundColor = UIColorFromRGB(0xFCC208);
                             btn_plan.backgroundColor = UIColorFromRGB(0xFCC208);
                             [btn_plan setTitle:@"Plan a Trip" forState:UIControlStateNormal];
                             lbl_info.text = @"You have not set trip any yet. Why dont you create one?";
                         }
                         
                         [self.view layoutIfNeeded]; // Called on parent view
                     }];
    
}

- (void)_loadData {
    // If the user is already logged in, display any previously cached values before we get the latest from Facebook.
    if ([PFUser currentUser]) {
        [self _updateProfileData];
    }
    
    // Send request to Facebook
    FBRequest *request = [FBRequest requestForMe];
    [request startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        // handle response
        if (!error) {
            // Parse the data received
            NSDictionary *userData = (NSDictionary *)result;
            
            NSString *facebookID = userData[@"id"];
            
            
            NSMutableDictionary *userProfile = [NSMutableDictionary dictionaryWithCapacity:7];
            
            if (facebookID) {
                userProfile[@"facebookId"] = facebookID;
            }
            
            NSString *name = userData[@"name"];
            if (name) {
                userProfile[@"name"] = name;
            }
            
            NSString *location = userData[@"location"][@"name"];
            if (location) {
                userProfile[@"location"] = location;
            }
            
            NSString *gender = userData[@"gender"];
            if (gender) {
                userProfile[@"gender"] = gender;
            }
            
            NSString *birthday = userData[@"birthday"];
            if (birthday) {
                userProfile[@"birthday"] = birthday;
            }
            
            NSString *relationshipStatus = userData[@"relationship_status"];
            if (relationshipStatus) {
                userProfile[@"relationship"] = relationshipStatus;
            }
            
            userProfile[@"pictureURL"] = [NSString stringWithFormat:@"https://graph.facebook.com/%@/picture?type=large&return_ssl_resources=1", facebookID];
            
            [[PFUser currentUser] setObject:userProfile forKey:@"profile"];
            [[PFUser currentUser] saveInBackground];
            
            [self _updateProfileData];
        } else if ([[[[error userInfo] objectForKey:@"error"] objectForKey:@"type"]
                    isEqualToString: @"OAuthException"]) { // Since the request failed, we can check if it was due to an invalid session
            NSLog(@"The facebook session was invalidated");
            [self logoutButtonAction:nil];
        } else {
            NSLog(@"Some other error: %@", error);
        }
    }];
}

// Set received values if they are not nil and reload the table
- (void)_updateProfileData {
    NSString *location = [PFUser currentUser][@"profile"][@"location"];
    if (location) {
        self.rowDataArray[0] = location;
    }
    
    NSString *gender = [PFUser currentUser][@"profile"][@"gender"];
    if (gender) {
        self.rowDataArray[1] = gender;
    }
    
    NSString *birthday = [PFUser currentUser][@"profile"][@"birthday"];
    if (birthday) {
        self.rowDataArray[2] = birthday;
    }
    
    NSString *relationshipStatus = [PFUser currentUser][@"profile"][@"relationship"];
    if (relationshipStatus) {
        self.rowDataArray[3] = relationshipStatus;
    }
    
    
    // Set the name in the header view label
    NSString *name = [PFUser currentUser][@"profile"][@"name"];
    if (name) {
        
        self.headerNameLabel.text = [NSString stringWithFormat:@"Hello %@. Wellcome to Tripfy!",name];
    }
    
    NSString *userProfilePhotoURLString = [PFUser currentUser][@"profile"][@"pictureURL"];
    // Download the user's facebook profile picture
    if (userProfilePhotoURLString) {
        NSURL *pictureURL = [NSURL URLWithString:userProfilePhotoURLString];
        NSURLRequest *urlRequest = [NSURLRequest requestWithURL:pictureURL];
        
        [NSURLConnection sendAsynchronousRequest:urlRequest
                                           queue:[NSOperationQueue mainQueue]
                               completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                                   if (connectionError == nil && data != nil) {
                                       
                                       self.headerImageView.image = [[tripfy utils] maskImage:[UIImage imageWithData:data] withMask:[UIImage imageNamed:@"mask.png"]];
                                       
                                       // Add a nice corner radius to the image
                                       self.headerImageView.layer.cornerRadius = 8.0f;
                                       self.headerImageView.layer.masksToBounds = YES;
                                   } else {
                                       NSLog(@"Failed to load profile photo.");
                                   }
                               }];
    }
}

- (void)logoutButtonAction:(id)sender {
    // Logout user, this automatically clears the cache
    [PFUser logOut];
    
    // Return to login view controller
    [self.navigationController popToRootViewControllerAnimated:YES];
}

- (IBAction)enter:(id)sender {
    tripfy.index = 2;
    [tripfy.root main];
    
}

- (IBAction)logOut:(id)sender {
    [PFUser logOut];
    [tripfy.root login];
    
    // Return to login view controller
}

- (IBAction)plan:(id)sender {
    tripfy.index = 2;
    [tripfy.root main];
    if (tripfy.root.isPassenger) {
        if (SYSTEM_VERSION_LESS_THAN(@"8.0")) {
            
        }else{
            
        }
    }else{
        if (SYSTEM_VERSION_LESS_THAN(@"8.0")) {
            
        }else{
           
        }
    }
}

- (IBAction)quickTrip:(id)sender {
}
@end
