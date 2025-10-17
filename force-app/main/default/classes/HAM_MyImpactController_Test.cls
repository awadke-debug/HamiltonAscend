/**
* @File Name : HAM_MyImpactController_Test.cls
* @Description : This is the test class for HAM_MyImpactController to ensure 
*                contact and philanthropy details are fetched correctly on My Impact page.
* @Author : Sachin Kumar Sharma
* @Last Modified By : Sachin
* @Last Modified On : Aug 21, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | August 21, 2025 | Sachin Kumar Sharma  | Initial Version
**/
@IsTest
private class HAM_MyImpactController_Test {
    
    /**
     * @description Test data setup method. This method creates all necessary data once
     * for all test methods in this class to use, ensuring a consistent and efficient test environment.
     */
    @TestSetup
    static void setupTestData() {
        // Create an Account
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        // Create a Contact
        Contact contact = new Contact(
            LastName = 'TestUser',
            AccountId = acc.Id,
            HAM_Profile_Picture_URL__c = 'http://testurl.com/profile.jpg',
            HAM_LiveAlumni_LinkedIn_URL__c = 'http://linkedin.com/testuser',
            HAM_1812__c = true
        );
        insert contact;
        
        // Find a valid community or portal profile to associate with the contact
        Profile p = [SELECT Id FROM Profile WHERE Name LIKE 'Partner Community Login User' LIMIT 1];
                
        // Create a user linked to the contact for testing
        User u = new User(
            Alias = 'testuser',
            Email = 'testuser' + System.currentTimeMillis() + '@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Testing',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'testuser' + System.currentTimeMillis() + '@test.com',
            ContactId = contact.Id
        );
        insert u;
        
        // Create a standard user to act as the relationship manager
        Profile sysAdminProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        User relMgrUser = new User(
            Alias = 'relmgr',
            Email = 'relmgr' + System.currentTimeMillis() + '@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Relationship Manager',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = sysAdminProfile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'relmgr' + System.currentTimeMillis() + '@test.com'
        );
        insert relMgrUser;

        // Create the Designation record
        ucinn_ascendv2__Designation__c designation = new ucinn_ascendv2__Designation__c(
            Name = 'Test Designation',
            ucinn_ascendv2__Fund_Name__c = 'Test Fund'
        );
        insert designation;

        // Create related records
        ucinn_ascendv2__Designation_Stewardship__c purposeRecord = new ucinn_ascendv2__Designation_Stewardship__c(
            ucinn_ascendv2__Contact_Stewardee__c = contact.Id,
            ucinn_ascendv2__Designation__c = designation.Id
        );
        insert purposeRecord;

        ucinn_ascendv2__Degree_Information__c degreeRecord = new ucinn_ascendv2__Degree_Information__c(
            ucinn_ascendv2__Contact__c = contact.Id
        );
        insert degreeRecord;
        
        ucinn_ascendv2__Social_Media__c socialMedia = new ucinn_ascendv2__Social_Media__c(
            ucinn_ascendv2__Contact__c = contact.Id,
            ucinn_ascendv2__Platform__c = 'Facebook',
            ucinn_ascendv2__URL__c = 'http://facebook.com/testuser'
        );
        insert socialMedia;

        // Create the Assignment record and link it to the new relationship manager user
        ucinn_ascendv2__Assignment__c classAssignment = new ucinn_ascendv2__Assignment__c(
            ucinn_ascendv2__Contact__c = contact.Id,
            ucinn_ascendv2__Assignment_Type__c = 'Class Manager',
            ucinn_ascendv2__Assigned_Relationship_Manager_User__c = relMgrUser.Id
         );
        insert classAssignment;
    }
    
    /**
     * @description Test case to verify the successful retrieval of contact and philanthropy data.
     * It runs as the test user to simulate a real-world scenario.
     */
    @IsTest
    static void testGetContactAndPhilanthropyData() {
        // Get the test user and contact
        User testUser = [SELECT Id, ContactId FROM User WHERE Alias = 'testuser' LIMIT 1];
        Contact testContact = [SELECT Id FROM Contact WHERE LastName = 'TestUser' LIMIT 1];

        Test.startTest();
        // Call the main method with the contact's ID
        HAM_MyImpactController.MyImpactDataWrapper result = HAM_MyImpactController.getContactAndPhilanthropyData(testUser.ContactId);
        Test.stopTest();
        System.debug('result:'+result);
        // Assert the results
        System.assertNotEquals(null, result, 'Response wrapper should not be null.');
        System.assertNotEquals(null, result.contact, 'ContactInfo wrapper should not be null.');
        System.assertEquals('TestUser', result.contact.Name, 'Contact name should match.');
        System.assertNotEquals(null, result.degree, 'Degree list should not be null.');
        
    }

    /**
     * @description Test case to verify the successful retrieval of detailed philanthropy information.
     */
    @IsTest
    static void testGetPhilanthropyDetails() {
        // Get the test contact ID
        Contact testContact = [SELECT Id FROM Contact WHERE LastName = 'TestUser' LIMIT 1];
        
        Test.startTest();
        // Call the method to test
        HAM_MyImpactController.PhilanthropyDetail result = HAM_MyImpactController.getPhilanthropyDetails(testContact.Id);
        Test.stopTest();
        
        // Assert the results
        System.assertNotEquals(null, result, 'PhilanthropyDetail wrapper should not be null.');
        System.assertNotEquals(null, result.philanthropyField, 'PhilanthropyField list should not be null.');
        System.assertNotEquals(null, result.philanthropyDataTables, 'PhilanthropyDataTables list should not be null.');
    }

    /**
     * @description Test case to verify the successful retrieval of service and affinities data.
     */
    @IsTest
    static void testGetMyServiceAffinitiesData() {
        // Get the test contact ID
        Contact testContact = [SELECT Id FROM Contact WHERE LastName = 'TestUser' LIMIT 1];
        
        Test.startTest();
        // Call the method to test
        HAM_MyImpactController.MyServiceAffinities result = HAM_MyImpactController.getMyServiceAffinitiesData(testContact.Id);
        Test.stopTest();
        
        // Assert the results
        System.assertNotEquals(null, result, 'MyServiceAffinities wrapper should not be null.');
        System.assertNotEquals(null, result.myServices, 'MyServices list should not be null.');
        System.assertNotEquals(null, result.myAffinities, 'MyAffinities list should not be null.');
    }

    /**
     * @description Test case to verify the controller's graceful error handling
     * when an invalid or non-existent Contact ID is provided to the methods.
     */
    @IsTest
    static void testErrorHandling() {
        // We will call the methods with a non-existent ID to force an error
        String nonExistentId = '003000000000000';

        Test.startTest();
        // Test getContactAndPhilanthropyData error handling
        HAM_MyImpactController.MyImpactDataWrapper contactResult = HAM_MyImpactController.getContactAndPhilanthropyData(nonExistentId);
        
        // Assert that an error message is returned
        System.assertNotEquals(null, contactResult, 'Response wrapper should not be null.');

        // Test getPhilanthropyDetails error handling
        HAM_MyImpactController.PhilanthropyDetail philanthropyResult = HAM_MyImpactController.getPhilanthropyDetails(nonExistentId);

        // Assert that an error message is returned
        System.assertNotEquals(null, philanthropyResult, 'PhilanthropyDetail wrapper should not be null.');
        Test.stopTest();
    }
}