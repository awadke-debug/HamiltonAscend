public with sharing class HAMJediEventController {
    @AuraEnabled(cacheable=true)
    public static List<conference360__Attendee__c> getEventsDetail(String contactId) {
        List<conference360__Attendee__c> attendance = new List<conference360__Attendee__c>();
        attendance = [SELECT Id, Name,conference360__Event_Name__c,conference360__Event_End_Date_Time__c,conference360__Attendance_Status__c,conference360__Registration_Status__c
                       FROM conference360__Attendee__c
                       WHERE conference360__Contact__c =:contactId];
        return attendance;
    }

    @AuraEnabled(cacheable=true)
    public static List<et4ae5__IndividualEmailResult__c> getEmailDetail(String contactId) {
        List<et4ae5__IndividualEmailResult__c> emails = new List<et4ae5__IndividualEmailResult__c>();
        emails = [SELECT Name,et4ae5__FromName__c,et4ae5__FromAddress__c,et4ae5__SubjectLine__c,et4ae5__Contact__c,et4ae5__HardBounce__c,et4ae5__SoftBounce__c,et4ae5__DateBounced__c,et4ae5__Opened__c,et4ae5__DateOpened__c,et4ae5__NumberOfTotalClicks__c,et4ae5__NumberOfUniqueClicks__c FROM et4ae5__IndividualEmailResult__c WHERE et4ae5__Contact__c =:contactId];
        return emails;
    }
    
}