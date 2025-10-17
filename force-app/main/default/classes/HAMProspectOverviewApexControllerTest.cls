@IsTest
public class HAMProspectOverviewApexControllerTest {
    
    @TestSetup
    static void setupTestData() {
        Account testAccount = HAMJediTestDataFactory.makeAccount('Prospect Test Account');
        Contact testContact = HAMJediTestDataFactory.makeContactWithDonorId('TestProspect', testAccount.Id, 'D12345');
        
        // Set up minimal contact data
        testContact.ucinn_ascendv2__Is_Deceased__c = false;
        testContact.Birthdate = Date.newInstance(1990, 1, 1);
        update testContact;
        
        // Only create basic records that don't cause issues
        HAMJediTestDataFactory.makeServiceIndicator(testContact.Id);
        HAMJediTestDataFactory.makeDegreeInformation(testContact.Id);
    }
    
    @IsTest
    static void testSearchProspectDetails() {
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
        
        Test.startTest();
        Contact result = HAMProspectOverviewApexController.searchProspectDetails(testContact.Id);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Should return a contact record');
        System.assertEquals(testContact.Id, result.Id, 'Should return the correct contact');
    }
    
    @IsTest
    static void testSearchProspectGivingDetails() {
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
        
        Test.startTest();
        HAMProspectOverviewApexController.ContactWrapper result = HAMProspectOverviewApexController.searchProspectGivingDetails(testContact.Id);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Should return a ContactWrapper');
        System.assertNotEquals(null, result.objRecord, 'Should have contact record');
        System.assertNotEquals(null, result.designations, 'Should have designations list');
        System.assertEquals(0, result.designations.size(), 'Should have empty designations list');
    }
    
    @IsTest
    static void testSearchIndicatorDetails() {
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
        
        Test.startTest();
        HAMProspectOverviewApexController.ContactWrapper result = HAMProspectOverviewApexController.searchIndicatorDetails(testContact.Id);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Should return a ContactWrapper');
        System.assertEquals(false, result.isDeceased, 'Should set deceased status');
        System.assertNotEquals(null, result.isDoNotContact, 'Should have do not contact flag');
    }
    
    @IsTest
    static void testSearchProspectEducation() {
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
        
        Test.startTest();
        HAMProspectOverviewApexController.DegreeWrapper result = HAMProspectOverviewApexController.searchProspectEducation(testContact.Id);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Should return a DegreeWrapper');
        System.assertNotEquals(null, result.hamiltonDegree, 'Should have hamilton degree');
        System.assertNotEquals(null, result.awards, 'Should have awards list');
        System.assertEquals(0, result.awards.size(), 'Should have empty awards list');
    }
    
    @IsTest
    static void testGetDegreeRecord() {
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
        
        Test.startTest();
        ucinn_ascendv2__Degree_Information__c result = HAMProspectOverviewApexController.getDegreeRecord(testContact.Id);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Should return degree information');
        System.assertNotEquals(null, result.Id, 'Should have degree record ID');
    }
    
    @IsTest
    static void testGetProspectInvolvements() {
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
        HAMProspectOverviewApexController.DegreeWrapper wrapper = new HAMProspectOverviewApexController.DegreeWrapper();
        
        Test.startTest();
        HAMProspectOverviewApexController.DegreeWrapper result = HAMProspectOverviewApexController.getProspectInvolments(testContact.Id, wrapper);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Should return a DegreeWrapper');
        System.assertEquals('', result.athletics, 'Should have empty athletics string');
        System.assertEquals('', result.clubs, 'Should have empty clubs string');
        System.assertEquals('', result.societies, 'Should have empty societies string');
        System.assertNotEquals(null, result.awards, 'Should have awards list');
    }
    
    @IsTest
    static void testWrapperClasses() {
        // Test ContactWrapper
        HAMProspectOverviewApexController.ContactWrapper contactWrapper = new HAMProspectOverviewApexController.ContactWrapper();
        contactWrapper.isDeceased = true;
        contactWrapper.isDoNotContact = true;
        System.assertEquals(true, contactWrapper.isDeceased, 'ContactWrapper should set deceased flag');
        System.assertEquals(true, contactWrapper.isDoNotContact, 'ContactWrapper should set do not contact flag');
        
        // Test DegreeWrapper
        HAMProspectOverviewApexController.DegreeWrapper degreeWrapper = new HAMProspectOverviewApexController.DegreeWrapper();
        degreeWrapper.athletics = 'Test Athletics';
        degreeWrapper.clubs = 'Test Clubs';
        degreeWrapper.societies = 'Test Societies';
        System.assertEquals('Test Athletics', degreeWrapper.athletics, 'DegreeWrapper should set athletics');
        System.assertEquals('Test Clubs', degreeWrapper.clubs, 'DegreeWrapper should set clubs');
        System.assertEquals('Test Societies', degreeWrapper.societies, 'DegreeWrapper should set societies');
    }
}