public with sharing class HAMFixPrimaryDonorIssues implements Database.Batchable<sObject>,  Database.Stateful {
    List<DmlException> errors = new List<DmlException>(); 
    Map<Id,ucinn_ascendv2__Interim__c> primaryDonorInterimList = new Map<Id,ucinn_ascendv2__Interim__c>();

    public Database.QueryLocator start(Database.BatchableContext bc){
        Set<Id> oppIds = new Set<Id>();
        oppIds = getNewPrimaryDonorIssues();
        return Database.getQueryLocator([SELECT Id,ucinn_ascendv2__Opportunity__c, ucinn_ascendv2__Contact__c, ucinn_ascendv2__Account__c,HAM_Historical_Primary_Donor_Sources__c,HAM_Historical_Is_Primary_Donor__c,HAM_Old_Primary_Donor_Constituent_Type__c, HAM_Is_Primary_Donor__c, HAM_Primary_Donor_Constituent_Type__c, HAM_Primary_Donor_Sources__c,ucinn_ascendv2__Opportunity__r.HAM_Primary_Donor__c,ucinn_ascendv2__Opportunity__r.HAM_Primary_Donor_organization__c FROM ucinn_ascendv2__Hard_and_Soft_Credit__c WHERE ucinn_ascendv2__Opportunity__c IN: oppIds]);
    }
    public void execute(Database.BatchableContext bc, List<ucinn_ascendv2__Hard_and_Soft_Credit__c> lstCreditstoUpdate){
        //Generate the framework and associated data needed to update if match is found
        Map<Id,Contact> associatedContact = new Map<Id, Contact>();
        Map<Id,Account> associatedAccounts = new Map<Id, Account>();
        Set<Id> contactIds = new Set<Id>();
        Set<Id> accountIds = new Set<Id>();
        for(ucinn_ascendv2__Hard_and_Soft_Credit__c credits : lstCreditstoUpdate){
            if(credits.ucinn_ascendv2__Opportunity__r.HAM_Primary_Donor__c != null){
                contactIds.add(credits.ucinn_ascendv2__Opportunity__r.HAM_Primary_Donor__c);
            }else if(credits.ucinn_ascendv2__Opportunity__r.HAM_Primary_Donor_organization__c != null){
                accountIds.add(credits.ucinn_ascendv2__Opportunity__r.HAM_Primary_Donor_organization__c);
            }
        }
        //Use existing class methods to avoid duplicate logic and code issues
        HAMUpdateHistoricalOppPrimaryDonors objController = new HAMUpdateHistoricalOppPrimaryDonors();
        if(!contactIds.isEmpty()){
            associatedContact = objController.fetchConstitiuentDetails(contactIds);
        }
        if(!accountIds.isEmpty()){
            associatedAccounts = objController.fetchAccountDetails(accountIds);
        }
        //List of interims processed in this chunk of batch
        List<ucinn_ascendv2__Interim__c> completeInterims = new List<ucinn_ascendv2__Interim__c>();
        Set<Id> oppupdateIds = new Set<Id>();
        //Actual logic to find a match, if found update
        for(ucinn_ascendv2__Hard_and_Soft_Credit__c credits : lstCreditstoUpdate){
            if(credits.ucinn_ascendv2__Contact__c != null){
                if(credits.ucinn_ascendv2__Opportunity__r.HAM_Primary_Donor__c == credits.ucinn_ascendv2__Contact__c){
                    System.debug('Contact matched---'+credits);
                    credits.HAM_Is_Primary_Donor__c = true;
                    if(associatedContact.containsKey(credits.ucinn_ascendv2__Opportunity__r.HAM_Primary_Donor__c)){
                        Contact tempConstituent = associatedContact.get(credits.ucinn_ascendv2__Opportunity__r.HAM_Primary_Donor__c);
                        credits.HAM_Primary_Donor_Constituent_Type__c = tempConstituent.ucinn_ascendv2__Primary_Contact_Type__c;
                        credits.HAM_Primary_Donor_Sources__c = tempConstituent.ucinn_ascendv2__Contact_Type__c;
                    }
                }
            }else if(credits.ucinn_ascendv2__Account__c != null){
                if(credits.ucinn_ascendv2__Opportunity__r.HAM_Primary_Donor_organization__c == credits.ucinn_ascendv2__Account__c){
                    System.debug('Account matched---'+credits);
                    credits.HAM_Is_Primary_Donor__c = true;
                    if(associatedAccounts.containsKey(credits.ucinn_ascendv2__Opportunity__r.HAM_Primary_Donor_organization__c)){
                        Account tempAccount = associatedAccounts.get(credits.ucinn_ascendv2__Opportunity__r.HAM_Primary_Donor_organization__c);
                        credits.HAM_Primary_Donor_Constituent_Type__c = tempAccount.Type;
                        credits.HAM_Primary_Donor_Sources__c = tempAccount.Type;
                    }
                }
            }
            //As its multiple credits per opp, we create a list of unique interims to update
            if(oppupdateIds.isEmpty() || !oppupdateIds.contains(credits.ucinn_ascendv2__Opportunity__c) ){
                oppupdateIds.add(credits.ucinn_ascendv2__Opportunity__c);
                completeInterims.add(primaryDonorInterimList.get(credits.ucinn_ascendv2__Opportunity__c));
            }
        }


        try{
            update lstCreditstoUpdate;
            updateInterimList(completeInterims);
        }catch(DmlException ex){
            errors.add(ex);
        }
    }
    public void finish(Database.BatchableContext bc){
       
    }

    //Method to complete the Interim once the Credits are updated successfully
    public void updateInterimList(List<ucinn_ascendv2__Interim__c> completeInterims){
        for(ucinn_ascendv2__Interim__c interim : completeInterims){
            interim.HAM_Is_Completed__c = true;
        }
        try{
            update completeInterims;
        }catch(DmlException ex){
           system.debug('Interim Update Failed');
        }
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