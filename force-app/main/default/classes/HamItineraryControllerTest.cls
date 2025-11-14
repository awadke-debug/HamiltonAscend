@IsTest
public with sharing class HamItineraryControllerTest {
    @TestSetup
    static void makeData(){
        Contact contact = new Contact();
        contact.LastName = 'Test';
        insert contact;

        HAM_Trip_Details__c tripDetail = new HAM_Trip_Details__c();
        tripDetail.HAM_Title__c = 'Test Trip';
        tripDetail.HAM_Start_Date_Time__c = Datetime.now();
        tripDetail.HAM_End_Date_Time__c = Datetime.now().addDays(1);
        insert tripDetail;

        Event meetingEvt = new Event();
        meetingEvt.OwnerId = UserInfo.getUserId();
        meetingEvt.WhatId = tripDetail.Id;
        meetingEvt.RecordTypeId = Schema.SObjectType.Event.getRecordTypeInfosByDeveloperName().get('HAM_Meeting').getRecordTypeId();
        meetingEvt.HAM_Trip_Details__c = tripDetail.Id;
        meetingEvt.Subject = 'Test Event';
        meetingEvt.DurationInMinutes = 30;
        meetingEvt.ActivityDateTime = Datetime.now();
        meetingEvt.Description = 'Test Description';
        insert meetingEvt;

        Event accommodationEvt = new Event();
        accommodationEvt.OwnerId = UserInfo.getUserId();
        accommodationEvt.WhatId = tripDetail.Id;
        accommodationEvt.RecordTypeId = Schema.SObjectType.Event.getRecordTypeInfosByDeveloperName().get('HAM_Accommodation').getRecordTypeId();
        accommodationEvt.HAM_Trip_Details__c = tripDetail.Id;
        accommodationEvt.Subject = 'Test Event';
        accommodationEvt.DurationInMinutes = 30;
        accommodationEvt.ActivityDateTime = Datetime.now();
        accommodationEvt.Description = 'Test Description';
        insert accommodationEvt;

        Event travelEvt = new Event();
        travelEvt.OwnerId = UserInfo.getUserId();
        travelEvt.WhatId = tripDetail.Id;
        travelEvt.RecordTypeId = Schema.SObjectType.Event.getRecordTypeInfosByDeveloperName().get('HAM_Transportation').getRecordTypeId();
        travelEvt.HAM_Trip_Details__c = tripDetail.Id;
        travelEvt.Subject = 'Test Event';
        travelEvt.DurationInMinutes = 30;
        travelEvt.ActivityDateTime = Datetime.now();
        travelEvt.Description = 'Test Description';
        insert travelEvt;

        ucinn_ascendv2__Contact_Report__c contactReport = new ucinn_ascendv2__Contact_Report__c();
        contactReport.Trip_Details__c = tripDetail.Id;
        contactReport.ucinn_ascendv2__Contact__c = contact.Id;
        insert contactReport;

        HAM_Email_Filter_Setting__c emailFilterSetting = new HAM_Email_Filter_Setting__c();
        emailFilterSetting.HAM_Email_Domain__c = '@hamilton.edu';
        emailFilterSetting.Restrict_to_Hamilton_Email__c = true;
        insert emailFilterSetting;
    }

    @IsTest
    static void methodName(){
        Id tripDetailId = [SELECT Id FROM HAM_Trip_Details__c LIMIT 1].Id;

        PageReference pageRef = Page.hamItineraryPdf;
        pageRef.getParameters().put('tripDetailId', tripDetailId);
        Test.setCurrentPage(pageRef);
        HamItineraryController iterController = new HamItineraryController();

        HamItineraryController.getBaseUrl();
        HamItineraryController.getStays(tripDetailId);
        HamItineraryController.getEvents(tripDetailId);
        HamItineraryController.getEventsByUser();

        HamItineraryController.EventDetail eventDetail = new HamItineraryController.EventDetail();
        eventDetail.startDateTime = Datetime.now();
        eventDetail.endDateTime = Datetime.now().addDays(1);
        eventDetail.tripDetailId = tripDetailId;

        HamItineraryController.EventDetail meetingEventDetail = (HamItineraryController.EventDetail) JSON.deserialize(JSON.serialize(eventDetail), HamItineraryController.EventDetail.class);
        meetingEventDetail.type = 'HAM_Meeting';
        meetingEventDetail.meetingStatus = 'Scheduled';
        meetingEventDetail.contactId = [SELECT Id FROM Contact WHERE LastName = 'Test' LIMIT 1].Id;
        meetingEventDetail.address = '123 Main St';
        meetingEventDetail.description = 'Test Description';
        HamItineraryController.saveEvent(meetingEventDetail);

        HamItineraryController.EventDetail accommodationEventDetail = (HamItineraryController.EventDetail) JSON.deserialize(JSON.serialize(eventDetail), HamItineraryController.EventDetail.class);
        accommodationEventDetail.stayDetailsName = 'Test Stay Details';
        accommodationEventDetail.type = 'HAM_Accommodation';
        accommodationEventDetail.address = '123 Main St';
        HamItineraryController.saveEvent(accommodationEventDetail);

        HamItineraryController.EventDetail travelEventDetail = (HamItineraryController.EventDetail) JSON.deserialize(JSON.serialize(eventDetail), HamItineraryController.EventDetail.class);
        travelEventDetail.mode = 'Car';
        travelEventDetail.flightOrTrainNumber = 'AA123';
        travelEventDetail.sourceAirport = 'JFK';
        travelEventDetail.destinationAirport = 'LAX';
        travelEventDetail.type = 'HAM_Transportation';
        HamItineraryController.saveEvent(travelEventDetail);

        HamItineraryController.deleteEvent(String.valueOf([SELECT Id FROM Event WHERE WhatId = :tripDetailId][0].Id));

        HamItineraryController.sendDigitalTrip(tripDetailId, 'Test Subject', 'Test Body');

        HAM_Itinerary_Email_Setting__c emailSetting = HAM_Itinerary_Email_Setting__c.getInstance();
        emailSetting.Recipient__c = 'jescyq@leedssource.com';
        insert emailSetting;
        HamItineraryController.sendDigitalTrip(tripDetailId, 'Test Subject', 'Test Body');

        HamItineraryController.getMeetingStatusOptions();

        HamItineraryController.getInvolvementOptions(new List<String>{'Student Clubs', 'Student Private Societies'});

        HamItineraryController.getStakeholders(tripDetailId);

    }
    @IsTest
    static void testSearchAddress(){
        Test.setMock(HttpCalloutMock.class, new GeocodingCalloutMock());
        Test.startTest();
        HamItineraryController.searchAddress('Naples Florida');
        Test.stopTest();
    }
}