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

        // Test ChildContact
        HAMProspectOverviewApexController.ChildContact childContact = new HAMProspectOverviewApexController.ChildContact('Test Child', '003000000000001');
        System.assertEquals('Test Child', childContact.displayName, 'ChildContact should set displayName');
        System.assertEquals('003000000000001', childContact.contactId, 'ChildContact should set contactId');
    }

    @IsTest
    static void testGetChildrenLinksWithMatches() {
        // Create contacts with unique names in a single insert to minimize DML
        Account testAccount = HAMJediTestDataFactory.makeAccount('Children Test Account');

        List<Contact> contacts = new List<Contact>();

        // Child 1
        Contact child1 = new Contact(
            FirstName = 'Danielle',
            LastName = 'ChildTestOne' + System.now().getTime(),
            AccountId = testAccount.Id,
            ucinn_ascendv2__Donor_ID__c = 'DChild1' + System.now().getTime(),
            HAM_Alum_Suffix__c = '\'09',
            Email = 'childtest1@test.com'
        );
        contacts.add(child1);

        // Child 2
        Contact child2 = new Contact(
            FirstName = 'Hillary',
            LastName = 'ChildTestTwo' + System.now().getTime(),
            AccountId = testAccount.Id,
            ucinn_ascendv2__Donor_ID__c = 'DChild2' + System.now().getTime(),
            HAM_Alum_Suffix__c = '\'11',
            Email = 'childtest2@test.com'
        );
        contacts.add(child2);

        insert contacts;

        // Re-query to get the calculated formula field values
        List<Contact> insertedContacts = [SELECT Id, HAM_Name_w_Suffix__c FROM Contact WHERE Id IN :contacts ORDER BY FirstName];

        String childrenString = insertedContacts[0].HAM_Name_w_Suffix__c + ', ' + insertedContacts[1].HAM_Name_w_Suffix__c;

        Test.startTest();
        List<HAMProspectOverviewApexController.ChildContact> result = HAMProspectOverviewApexController.getChildrenLinks(childrenString);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Should return a list');
        System.assertEquals(2, result.size(), 'Should return 2 children');
        System.assertNotEquals(null, result[0].contactId, 'First child should have contactId');
        System.assertNotEquals(null, result[1].contactId, 'Second child should have contactId');
    }

    @IsTest
    static void testGetChildrenLinksWithoutMatches() {
        Test.startTest();
        List<HAMProspectOverviewApexController.ChildContact> result = HAMProspectOverviewApexController.getChildrenLinks('Unknown Child \'09, Another Child \'10');
        Test.stopTest();

        System.assertNotEquals(null, result, 'Should return a list');
        System.assertEquals(2, result.size(), 'Should return 2 children');
        System.assertEquals('Unknown Child \'09', result[0].displayName, 'First child display name should match');
        System.assertEquals(null, result[0].contactId, 'First child should not have contactId');
        System.assertEquals('Another Child \'10', result[1].displayName, 'Second child display name should match');
        System.assertEquals(null, result[1].contactId, 'Second child should not have contactId');
    }

    @IsTest
    static void testGetChildrenLinksWithEmptyString() {
        Test.startTest();
        List<HAMProspectOverviewApexController.ChildContact> result = HAMProspectOverviewApexController.getChildrenLinks('');
        Test.stopTest();

        System.assertNotEquals(null, result, 'Should return a list');
        System.assertEquals(0, result.size(), 'Should return empty list for empty string');
    }

    @IsTest
    static void testGetChildrenLinksWithNullString() {
        Test.startTest();
        List<HAMProspectOverviewApexController.ChildContact> result = HAMProspectOverviewApexController.getChildrenLinks(null);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Should return a list');
        System.assertEquals(0, result.size(), 'Should return empty list for null string');
    }

    @IsTest
    static void testGetChildrenLinksMixedMatches() {
        // Create test account
        Account testAccount = HAMJediTestDataFactory.makeAccount('Mixed Children Test');

        // Create one matching child in a single operation
        Contact child1 = new Contact(
            FirstName = 'John',
            LastName = 'MixedTestChild' + System.now().getTime(),
            AccountId = testAccount.Id,
            ucinn_ascendv2__Donor_ID__c = 'DMixed1' + System.now().getTime(),
            HAM_Alum_Suffix__c = '\'15',
            Email = 'mixedtest@test.com'
        );
        insert child1;

        // Re-query to get the calculated formula field value
        child1 = [SELECT Id, HAM_Name_w_Suffix__c FROM Contact WHERE Id = :child1.Id];

        Test.startTest();
        List<HAMProspectOverviewApexController.ChildContact> result = HAMProspectOverviewApexController.getChildrenLinks(child1.HAM_Name_w_Suffix__c + ', Unknown Person \'16');
        Test.stopTest();

        System.assertNotEquals(null, result, 'Should return a list');
        System.assertEquals(2, result.size(), 'Should return 2 children');
        System.assertNotEquals(null, result[0].contactId, 'First child should have contactId');
        System.assertEquals('Unknown Person \'16', result[1].displayName, 'Second child display name should match');
        System.assertEquals(null, result[1].contactId, 'Second child should not have contactId');
    }
}