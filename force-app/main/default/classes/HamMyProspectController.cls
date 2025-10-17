public with sharing class HamMyProspectController {
     @AuraEnabled(cacheable=true)
    public static List<Contact> searchMyProspects() {
        Id userId =UserInfo.getUserId(); 
        List<Contact> recentlyViewedRecords= [SELECT ID, Name,HAM_Name_w_Suffix__c,HAM_Preferred_Chapter_Lookup__c,HAM_Preferred_Chapter_Lookup__r.name, HAM_Current_Chapters__c FROM Contact WHERE ucinn_ascendv2__PRM__c =:userId ORDER BY LastViewedDate DESC];
        system.debug('recentlyViewedRecords-----'+recentlyViewedRecords);
        return recentlyViewedRecords;
    }
}