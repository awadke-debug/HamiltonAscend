@IsTest
public with sharing class MapFinderControllerTest {

    @TestSetup
    static void makeData(){
        Campaign newCampaign = new Campaign(Name = 'Test Campaign');
        insert newCampaign;

        Account newAccount = new Account(Name = 'Test Account');
        insert newAccount;

        Contact c = new Contact(FirstName = 'Test', LastName = 'Contact', AccountId = newAccount.Id);
        insert c;

        // System.assert(c.Id != null);

        // ucinn_ascendv2__Address__c newAddress = new ucinn_ascendv2__Address__c();
        // insert newAddress;

        // Id recordTypeId = Schema.SObjectType.ucinn_ascendv2__Address_Relation__c.getRecordTypeInfosByDeveloperName().get('Contact_Address_Relation').getRecordTypeId();

        // ucinn_ascendv2__Address_Relation__c newAR = new ucinn_ascendv2__Address_Relation__c(ucinn_ascendv2__Contact__c = c.Id, ucinn_ascendv2__Account__c = newAccount.Id, ucinn_ascendv2__Address__c = newAddress.Id, ucinn_ascendv2__Status__c = 'Current', ucinn_ascendv2__Type__c = 'Business', RecordTypeId = recordTypeId);
        // insert newAr;
    }
    
    @IsTest
    static void testGetConstituentAdvanceFilters(){
        
        Test.startTest();
        List<Object> results = MapFinderController.getConstituentAdvanceFilters('Map_Finder_App');
        Test.stopTest();

        for (Object result : results) {
            Map<String,Object> resultMap = (Map<String,Object>) JSON.deserializeUntyped(JSON.serialize(result));
            System.debug(resultMap.get('label'));
        }

        System.debug(results.size());
        System.Assert.isTrue(results.size() > 0);
    }

    @IsTest
    static void testGetConstituentsByFilters(){
        AdvanceFilterParamWrapper filterWrapper = new AdvanceFilterParamWrapper();
        filterWrapper.latitude = 28.5374094;
        filterWrapper.longitude = -81.1747498;
        filterWrapper.radius = 50;

        AdvanceFilterParam param = new AdvanceFilterParam();
        param.fieldName = 'HAM_Rating_Number__c';
        param.operator = '=';
        param.fieldType = 'INTEGER';
        param.fieldValue = '15';
        param.lookupFieldApiName = 'ucinn_ascendv2__Contact__r';

        filterWrapper.advanceFilterParams = new List<AdvanceFilterParam>{ param };

        MapFinderController.getConstituentsByFilters('Map_Finder_App', filterWrapper, 0, 10, 'Id', 'ASC');

    }

    @IsTest
    static void testGetDataTableProperties(){
        MapFinderController.getDataTableProperties('Map_Finder_App');
    }

    @IsTest
    static void testGetMarkerProperties(){
        MapFinderController.getMarkerProperties('Map_Finder_App');
    }

    @IsTest
    static void testGetAddressCoordinates(){
        Test.setMock(HttpCalloutMock.class, new GeocodingCalloutMock());
        Test.startTest();
            MapFinderController.GeolocationWrapper result = MapFinderController.getAddressCoordinates('1600 Pennsylvania Ave');
        Test.stopTest();

        System.assertEquals('37.4220094', result.Latitude);
        System.AssertEquals('-122.0847516', result.Longitude);
    }

    @IsTest
    static void testGetAllProperties(){
        
        MapFinderController.getAllProperties('Map_Finder_App');
    }

    @IsTest
    static void testGetContactsForExport(){
        AdvanceFilterParamWrapper filterWrapper = new AdvanceFilterParamWrapper();
        filterWrapper.latitude = 28.5374094;
        filterWrapper.longitude = -81.1747498;
        filterWrapper.radius = 50;

        AdvanceFilterParam param = new AdvanceFilterParam();
        param.fieldName = 'HAM_Rating_Number__c';
        param.operator = '=';
        param.fieldType = 'INTEGER';
        param.fieldValue = '15';
        param.lookupFieldApiName = 'ucinn_ascendv2__Contact__r';
        param.isRange = false;

        filterWrapper.advanceFilterParams = new List<AdvanceFilterParam>{ param };
        
        MapFinderController.getContactsForExport('Map_Finder_App', new List<String>{'ucinn_ascendv2__Contact__r.HAM_Rating_Number__c'}, filterWrapper, 'Id', 'ASC');
        
    }

    @IsTest
    static void testSaveFilters(){

        AdvanceFilterParam param = new AdvanceFilterParam();
        param.fieldName = 'HAM_Rating_Number__c';
        param.operator = '=';
        param.fieldType = 'DOUBLE';
        param.fieldValue = '15';
        param.lookupFieldApiName = 'ucinn_ascendv2__Contact__r';
        param.isRange = false;
        
        MapFinderController.saveFilters('Map_Finder_App', new List<AdvanceFilterParam>{ param });
    }

    @IsTest
    static void testLoadSavedFiltersByExternalId(){
        
        MapFinderController.loadSavedFilterByExternalId('Map_Finder_App', 'test');
    }

    @IsTest
    static void testInvalidSavedFilters(){
        
        MapFinderController.invalidSavedFilters('Map_Finder_App');
    }

    @IsTest
    static void testDeleteSavedFilters(){
        
        MapFinderController.deleteSavedFilters('Map_Finder_App');
    }

    @IsTest
    static void testIsMarketingUser(){
        
        MapFinderController.isMarketingUser();
        
    }

    @IsTest
    static void testAddCampaignMembers(){
        AdvanceFilterParamWrapper filterWrapper = new AdvanceFilterParamWrapper();
        filterWrapper.latitude = 28.5374094;
        filterWrapper.longitude = -81.1747498;
        filterWrapper.radius = 50;

        AdvanceFilterParam param = new AdvanceFilterParam();
        param.fieldName = 'HAM_Rating_Number__c';
        param.operator = '=';
        param.fieldType = 'INTEGER';
        param.fieldValue = '15';
        param.lookupFieldApiName = 'ucinn_ascendv2__Contact__r';

        filterWrapper.advanceFilterParams = new List<AdvanceFilterParam>{ param };

        Campaign testCampaign = [SELECT Id FROM Campaign WHERE Name = 'Test Campaign' LIMIT 1];
        MapFinderController.addCampaignMembers('Map_Finder_App', filterWrapper, testCampaign.Id);
    }

    @IsTest
    static void testGetMarkerDescriptionProperties(){
        MapFinderController.getMarkerDescriptionProperties('Map_Finder_App');
    }

    @IsTest
    static void testIsCampaignMemberFieldValid(){
        MapFinderController.isCampaignMemberFieldValid('Map_Finder_App');
    }

    @IsTest
    static void testIsValidContactField(){
        MapFinderController.isValidContactField([SELECT Id FROM Contact LIMIT 1].Id);
    }

    @IsTest
    static void testParse() {
		String json=		'{"results":[{"address_components":[{"long_name":"1600","short_name":"1600","types":["street_number"]},{"long_name":"Amphitheatre Parkway","short_name":"Amphitheatre Pkwy","types":["route"]},{"long_name":"Mountain View","short_name":"Mountain View","types":["locality","political"]},{"long_name":"Santa Clara County","short_name":"Santa Clara County","types":["administrative_area_level_2","political"]},{"long_name":"California","short_name":"CA","types":["administrative_area_level_1","political"]},{"long_name":"United States","short_name":"US","types":["country","political"]},{"long_name":"94043","short_name":"94043","types":["postal_code"]},{"long_name":"1351","short_name":"1351","types":["postal_code_suffix"]}],"formatted_address":"1600 Amphitheatre Pkwy, Mountain View, CA 94043, USA","geometry":{"location":{"lat":37.4220094,"lng":-122.0847516},"location_type":"ROOFTOP","viewport":{"northeast":{"lat":37.4233580302915,"lng":-122.0827769697085},"southwest":{"lat":37.4206600697085,"lng":-122.0854749302915}}},"navigation_points":[{"location":{"latitude":37.4209982,"longitude":-122.082964}},{"location":{"latitude":37.4211397,"longitude":-122.0852956}},{"location":{"latitude":37.4229215,"longitude":-122.0834223}},{"location":{"latitude":37.4230178,"longitude":-122.0850192}}],"place_id":"ChIJ09H2YwK6j4ARoF7qfCBxhB8","plus_code":{"compound_code":"CWC8+R3 Mountain View, CA","global_code":"849VCWC8+R3"},"types":["street_address"]}],"status":"OK"}';
		GeocodeResponse obj = GeocodeResponse.parse(json);
		System.assert(obj != null);
	}
}