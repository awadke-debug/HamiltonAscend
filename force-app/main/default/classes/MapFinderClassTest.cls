@IsTest
public with sharing class MapFinderClassTest {

    @TestSetup
    static void makeData(){
        Campaign newCampaign = new Campaign(Name = 'Test Campaign');
        insert newCampaign;

        Account newAccount = new Account(Name = 'Test Account');
        insert newAccount;

        Contact c = new Contact(FirstName = 'Test', LastName = 'Contact', AccountId = newAccount.Id);
        insert c;
    }
    
    @IsTest
    static void testFinderInstances(){
        
        Map<String, String> augMap = (Map<String, String>) JSON.deserializeStrict('{"sportsAssociation":"a16VG000005T2a1YAC", "studentOrganization": "a16VG000005T2Q9YAK"}', Map<String, String>.class);
        MapFinderInterface mapFinderGeneric = new MapFinderGeneric();
        mapFinderGeneric.setFilterAugmentation(augMap);
        MapFinderInterface mapFinderItinerary = new MapFinderItinerary();
        mapFinderItinerary.setFilterAugmentation(augMap);

        mapFinderGeneric.augmentQueryFilter(new Map<String, Object>());
        mapFinderItinerary.augmentQueryFilter(new Map<String, Object>());
    
    }

    @IsTest
    static void testAddToCampaign(){
        Set<Id> contactIds = new Set<Id>();
        List<CampaignMember> campaignMembersToAdd = new List<CampaignMember>();

        MapFinderGeneric mapFinder = new MapFinderGeneric();
        mapFinder.addToCampaignMembersCollection(
            [SELECT Id FROM Campaign LIMIT 1].Id, 
            [SELECT Id FROM Contact LIMIT 1].Id, 
            contactIds, 
            campaignMembersToAdd
        );

        mapFinder.insertMembers(campaignMembersToAdd);
    }
}