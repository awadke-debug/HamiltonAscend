public with sharing class HAMJEDIPledgeBalanceController {
    @AuraEnabled(cacheable=true)
    public static List<HAM_Pledge_Balance__c> getCampaignDetail(String contactId) {
        List<HAM_Pledge_Balance__c> attendance = new List<HAM_Pledge_Balance__c>();
        String pdRecordTypeID = Schema.SObjectType.HAM_Pledge_Balance__c.getRecordTypeInfosByName().get('Campaign').getRecordTypeId();
        attendance = [SELECT Id, Name,
                        HAM_Designation__c,
                        HAM_Fiscal_Year__c,
                        HAM_Paid__c,
                        HAM_Pledge_Balance__c,
                        HAM_Pledged__c
                       FROM HAM_Pledge_Balance__c
                       WHERE Constituent__c =:contactId AND HAM_Status__c = 'active' AND RecordtypeID =:pdRecordTypeID];
        return attendance;
    }
    @AuraEnabled(cacheable=true)
    public static List<HAM_Pledge_Balance__c> getEndowdedFundsDetail(String contactId) {
        List<HAM_Pledge_Balance__c> attendance = new List<HAM_Pledge_Balance__c>();
        String pdRecordTypeID = Schema.SObjectType.HAM_Pledge_Balance__c.getRecordTypeInfosByName().get('Endowed Funds').getRecordTypeId();
        attendance = [SELECT Id, Name,
                        HAM_Designation__c,
                        HAM_Fiscal_Year__c,
                        HAM_Paid__c,
                        HAM_Pledge_Balance__c,
                        HAM_Pledged__c,
                        HAM_Endowed_Fund_Date__c
                       FROM HAM_Pledge_Balance__c
                       WHERE Constituent__c =:contactId AND HAM_Status__c = 'active' AND RecordtypeID =:pdRecordTypeID];
        return attendance;
    }
    @AuraEnabled(cacheable=true)
    public static List<HAM_Pledge_Balance__c> getGivingByPurposeDetail(String contactId) {
        List<HAM_Pledge_Balance__c> attendance = new List<HAM_Pledge_Balance__c>();
        String pdRecordTypeID = Schema.SObjectType.HAM_Pledge_Balance__c.getRecordTypeInfosByName().get('Giving By Purpose').getRecordTypeId();
        attendance = [SELECT Id, Name,
                        HAM_Designation__c,
                        HAM_Fiscal_Year__c,
                        HAM_Paid__c,
                        HAM_Pledge_Balance__c,
                        HAM_Pledged__c 
                       FROM HAM_Pledge_Balance__c
                       WHERE Constituent__c =:contactId AND HAM_Status__c = 'active' AND RecordtypeID =:pdRecordTypeID];
        return attendance;
    }
    @AuraEnabled(cacheable=true)
    public static List<HAM_Pledge_Balance__c> getLast5YearsDetail(String contactId) {
        List<HAM_Pledge_Balance__c> attendance = new List<HAM_Pledge_Balance__c>();
        String pdRecordTypeID = Schema.SObjectType.HAM_Pledge_Balance__c.getRecordTypeInfosByName().get('Last 5 year Giving').getRecordTypeId();
        attendance = [SELECT Id, Name,
                        HAM_Designation__c,
                        HAM_Fiscal_Year__c,
                        HAM_Paid__c,
                        HAM_Pledge_Balance__c,
                        HAM_Pledged__c 
                       FROM HAM_Pledge_Balance__c
                       WHERE Constituent__c =:contactId AND HAM_Status__c = 'active' AND RecordtypeID =:pdRecordTypeID];
        return attendance;
    }
    @AuraEnabled(cacheable=true)
    public static List<HAM_Pledge_Balance__c> getOpenPledgeDetail(String contactId) {
        List<HAM_Pledge_Balance__c> attendance = new List<HAM_Pledge_Balance__c>();
        String pdRecordTypeID = Schema.SObjectType.HAM_Pledge_Balance__c.getRecordTypeInfosByName().get('Open Pledge').getRecordTypeId();
        attendance = [SELECT Id, Name,
                        HAM_Designation__c,
                        HAM_Fiscal_Year__c,
                        HAM_Paid__c,
                        HAM_Pledge_Balance__c,
                        HAM_Pledged__c 
                       FROM HAM_Pledge_Balance__c
                       WHERE Constituent__c =:contactId AND HAM_Status__c = 'active' AND RecordtypeID =:pdRecordTypeID];
        return attendance;
    }

}