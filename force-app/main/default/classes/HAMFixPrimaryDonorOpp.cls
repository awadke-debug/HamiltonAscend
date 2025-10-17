public with sharing class HAMFixPrimaryDonorOpp  implements Database.Batchable<sObject>,  Database.Stateful {
    
    List<DmlException> errors = new List<DmlException>(); 
    Map<Id,ucinn_ascendv2__Interim__c> primaryDonorInterimList = new Map<Id,ucinn_ascendv2__Interim__c>();

    public Database.QueryLocator start(Database.BatchableContext bc){
        Set<Id> oppIds = new Set<Id>();
        oppIds = getNewPrimaryDonorIssues();
        return Database.getQueryLocator([SELECT ID, Name, AccountId,ucinn_ascendv2__Contact__c,HAM_Primary_Donor__c, HAM_Primary_Donor_organization__c FROM Opportunity WHERE Id IN: oppIds]);
    }
    public void execute(Database.BatchableContext bc, List<Opportunity> opportunities){
        Set<Id> contactIds = new Set<Id>();
        Set<Id> accountIds = new Set<Id>();
        Map<Id,Account> associatedAccounts = new Map<Id, Account>();
        Map<Id,Contact> associatedContact = new Map<Id, Contact>();
        Map<Id,Id> affiliationaccountIdwithContactId = new Map<ID,ID>();

        HAMUpdateHistoricalOppPrimaryDonors objController = new HAMUpdateHistoricalOppPrimaryDonors();
        for(Opportunity opp:opportunities){
            if(String.isNotBlank(opp.AccountId)){
                accountIds.add(opp.AccountId);
            }else if(String.isNotBlank(opp.ucinn_ascendv2__Contact__c)){
                contactIds.add(opp.ucinn_ascendv2__Contact__c);
            }
        }
        if(!accountIds.isEmpty()){
            associatedAccounts = objController.fetchAccountDetails(accountIds);
            affiliationaccountIdwithContactId = objController.fetchRelatedPrimaryAffiliations(accountIds);
            contactIds.addAll(affiliationaccountIdwithContactId.values());

        }
        if(!contactIds.isEmpty()){
            associatedContact = objController.fetchConstitiuentDetails(contactIds);
        }
        opportunities = objController.checkPrimaryDonor(opportunities,associatedAccounts, associatedContact,affiliationaccountIdwithContactId);
         try{
            Update opportunities;
        } catch(DmlException e) {
            System.debug('The following exception has occurred: ' + e.getMessage());
            errors.add(e);
        }
    }
    public void finish(Database.BatchableContext bc){
       
    }

    //Method to fetch the Ids of Opportunity to get the credit records
    public Set<Id> getNewPrimaryDonorIssues(){
        primaryDonorInterimList = new Map<Id,ucinn_ascendv2__Interim__c>();
        String pdRecordTypeID = Schema.SObjectType.ucinn_ascendv2__Interim__c.getRecordTypeInfosByName().get('Primary Donor').getRecordTypeId();
        for(ucinn_ascendv2__Interim__c interim: [SELECT Id, Name, HAM_Primary_Donor_Opportunity__c, HAM_Is_Completed__c FROM ucinn_ascendv2__Interim__c WHERE HAM_Is_Completed__c = FALSE AND recordtypeId =: pdRecordTypeID]){
            primaryDonorInterimList.put(interim.HAM_Primary_Donor_Opportunity__c, interim);
        }
        Set<Id> oppIds = new Set<Id>();
        oppIds = primaryDonorInterimList.keySet();
        system.debug('Opportunities selected -------'+oppIds);
        return oppIds;
    }
}