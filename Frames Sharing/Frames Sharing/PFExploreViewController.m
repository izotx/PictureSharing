//
//  PFExploreViewController.m
//  Frames Sharing
//
//  Created by Terry Lewis II on 3/4/13.
//  Copyright (c) 2013 Blue Plover Productions. All rights reserved.
//

#import "PFExploreViewController.h"
#import "PFExploreCell.h"
#import "Photo.h"
#import "PFDisplayPhotoViewController.h"
#import "LoginRegisterViewController.h"
#import "PFProfileViewController.h"

@interface PFExploreViewController ()<UISearchBarDelegate>

@property (strong, nonatomic) IBOutlet UISearchBar *searchBar;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@end

@implementation PFExploreViewController
Manager * manager;
NSMutableArray * photoArray;
UIPopoverController * profilePopover;
#pragma mark iPad Methods



#pragma mark end of iPad

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    manager = [Manager sharedInstance];
    [manager.ff setAutoLoadBlobs:NO];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(searchCompletedWithResults:) name:photosRetrievedFromSearchNotification object:nil];
    if(!photoArray){
        photoArray = [[NSMutableArray alloc]initWithCapacity:0];
    }
    else{
        [photoArray removeAllObjects];
    }
    
    if(self.navigationController){
        manager.currentNavigationController = self.navigationController;
        
    }
    [manager getNewestPhotos];
    
}

-(void)viewWillDisappear:(BOOL)animated{
    [[NSNotificationCenter defaultCenter]removeObserver:self name:photosRetrievedFromSearchNotification object:nil];
}



-(void)viewDidAppear:(BOOL)animated{
    //[self configureView];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(searchCompletedWithResults:) name:photosRetrievedFromSearchNotification object:nil];

}

#warning it might be unused
-(void)configureView{
  
    if(manager.user){
        //configure view
        UIBarButtonItem *anotherButton = [[UIBarButtonItem alloc] initWithTitle:@"Profile" style:UIBarButtonItemStylePlain target:self action:@selector(showProfile)];
        self.navigationItem.rightBarButtonItem = anotherButton;
        
    }
    else{
        UIBarButtonItem *anotherButton = [[UIBarButtonItem alloc] initWithTitle:@"Login" style:UIBarButtonItemStylePlain target:self action:@selector(loginOrSignUp:)];
        self.navigationItem.rightBarButtonItem = anotherButton;
    }
}

- (IBAction)loginOrSignUp:(UIBarButtonItem *)sender {
    LoginRegisterViewController *pf = [self.storyboard instantiateViewControllerWithIdentifier:@"LoginPopover"];
    [self.navigationController pushViewController:pf animated:YES];
}


-(IBAction)showProfile{
    if(manager.user){
        PFProfileViewController * p;
        UIStoryboard * st;
        if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad){
            
            st = [UIStoryboard storyboardWithName:@"iPadStoryboard" bundle:nil];
            p =[st instantiateViewControllerWithIdentifier:@"PFProfileViewController"];
            p.user = manager.user;
            
            if(!profilePopover)
            {
                profilePopover = [[UIPopoverController alloc]initWithContentViewController:p];
            }
            if([profilePopover isPopoverVisible]){
                [profilePopover dismissPopoverAnimated:YES];
            }
            else{
                [profilePopover presentPopoverFromRect:self.view.frame inView:self.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
            }
            
            
        }
        else{
            st = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
            p =[st instantiateViewControllerWithIdentifier:@"PFProfileViewController"];
            p.user = manager.user;
            [self.navigationController pushViewController:p animated:YES];
            
        }
    }
    else
    {
        [manager displayActionSheetWithMessage:@"You need to be logged in to continue." forView:self.view navigationController:self.navigationController storyboard:self.storyboard andViewController:self];
    }
}













#pragma mark - UICollectionViewDelegate

-(void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath {
    //TODO deselect item
}

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    
    PFDisplayPhotoViewController * pdp;
    Photo * p = [photoArray objectAtIndex:indexPath.row];
   // if(manager.user == [manager getOwnerOfPhoto:p] )
    pdp= [self.storyboard instantiateViewControllerWithIdentifier:@"PFDisplayPhotoViewController"];
   
    pdp.photo = p;
    
    
    [self.navigationController pushViewController:pdp animated:YES];
 
    [pdp changeDescription:p.description];
    [pdp changeImage:[UIImage imageWithData:p.imageData]];
    [pdp changeRatings:p.ratings.count];
    
    NSLog(@" Cell Selected ");
    
}

#pragma mark – UICollectionViewDelegateFlowLayout
/*
-(CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    CGSize retVal = CGSizeMake(75, 75);
    return  retVal;
}
 
- (UIEdgeInsets)collectionView:
(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(10, 10, 10, 10);
}
*/
#pragma mark - UICollectionView Datasource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
 
    return [photoArray count];
}

-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)cv cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    PFExploreCell *cell = [cv dequeueReusableCellWithReuseIdentifier:@"ExploreCell" forIndexPath:indexPath];
    Photo * photo =       [photoArray objectAtIndex:indexPath.row];
    [self updateCell:cell withObject:photo andIndexPath:indexPath];

    return cell;
}


-(void)updateCell:(PFExploreCell *)cell withObject:(id)object andIndexPath:(NSIndexPath*)indexPath{
    
    NSLog(@"Update Cell");
    if([[(Photo *)object thumbnailImageData]length]>0 && [[(Photo *)object imageData]length]>0){
        NSLog(@"No need to update.");
         cell.imageView.image = [UIImage imageWithData:[(Photo *)object  thumbnailImageData]];
        
    }
    else{
        NSLog(@"Yes need to update it");
        [manager.ff loadBlobsForObj:(Photo *)object onComplete:^
         (NSError *theErr, id theObj, NSHTTPURLResponse *theResponse){
             if(theErr)
             {
                 NSLog(@" Error for blob  %@ ",[theErr debugDescription]);
             }
             
             Photo * photo = theObj;
             if(photoArray && photo!=nil){
                 if(indexPath.row<photoArray.count){
                     
                     [photoArray replaceObjectAtIndex:indexPath.row withObject:photo];
                     
                     cell.imageView.image = [UIImage imageWithData:photo.thumbnailImageData];
                     
                     NSLog(@"Cell Updated ");
                 }
             }
         }];
    }
   }

#pragma mark Search Bar

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar{
    [photoArray removeAllObjects];
    [self.collectionView reloadData];
    [manager getPhotosWithSearchQuery:searchBar.text];
    [self.searchBar resignFirstResponder];
    
    NSLog(@"Searching ");
    
}

-(void)searchCompletedWithResults:(NSNotification *)notification{
    NSArray * array = notification.object;
    photoArray = (NSMutableArray *) array;
    [self.collectionView reloadData];
    NSLog(@"Search completed with results");
}

- (void)searchBar:(UISearchBar *)searchBar selectedScopeButtonIndexDidChange:(NSInteger)selectedScope{
    [photoArray removeAllObjects];
    if(searchBar.selectedScopeButtonIndex == 0)
    {
       [manager getNewestPhotos];
    }
    else{
        [self searchBarSearchButtonClicked:searchBar];
    }    
}



-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if ([segue.identifier isEqualToString:@"menu"]) {
        [segue.destinationViewController performSelector:@selector(setCurrentNavigationController:)
                                              withObject:self.navigationController];
        NSLog(@"Segue menu");
    }
}




@end
