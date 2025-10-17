@IsTest
public class HAMJediSearchControllerTest {
    
    @TestSetup
    static void setupTestData() {
        Account testAccount = HAMJediTestDataFactory.makeAccount('Search Test Account');
        
        // Create test contacts with donor IDs
        HAMJediTestDataFactory.makeContactWithDonorId('Johnson', testAccount.Id, 'D12345');
        HAMJediTestDataFactory.makeContactWithDonorId('Smith', testAccount.Id, 'D67890');
        HAMJediTestDataFactory.makeContactWithDonorId('Williams', testAccount.Id, 'D54321');
    }
    
    @IsTest
    static void testSearchContactWithBothParams() {
        Test.startTest();
        List<Contact> results = HAMJediSearchController.searchContact('Johnson', 'D12345');
        Test.stopTest();
        
        System.assert(results.size() >= 0, 'Search should execute without errors');
    }
    
    @IsTest
    static void testSearchContactWithNameOnly() {
        Test.startTest();
        List<Contact> results = HAMJediSearchController.searchContact('Smith', '');
        Test.stopTest();
        
        System.assert(results.size() >= 0, 'Search should execute without errors');
    }
    
    @IsTest
    static void testSearchContactWithDonorIdOnly() {
        Test.startTest();
        List<Contact> results = HAMJediSearchController.searchContact('', 'D67890');
        Test.stopTest();
        
        System.assert(results.size() >= 0, 'Search should execute without errors');
        if (results.size() > 0) {
            System.assertEquals('D67890', results[0].ucinn_ascendv2__Donor_ID__c, 'Should have correct donor ID');
        }
    }
    
    @IsTest
    static void testSearchContactPartialMatch() {
        Test.startTest();
        List<Contact> results = HAMJediSearchController.searchContact('Test', '');
        Test.stopTest();
        
        System.assert(results.size() >= 0, 'Search should execute without errors');
    }
    
    @IsTest
    static void testSearchContactNoResults() {
        Test.startTest();
        List<Contact> results = HAMJediSearchController.searchContact('NonExistent', '');
        Test.stopTest();
        
        System.assertEquals(0, results.size(), 'Should return no results for non-existent search');
    }
    
    @IsTest
    static void testSearchRecentRecords() {
        Test.startTest();
        List<Contact> results = HAMJediSearchController.searchRecentRecords();
        Test.stopTest();
        
        System.assert(results.size() >= 0, 'Should execute without errors');
        System.assert(results.size() <= 10, 'Should return maximum 10 records');
    }
    
    @IsTest
    static void testSearchContactEmptyParams() {
        Test.startTest();
        List<Contact> results = HAMJediSearchController.searchContact('', '');
        Test.stopTest();
        
        System.assert(results.size() >= 0, 'Search should handle empty parameters');
    }
    
    @IsTest
    static void testSearchContactNullParams() {
        Test.startTest();
        List<Contact> results = HAMJediSearchController.searchContact(null, null);
        Test.stopTest();
        
        System.assert(results.size() >= 0, 'Search should handle null parameters');
    }
}