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

    // Tests for getChildrenFromRelationships
    @IsTest
    static void testGetChildrenFromRelationshipsWithChildren() {
        // Setup reciprocal relationship custom setting
        ucinn_ascendv2__Reciprocal_Relationships__c childSetting = new ucinn_ascendv2__Reciprocal_Relationships__c(
            Name = 'Child',
            ucinn_ascendv2__Reciprocal__c = 'Child'
        );
        insert childSetting;

        Account testAccount = HAMJediTestDataFactory.makeAccount('Relationship Test Account');
        Contact parent = HAMJediTestDataFactory.makeContactWithDonorId('Parent', testAccount.Id);
        Contact child1 = HAMJediTestDataFactory.makeContactWithDonorId('ChildOne', testAccount.Id);
        Contact child2 = HAMJediTestDataFactory.makeContactWithDonorId('ChildTwo', testAccount.Id);

        // Create relationship records
        ucinn_ascendv2__Relationship__c rel1 = new ucinn_ascendv2__Relationship__c(
            ucinn_ascendv2__Contact__c = parent.Id,
            ucinn_ascendv2__Related_Contact__c = child1.Id,
            ucinn_ascendv2__Related_Contact_Role__c = 'Child'
        );
        ucinn_ascendv2__Relationship__c rel2 = new ucinn_ascendv2__Relationship__c(
            ucinn_ascendv2__Contact__c = parent.Id,
            ucinn_ascendv2__Related_Contact__c = child2.Id,
            ucinn_ascendv2__Related_Contact_Role__c = 'Child'
        );
        insert new List<ucinn_ascendv2__Relationship__c>{rel1, rel2};

        Test.startTest();
        List<HAMProspectOverviewApexController.ChildContact> result = HAMProspectOverviewApexController.getChildrenFromRelationships(parent.Id);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Should return a list');
        System.assertEquals(2, result.size(), 'Should return 2 children');
        System.assertNotEquals(null, result[0].contactId, 'First child should have contactId');
        System.assertNotEquals(null, result[1].contactId, 'Second child should have contactId');
    }

    @IsTest
    static void testGetChildrenFromRelationshipsWithNoChildren() {
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];

        Test.startTest();
        List<HAMProspectOverviewApexController.ChildContact> result = HAMProspectOverviewApexController.getChildrenFromRelationships(testContact.Id);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Should return a list');
        System.assertEquals(0, result.size(), 'Should return empty list when no children');
    }

    @IsTest
    static void testGetChildrenFromRelationshipsWithBlankId() {
        Test.startTest();
        List<HAMProspectOverviewApexController.ChildContact> result = HAMProspectOverviewApexController.getChildrenFromRelationships('');
        Test.stopTest();

        System.assertNotEquals(null, result, 'Should return a list');
        System.assertEquals(0, result.size(), 'Should return empty list for blank ID');
    }

    // Tests for getParentsFromRelationships
    @IsTest
    static void testGetParentsFromRelationshipsWithParents() {
        // Setup reciprocal relationship custom setting
        ucinn_ascendv2__Reciprocal_Relationships__c parentSetting = new ucinn_ascendv2__Reciprocal_Relationships__c(
            Name = 'Parent',
            ucinn_ascendv2__Reciprocal__c = 'Parent'
        );
        insert parentSetting;

        Account testAccount = HAMJediTestDataFactory.makeAccount('Parent Relationship Test');
        Contact child = HAMJediTestDataFactory.makeContactWithDonorId('ChildContact', testAccount.Id);
        Contact parent1 = HAMJediTestDataFactory.makeContactWithDonorId('ParentOne', testAccount.Id);
        Contact parent2 = HAMJediTestDataFactory.makeContactWithDonorId('ParentTwo', testAccount.Id);

        // Create relationship records
        ucinn_ascendv2__Relationship__c rel1 = new ucinn_ascendv2__Relationship__c(
            ucinn_ascendv2__Contact__c = child.Id,
            ucinn_ascendv2__Related_Contact__c = parent1.Id,
            ucinn_ascendv2__Related_Contact_Role__c = 'Parent'
        );
        ucinn_ascendv2__Relationship__c rel2 = new ucinn_ascendv2__Relationship__c(
            ucinn_ascendv2__Contact__c = child.Id,
            ucinn_ascendv2__Related_Contact__c = parent2.Id,
            ucinn_ascendv2__Related_Contact_Role__c = 'Parent'
        );
        insert new List<ucinn_ascendv2__Relationship__c>{rel1, rel2};

        Test.startTest();
        List<HAMProspectOverviewApexController.ChildContact> result = HAMProspectOverviewApexController.getParentsFromRelationships(child.Id);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Should return a list');
        System.assertEquals(2, result.size(), 'Should return 2 parents');
        System.assertNotEquals(null, result[0].contactId, 'First parent should have contactId');
        System.assertNotEquals(null, result[1].contactId, 'Second parent should have contactId');
    }

    @IsTest
    static void testGetParentsFromRelationshipsWithNoParents() {
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];

        Test.startTest();
        List<HAMProspectOverviewApexController.ChildContact> result = HAMProspectOverviewApexController.getParentsFromRelationships(testContact.Id);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Should return a list');
        System.assertEquals(0, result.size(), 'Should return empty list when no parents');
    }

    @IsTest
    static void testGetParentsFromRelationshipsWithBlankId() {
        Test.startTest();
        List<HAMProspectOverviewApexController.ChildContact> result = HAMProspectOverviewApexController.getParentsFromRelationships('');
        Test.stopTest();

        System.assertNotEquals(null, result, 'Should return a list');
        System.assertEquals(0, result.size(), 'Should return empty list for blank ID');
    }
}