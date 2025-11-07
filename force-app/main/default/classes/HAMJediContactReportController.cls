public with sharing class HAMJediContactReportController {
    @AuraEnabled(cacheable=true)
    public static List<ucinn_ascendv2__Contact_Report__c> getContactReportDetail(String contactId) {
        List<ucinn_ascendv2__Contact_Report__c> contactReports = new List<ucinn_ascendv2__Contact_Report__c>();
        contactReports = [SELECT Id, Name, ucinn_ascendv2__Contact_Method__c, ucinn_ascendv2__Substantive_Contact__c, ucinn_ascendv2__Description__c, ucinn_ascendv2__Contact_Report_Body__c,ucinn_ascendv2__Date__c,HAM_PRM_at_Time_of_Meeting__c, HAM_Publish_to_Listserv__c, LastModifiedBy.Name
                       FROM ucinn_ascendv2__Contact_Report__c
                       WHERE ucinn_ascendv2__Contact__c =:contactId ORDER BY LastModifiedDate DESC];
        return contactReports;
    }
}