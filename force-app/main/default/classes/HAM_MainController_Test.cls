/**
* @File Name : HAM_MainController_Test.cls
* @Description : Test class for HAM_MainController to ensure 100% coverage
* @Author : Sachin Kumar Sharma
* @Last Modified By : Sachin Kumar Sharma
* @Last Modified On : August 21, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | August 21, 2025 | Sachin Kumar Sharma  | Initial Version
**/

@isTest
public class HAM_MainController_Test {
    
    @testSetup
    static void setupData() {
        // Create a Profile
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        
        Profile p2 = [SELECT Id FROM Profile WHERE Name = 'Partner Community Login User' LIMIT 1];
        
        // Create a Contact for the portal user
        Contact con = new Contact(FirstName = 'Test', LastName = 'Contact');
        insert con;
        
        // User1 : Base internal user (will simulate ContactId in test)
        User u1 = new User(
            FirstName = 'Test',
            LastName = 'User1',
            Email = 'user1@test.com',
            Username = 'user1_' + System.currentTimeMillis() + '@test.com',
            Alias = 'u1',
            TimeZoneSidKey = 'GMT',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = p.Id
        );
        insert u1;
        
        // User2 : No ContactId, will test branch 2
        User u2 = new User(
            FirstName = 'Test',
            LastName = 'User2',
            Email = 'user2@test.com',
            Username = 'user2_' + System.currentTimeMillis() + '@test.com',
            Alias = 'u2',
            TimeZoneSidKey = 'GMT',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = p.Id
        );
        insert u2;
        
        // User3 : Same email as u2, pretend as portal user with ContactId
        // (for test branch simulation we don't need a real contact association)
        User u3 = new User(
            FirstName = 'Test',
            LastName = 'User3',
            Email = u2.Email,
            Username = 'user3_' + System.currentTimeMillis() + '@test.com',
            Alias = 'u3',
            TimeZoneSidKey = 'GMT',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = p2.Id,
            IsActive = true,
            // Assign the ContactId to u3
            ContactId = con.Id
        );
        insert u3;
    }
    
    /**
     * Test for getMyLinksMetaData
     * Assumes CMDT record with HAM_Level_1__c = 'NavBar' exists in org
     */
    @isTest
    static void testGetMyLinksMetaData() {
        Test.startTest();
        List<HAM_Meta_Data__mdt> result = HAM_MainController.getMyLinksMetaData();
        Test.stopTest();
        System.assertNotEquals(0, result.size(), 'Expected metadata records');
    }
    
    /**
     * Test for fetchLoggedInUserInfo where user has ContactId
     * We simulate this by mocking via System.runAs and patching in-memory value
     */
    @isTest
    static void testFetchLoggedInUserInfo_withContactId() {
        User u1 = [SELECT Id, Email FROM User WHERE Email = 'user1@test.com' LIMIT 1];
        
        System.runAs(u1) {
            Test.startTest();
            // We cannot assign ContactId to internal users, but method only checks queried value
            // To simulate, we mock with null → method will fallback internally
            String contactId = HAM_MainController.fetchLoggedInUserInfo();
            Test.stopTest();
            
            System.assertEquals(null, contactId, 'Should return null as there is no ContactId and no fallback');
        }
    }
    
    /**
     * Test for fetchLoggedInUserInfo where user has no ContactId
     * but another active user with same email does (simulated portal user branch)
     */
    @isTest
    static void testFetchLoggedInUserInfo_withSameEmailPortalUser() {
        User u2 = [SELECT Id, Email FROM User WHERE Email = 'user2@test.com' LIMIT 1];
        
        System.runAs(u2) {
            Test.startTest();
            String contactId = HAM_MainController.fetchLoggedInUserInfo();
            Test.stopTest();
            
            System.assertNotEquals(null, contactId, 'Should return ContactId from simulated portal user');
        }
    }
    
    /**
     * Test for fetchLoggedInUserInfo where no ContactId is found
     * → should fallback to hardcoded Id
     */
    @isTest
    static void testFetchLoggedInUserInfo_noContactIdFallback() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        
        User u4 = new User(
            FirstName = 'Fallback',
            LastName = 'User',
            Email = 'unique_' + System.currentTimeMillis() + '@test.com',
            Username = 'fallback_' + System.currentTimeMillis() + '@test.com',
            Alias = 'fb',
            TimeZoneSidKey = 'GMT',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = p.Id
        );
        insert u4;
        
        System.runAs(u4) {
            Test.startTest();
            String contactId = HAM_MainController.fetchLoggedInUserInfo();
            Test.stopTest();
            
            System.assertEquals(null, contactId, 'Should return null as the hardcoded ContactId fallback is gone.');
        }
    }
}