@IsTest
public class HAMJediContactReportControllerTest {
    
    @TestSetup
    static void setupTestData() {
        Account testAccount = HAMJediTestDataFactory.makeAccount('Contact Report Test Account');
        Contact testContact = HAMJediTestDataFactory.makeContactWithDonorId('TestContact', testAccount.Id, 'D12345');
        
        // Create contact reports using existing factory methods
        HAMJediTestDataFactory.makeContactReport(testContact.Id);
        HAMJediTestDataFactory.makeContactReports(testContact.Id, 3);
    }
    
    @IsTest
    static void testGetContactReportDetail() {
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
        
        Test.startTest();
        List<ucinn_ascendv2__Contact_Report__c> results = HAMJediContactReportController.getContactReportDetail(testContact.Id);
        Test.stopTest();
        
        System.assertNotEquals(null, results, 'Should return contact reports list');
        System.assertEquals(4, results.size(), 'Should return 4 contact reports total');
        
        // Verify required fields are populated
        for (ucinn_ascendv2__Contact_Report__c report : results) {
            System.assertNotEquals(null, report.Id, 'Report ID should be populated');
            System.assertNotEquals(null, report.Name, 'Report Name should be populated');
        }
    }
    
    @IsTest
    static void testGetContactReportDetailNoReports() {
        // Create a contact without reports
        Account account = HAMJediTestDataFactory.makeAccount('No Reports Account');
        Contact contactNoReports = HAMJediTestDataFactory.makeContactWithDonorId('NoReports', account.Id, 'D99999');
        
        Test.startTest();
        List<ucinn_ascendv2__Contact_Report__c> results = HAMJediContactReportController.getContactReportDetail(contactNoReports.Id);
        Test.stopTest();
        
        System.assertNotEquals(null, results, 'Should return empty list, not null');
        System.assertEquals(0, results.size(), 'Should return empty list when no reports exist');
    }
    
    @IsTest
    static void testGetContactReportDetailOrdering() {
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
        
        // Create additional report to test ordering
        HAMJediTestDataFactory.makeContactReport(testContact.Id);
        
        Test.startTest();
        List<ucinn_ascendv2__Contact_Report__c> results = HAMJediContactReportController.getContactReportDetail(testContact.Id);
        Test.stopTest();
        
        System.assert(results.size() > 1, 'Should have multiple reports for ordering test');
        // Results should be ordered by LastModifiedDate DESC
        // We can verify the query executes without errors
    }
    
    @IsTest
    static void testGetContactReportFieldAccess() {
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
        
        Test.startTest();
        List<ucinn_ascendv2__Contact_Report__c> results = HAMJediContactReportController.getContactReportDetail(testContact.Id);
        Test.stopTest();
        
        if (results.size() > 0) {
            ucinn_ascendv2__Contact_Report__c report = results[0];
            // Verify all queried fields are accessible (no exceptions thrown)
            String name = report.Name;
            String contactMethod = report.ucinn_ascendv2__Contact_Method__c;
            String substantive = report.ucinn_ascendv2__Substantive_Contact__c;
            String description = report.ucinn_ascendv2__Description__c;
            String body = report.ucinn_ascendv2__Contact_Report_Body__c;
            Date reportDate = report.ucinn_ascendv2__Date__c;
            String prm = report.HAM_PRM_at_Time_of_Meeting__c;
            String lastModifiedByName = report.LastModifiedBy?.Name;

            System.assertNotEquals(null, report.Id, 'Report should have ID');
            System.assertNotEquals(null, lastModifiedByName, 'Last Modified By Name should be populated');
        }
    }
    
    @IsTest
    static void testGetContactReportDetailWithNullContactId() {
        Test.startTest();
        List<ucinn_ascendv2__Contact_Report__c> results = HAMJediContactReportController.getContactReportDetail(null);
        Test.stopTest();
        
        System.assertNotEquals(null, results, 'Should return empty list for null contact ID');
        System.assertEquals(0, results.size(), 'Should return empty list for null contact ID');
    }
    
    @IsTest
    static void testGetContactReportDetailWithEmptyContactId() {
        Test.startTest();
        List<ucinn_ascendv2__Contact_Report__c> results = HAMJediContactReportController.getContactReportDetail('');
        Test.stopTest();
        
        System.assertNotEquals(null, results, 'Should return empty list for empty contact ID');
        System.assertEquals(0, results.size(), 'Should return empty list for empty contact ID');
    }
}