public with sharing class HAMJediSearchController {
   @AuraEnabled(cacheable=false)
    public static List<Contact> searchContact(string searchStr, string donorId) {

        String searchName = '\'%' + searchStr + '%\'';
        String queryString = 'SELECT ID, Name,HAM_Name_w_Suffix__c,HAM_Institutional_Suffix__c,ucinn_ascendv2__Primary_Contact_Type__c, ucinn_ascendv2__Donor_ID__c, HAM_PreferredEmail__c, HAM_Formatted_Phone__c FROM Contact WHERE ';
        if(String.isNotBlank(searchStr) && String.isNotBlank(donorId)){
            queryString+= 'HAM_Name_w_Suffix__c LIKE '+searchName+' AND ucinn_ascendv2__Donor_ID__c= '+'\''+donorId+'\'';
        }else if(String.isNotBlank(searchStr)){
            queryString+= 'HAM_Name_w_Suffix__c LIKE '+searchName;

        }else{
            queryString+= 'ucinn_ascendv2__Donor_ID__c= '+'\''+donorId+'\'';
        }
        queryString+= ' ORDER BY HAM_Name_w_Suffix__c ASC';
        system.debug('Query Str -----'+queryString);
        List<Contact> constitiuents = Database.query(queryString);
         system.debug('Query Results -----'+constitiuents);
        return constitiuents;
    }

    @AuraEnabled(cacheable=true)
    public static List<Contact> searchRecentRecords() {
        List<Contact> recentlyViewedRecords= [SELECT ID, Name,HAM_Name_w_Suffix__c,ucinn_ascendv2__Donor_ID__c FROM Contact WHERE LastViewedDate != NULL ORDER BY LastViewedDate DESC Limit 10];
        return recentlyViewedRecords;
    }

    
}