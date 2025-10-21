@IsTest
public class HAMJediSearchControllerTest {
    
    @TestSetup
    static void setupTestData() {
        Account testAccount = HAMJediTestDataFactory.makeAccount('Search Test Account');
        
        HAMJediTestDataFactory.makeSearchContact('Johnson', testAccount.Id, 'D12345', '2020');
        HAMJediTestDataFactory.makeSearchContact('Smith', testAccount.Id, 'D67890', '2015');
        HAMJediTestDataFactory.makeSearchContact('Williams', testAccount.Id, 'D54321', '2018');
    }
    
    @IsTest
    static void testSearchContactByName() {
        Test.startTest();
        List<Contact> results = HAMJediSearchController.searchContact('Johnson', '', '', '', '');
        Test.stopTest();
        
        System.assert(results.size() > 0, 'Should find contact by name');
    }
    
    @IsTest
    static void testSearchContactByDonorId() {
        Test.startTest();
        List<Contact> results = HAMJediSearchController.searchContact('', 'D12345', '', '', '');
        Test.stopTest();
        
        System.assert(results.size() > 0, 'Should find contact by donor ID');
        System.assertEquals('D12345', results[0].ucinn_ascendv2__Donor_ID__c, 'Should return correct donor ID');
    }
    
    @IsTest
    static void testSearchContactByClassYear() {
        Test.startTest();
        List<Contact> results = HAMJediSearchController.searchContact('', '', '2020', '', '');
        Test.stopTest();
        
        System.assert(results.size() > 0, 'Should find contact by class year');
    }
    
    @IsTest
    static void testSearchContactCombinedNameAndDonorId() {
        Test.startTest();
        List<Contact> results = HAMJediSearchController.searchContact('Johnson', 'D12345', '', '', '');
        Test.stopTest();
        
        System.assert(results.size() > 0, 'Should find contact with multiple filters');
    }
    
    @IsTest
    static void testSearchContactNoMatches() {
        Test.startTest();
        List<Contact> results = HAMJediSearchController.searchContact('NonExistent', '', '', '', '');
        Test.stopTest();
        
        System.assertEquals(0, results.size(), 'Should return empty list when no matches');
    }
    
    @IsTest
    static void testSearchContactNoParams() {
        Test.startTest();
        List<Contact> results = HAMJediSearchController.searchContact('', '', '', '', '');
        Test.stopTest();
        
        System.assertEquals(0, results.size(), 'Should return empty list with no parameters');
    }
    
    @IsTest
    static void testSearchContactPartialNameMatch() {
        Test.startTest();
        List<Contact> results = HAMJediSearchController.searchContact('Smit', '', '', '', '');
        Test.stopTest();
        
        System.assert(results.size() > 0, 'Should find partial name matches');
    }
    
    @IsTest
    static void testSearchRecentRecords() {
        Test.startTest();
        List<Contact> results = HAMJediSearchController.searchRecentRecords();
        Test.stopTest();
        
        System.assert(results != null, 'Should return a list');
        System.assert(results.size() <= 10, 'Should return maximum 10 records');
    }
    
    @IsTest
    static void testGetClassYearOptions() {
        Test.startTest();
        List<String> classYears = HAMJediSearchController.getClassYearOptions();
        Test.stopTest();
        
        System.assert(classYears != null, 'Should return list');
        System.assert(classYears.size() >= 3, 'Should have at least 3 class years from setup');
    }
    
    @IsTest
    static void testGetSportsAssociationOptions() {
        Test.startTest();
        List<String> sportsAssociations = HAMJediSearchController.getSportsAssociationOptions();
        Test.stopTest();
        
        System.assert(sportsAssociations != null, 'Should return list');
        System.assert(sportsAssociations.size() >= 0, 'Should return valid list');
    }
    
    @IsTest
    static void testGetStudentOrganizationsOptions() {
        Test.startTest();
        List<String> studentOrgs = HAMJediSearchController.getStudentOrganizationsOptions();
        Test.stopTest();
        
        System.assert(studentOrgs != null, 'Should return list');
        System.assert(studentOrgs.size() >= 0, 'Should return valid list');
    }
}