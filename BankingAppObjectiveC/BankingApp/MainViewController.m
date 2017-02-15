/*
 * Copyright (c) Microsoft. All rights reserved. Licensed under the MIT license.
 * See LICENSE in the project root for license information.
 */

#import "MainViewController.h"
#import "ChatViewController.h"
#import "VideoViewController.h"
#import "Util.h"


@interface MainViewController ()
@property (strong, nonatomic) IBOutlet UIButton *askAgentButton;
@end

@implementation MainViewController
SfBConversation* onPremConversation;
SfBApplication * onPremSfb;

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initializeSkype];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (IBAction)askAgent:(UIButton *)sender {
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Ask agent" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    [alertController addAction:[UIAlertAction actionWithTitle:@"Ask using Text Chat" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self askAgentText];
    }]];
    [alertController addAction:[UIAlertAction actionWithTitle:@"Ask using Video Chat" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self askAgentVideo];
    }]];
    [alertController addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
 UIPopoverPresentationController *popoverController =  alertController.popoverPresentationController;
    if(popoverController != nil){
        popoverController.sourceView = sender;
        popoverController.sourceRect = sender.bounds;
        
    }
    
    
    [self presentViewController:alertController animated:YES completion:nil];
    
    

}

- (void)askAgentVideo {
    
    SfBConfigurationManager *config = onPremSfb.configurationManager;
    NSString *key = @"AcceptedVideoLicense";
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
   
    if([defaults boolForKey:key]){
        [config setEndUserAcceptedVideoLicense];
        if([self didJoinMeeting]){
            [self performSegueWithIdentifier:@"askAgentVideo" sender:nil];
        }
    }else{
        MicrosoftLicenseViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"MicrosoftLicenseViewController"];
        vc.delegate = self;
        [self presentViewController:vc animated:YES completion:nil];
    }
}

- (void)askAgentText {
     if([self didJoinMeeting]){
    [self performSegueWithIdentifier:@"askAgentText" sender:nil];
     }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:YES];
}

- (void)didReceiveAlert:(SfBAlert *)alert{
    [alert showSfBAlertInController:self];
}


/**
 *  Initialize Skype
 */
- (void)initializeSkype {
    onPremSfb = SfBApplication.sharedApplication;
    onPremSfb.configurationManager.maxVideoChannels = 1;
    onPremSfb.configurationManager.requireWifiForAudio = false;
    onPremSfb.configurationManager.requireWifiForVideo = false;
    onPremSfb.devicesManager.selectedSpeaker.activeEndpoint = SfBSpeakerEndpointLoudspeaker;
    onPremSfb.configurationManager.enablePreviewFeatures = [Util getEnablePreviewSwitchState];
    onPremSfb.alertDelegate = self;
}

-(bool)didJoinMeeting{
    
    NSError *error = nil;
    NSString *meetingURLString =  [Util getMeetingURLString];
    NSString *meetingDisplayName = [Util getMeetingDisplayName];
  
        onPremConversation = [onPremSfb joinMeetingAnonymousWithUri:[NSURL URLWithString:meetingURLString]
                                                             displayName:meetingDisplayName
                                                                   error:&error].conversation;
    
        if (onPremConversation) {
            return true;
        } else {
            [Util showErrorAlert:error inView:self ];
        }
    return false;
}

#pragma mark -Segue navigation functions
-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if([segue.identifier isEqualToString:@"askAgentText"]){
        ChatViewController* destination = segue.destinationViewController;
        destination.conversation = onPremConversation;
        
       
    }
    else if([segue.identifier isEqualToString:@"askAgentVideo"]){
        VideoViewController* destination = segue.destinationViewController;
        destination.deviceManagerInstance = onPremSfb.devicesManager;
        destination.conversationInstance = onPremConversation;
        destination.displayName = [Util getMeetingDisplayName];
       
    }
     onPremConversation = nil;
}

#pragma mark - MicrosoftLicenseViewController delegate function
- (void)controller:(MicrosoftLicenseViewController* )controller
  didAcceptLicense:(BOOL)acceptedLicense{
    if(acceptedLicense){
        SfBConfigurationManager *config = onPremSfb.configurationManager;
        [config setEndUserAcceptedVideoLicense];
        if([self didJoinMeeting]){
            [self performSegueWithIdentifier:@"askAgentVideo" sender:nil];
        }
    }
}

@end
