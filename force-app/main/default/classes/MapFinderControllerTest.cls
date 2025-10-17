@IsTest
public with sharing class MapFinderControllerTest {

    @TestSetup
    static void makeData(){
        Campaign newCampaign = new Campaign(Name = 'Test Campaign');
        insert newCampaign;
    }
    
    @IsTest
    static void testGetConstituentAdvanceFilters(){
        
        Test.startTest();
        List<Object> results = MapFinderController.getConstituentAdvanceFilters();
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

        MapFinderController.getConstituentsByFilters(filterWrapper, 0, 10, 'Id', 'ASC');

    }

    @IsTest
    static void testGetDataTableProperties(){
        MapFinderController.getDataTableProperties();
    }

    @IsTest
    static void testGetMarkerProperties(){
        MapFinderController.getMarkerProperties();
    }

    @IsTest
    static void testGetAddressCoordinates(){
        Test.setMock(HttpCalloutMock.class, new GeocodingCalloutMock());
        Test.startTest();
            MapFinderController.GeolocationWrapper result = MapFinderController.getAddressCoordinates('1600 Pennsylvania Ave');
        Test.stopTest();

        System.assertEquals(37.4220094, result.lat);
        System.AssertEquals(-122.0847516, result.lng);
    }

    @IsTest
    static void testGetAllProperties(){
        
        MapFinderController.getAllProperties();
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
        
        MapFinderController.getContactsForExport(new List<String>{'ucinn_ascendv2__Contact__r.HAM_Rating_Number__c'}, filterWrapper, 'Id', 'ASC');
        
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
        
        MapFinderController.saveFilters(new List<AdvanceFilterParam>{ param });
    }

    @IsTest
    static void testLoadSavedFiltersByExternalId(){
        
        MapFinderController.loadSavedFilterByExternalId('test');
    }

    @IsTest
    static void testInvalidSavedFilters(){
        
        MapFinderController.invalidSavedFilters();
    }

    @IsTest
    static void testDeleteSavedFilters(){
        
        MapFinderController.deleteSavedFilters();
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
        MapFinderController.addCampaignMembers(filterWrapper, testCampaign.Id);
    }
}