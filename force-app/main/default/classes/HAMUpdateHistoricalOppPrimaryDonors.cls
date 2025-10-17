public with sharing class HAMUpdateHistoricalOppPrimaryDonors implements Database.Batchable<sObject>,  Database.Stateful {
    List<DmlException> errors = new List<DmlException>();
    
    public Database.QueryLocator start(Database.BatchableContext bc){
        Date newUpdateDate = date.newinstance(2025, 06, 04);
        // This is initial run query 
        //String queryStrNew = 'SELECT Id,ucinn_ascendv2__Opportunity__c, ucinn_ascendv2__Contact__c, ucinn_ascendv2__Account__c,HAM_Historical_Primary_Donor_Sources__c,HAM_Historical_Is_Primary_Donor__c,HAM_Old_Primary_Donor_Constituent_Type__c, HAM_Is_Primary_Donor__c, HAM_Primary_Donor_Constituent_Type__c, HAM_Primary_Donor_Sources__c FROM ucinn_ascendv2__Hard_and_Soft_Credit__c';
        //This is updated query to fix any missing record
        String queryStrNew = 'SELECT Id,ucinn_ascendv2__Opportunity__c, ucinn_ascendv2__Contact__c, ucinn_ascendv2__Account__c,HAM_Historical_Primary_Donor_Sources__c,HAM_Historical_Is_Primary_Donor__c,HAM_Old_Primary_Donor_Constituent_Type__c, HAM_Is_Primary_Donor__c, HAM_Primary_Donor_Constituent_Type__c, HAM_Primary_Donor_Sources__c FROM ucinn_ascendv2__Hard_and_Soft_Credit__c WHERE ucinn_ascendv2__Opportunity__r.HAM_Primary_Donor__c = Null  AND ucinn_ascendv2__Opportunity__r.HAM_Primary_Donor_organization__c = Null AND ucinn_ascendv2__Opportunity__r.CreatedDate >=: newUpdateDate ';
        return Database.getQueryLocator(queryStrNew);
    }
    public void execute(Database.BatchableContext bc, List<ucinn_ascendv2__Hard_and_Soft_Credit__c> lstCreditstoUpdate){
        Map<Id, Opportunity> Oppmap = new Map<Id, Opportunity>();
        Set<Id> contactIds = new Set<Id>();
		Set<Id> opportunityIds = new Set<Id>();
        Set<Id> accountIds = new Set<Id>();
        Map<Id,Account> associatedAccounts = new Map<Id, Account>();
        Map<Id,Contact> associatedContact = new Map<Id, Contact>();
		List<Opportunity> opportunities = new List<Opportunity>();
		for(ucinn_ascendv2__Hard_and_Soft_Credit__c objCredit:lstCreditstoUpdate){
			opportunityIds.add(objCredit.ucinn_ascendv2__Opportunity__c);
		}
        if(!opportunityIds.isEmpty()){
		    opportunities = fetchOpportunityDetails(opportunityIds);
        }
       //Get map of all affiliations for the opportunities
       Map<Id,Id> affiliationaccountIdwithContactId = new Map<ID,ID>();
       for(Opportunity opp:opportunities){
            if(String.isNotBlank(opp.AccountId)){
                accountIds.add(opp.AccountId);
            }else if(String.isNotBlank(opp.ucinn_ascendv2__Contact__c)){
                contactIds.add(opp.ucinn_ascendv2__Contact__c);
            }
       }
       if(!accountIds.isEmpty()){
            associatedAccounts = fetchAccountDetails(accountIds);
            affiliationaccountIdwithContactId = fetchRelatedPrimaryAffiliations(accountIds);
            contactIds.addAll(affiliationaccountIdwithContactId.values());

        }
       if(!contactIds.isEmpty()){
            associatedContact = fetchConstitiuentDetails(contactIds);
       }
       opportunities = checkPrimaryDonor(opportunities,associatedAccounts, associatedContact,affiliationaccountIdwithContactId);
       for(Opportunity opp:opportunities){
            Oppmap.put(opp.Id,opp);
       }
       lstCreditstoUpdate = fetchCreditstoUpdate(Oppmap, associatedAccounts, associatedContact, lstCreditstoUpdate); 
        try{
            Update opportunities;
        } catch(DmlException e) {
            System.debug('The following exception has occurred: ' + e.getMessage());
            errors.add(e);
        }
		try{
            Update lstCreditstoUpdate;
        } catch(DmlException e) {
            System.debug('The following exception has occurred: ' + e.getMessage());
            errors.add(e);
        }
		
        
    }
    public void finish(Database.BatchableContext bc){
       
    }
    // Method to fetch the primary donor based on affiliations
    public map<Id,Id> fetchRelatedPrimaryAffiliations(Set<Id> accountIds){
        map<Id,Id> accountIdToContactId = new map<Id,Id>();
        for(ucinn_ascendv2__Affiliation__c affiliation: [SELECT Id, ucinn_ascendv2__Contact__c,ucinn_ascendv2__Account__c FROM ucinn_ascendv2__Affiliation__c WHERE ucinn_ascendv2__Account__c IN:accountIds AND HAM_Is_Primary_Donor__c = TRUE ORDER BY LastModifiedDate ASC]){
           if(accountIdToContactId.isEmpty() || !accountIdToContactId.containsKey(affiliation.ucinn_ascendv2__Account__c)){
               accountIdToContactId.put(affiliation.ucinn_ascendv2__Account__c,affiliation.ucinn_ascendv2__Contact__c);
           }
        }
        return accountIdToContactId;
    }
     

   public Map<Id,Contact> fetchConstitiuentDetails(Set<Id> contactIds){
        Map<Id,Contact> associatedContact = new Map<Id, Contact>();
        for(Contact con:[SELECT ID, Name, ucinn_ascendv2__Primary_Contact_Type__c,ucinn_ascendv2__Contact_Type__c, AccountId, Account.ucinn_ascendv2__Primary_Contact__c  FROM Contact WHERE Id IN: contactIds]){
            associatedContact.put(con.Id,con);
        }
        return associatedContact;
    }
    
   
   public Map<Id,Account> fetchAccountDetails(Set<Id> accountIds){
        Map<Id,Account> associatedAccounts = new Map<Id, Account>();
        for(Account acc:[SELECT Id, Name, Type, ucinn_ascendv2__Primary_Contact__c FROM Account WHERE Id IN:accountIds]){
            associatedAccounts.put(acc.Id,acc);
        }
        return associatedAccounts;
    } 
	
	public List<Opportunity> fetchOpportunityDetails(Set<Id> opportunityIds){
        List<Opportunity> associatedOpportunities = new List<Opportunity>();
        associatedOpportunities = [SELECT ID, name, ucinn_ascendv2__Contact__c, AccountId,HAM_Primary_Donor_organization__c,HAM_Primary_Donor__c FROM Opportunity WHERE Id IN:opportunityIds];
        return associatedOpportunities;
    } 
	
	
   
    public List<ucinn_ascendv2__Hard_and_Soft_Credit__c> fetchCreditstoUpdate (Map<id,Opportunity> opportunities, Map<Id,Account> associatedAccounts, Map<Id,Contact> associatedContact, List<ucinn_ascendv2__Hard_and_Soft_Credit__c> lstCreditstoUpdate){
        Set<Id> oppIds = opportunities.keySet();
        //lstCreditstoUpdate = [SELECT Id,ucinn_ascendv2__Opportunity__c, ucinn_ascendv2__Contact__c, ucinn_ascendv2__Account__c,ucinn_ascendv2__Account__r.Type,HAM_Historical_Primary_Donor_Sources__c,HAM_Historical_Is_Primary_Donor__c,HAM_Old_Primary_Donor_Constituent_Type__c, HAM_Is_Primary_Donor__c, HAM_Primary_Donor_Constituent_Type__c, HAM_Primary_Donor_Sources__c FROM ucinn_ascendv2__Hard_and_Soft_Credit__c WHERE ucinn_ascendv2__Opportunity__c IN: oppIds];
        Set<Id> contactIds = new Set<Id>();
        Set<Id> accountIds = new Set<Id>();
        contactIds.addAll(associatedAccounts.keySet());
        accountIds.addAll(associatedContact.keySet());
        for(ucinn_ascendv2__Hard_and_Soft_Credit__c hsCredit :lstCreditstoUpdate){
            if(String.isNotBlank(hsCredit.ucinn_ascendv2__Contact__c)){
                contactIds.add(hsCredit.ucinn_ascendv2__Contact__c);
            }else if(String.isNotBlank(hsCredit.ucinn_ascendv2__Account__c)){
                accountIds.add(hsCredit.ucinn_ascendv2__Account__c);
            }
        }
        if(!accountIds.isEmpty()){
            associatedAccounts = fetchAccountDetails(accountIds);
        }
       if(!contactIds.isEmpty()){
            associatedContact = fetchConstitiuentDetails(contactIds);
       }
        for(ucinn_ascendv2__Hard_and_Soft_Credit__c hsCredit :lstCreditstoUpdate){
            //Update Historical fields
            hsCredit.HAM_Historical_Is_Primary_Donor__c = hsCredit.HAM_Is_Primary_Donor__c;
            hsCredit.HAM_Historical_Primary_Donor_Sources__c = hsCredit.HAM_Primary_Donor_Sources__c;
            hsCredit.HAM_Old_Primary_Donor_Constituent_Type__c = hsCredit.HAM_Primary_Donor_Constituent_Type__c;
            if(opportunities.containsKey(hsCredit.ucinn_ascendv2__Opportunity__c)){
                Opportunity opp = opportunities.get(hsCredit.ucinn_ascendv2__Opportunity__c);
                if(String.isNotBlank(hsCredit.ucinn_ascendv2__Contact__c)){
                    String hsCreditContact = hsCredit.ucinn_ascendv2__Contact__c;
                    if(hsCreditContact.equals(opp.HAM_Primary_Donor__c)){
                        hsCredit.HAM_Is_Primary_Donor__c = TRUE;
                        if(associatedContact.containsKey(opp.HAM_Primary_Donor__c)){
                            Contact tempConstituent = associatedContact.get(opp.HAM_Primary_Donor__c);
                            hsCredit.HAM_Primary_Donor_Constituent_Type__c = tempConstituent.ucinn_ascendv2__Primary_Contact_Type__c;
                            hsCredit.HAM_Primary_Donor_Sources__c = tempConstituent.ucinn_ascendv2__Contact_Type__c;
                        }
                    }
                }else if(String.isNotBlank(hsCredit.ucinn_ascendv2__Account__c)){
                    if(hsCredit.ucinn_ascendv2__Account__c.equals(opp.HAM_Primary_Donor_organization__c)){
                        hsCredit.HAM_Is_Primary_Donor__c = TRUE;
                        if(associatedAccounts.containsKey(opp.HAM_Primary_Donor_organization__c)){
                            Account tempAccount = associatedAccounts.get(opp.HAM_Primary_Donor_organization__c);
                            hsCredit.HAM_Primary_Donor_Constituent_Type__c = tempAccount.Type;
                            hsCredit.HAM_Primary_Donor_Sources__c = tempAccount.Type;
                        }
                    }
                }
            }
        }
        return lstCreditstoUpdate;
    }

   public List<Opportunity> checkPrimaryDonor(List<Opportunity> opportunities, Map<Id,Account> associatedAccounts, Map<Id,Contact> associatedContact, Map<Id,Id> affiliationaccountIdwithContactId){
       

       for(Opportunity opp:opportunities){
            if(String.isNotBlank(opp.AccountId)){
                
                Account objAcc = associatedAccounts.get(opp.AccountId);
                //Account Use Case 1: household account has Primary Contact
                
                if(String.isNotBlank(objAcc.ucinn_ascendv2__Primary_Contact__c)){ 
                    opp.HAM_Primary_Donor__c = objAcc.ucinn_ascendv2__Primary_Contact__c;
                }else{
                    //Account Use Case 2: Charity account has a primary donor affiliation
                    //Account Use Case 3: Charity household account does not have primary donor affiliation
                    if(affiliationaccountIdwithContactId.containsKey(opp.accountId)){
                        opp.HAM_Primary_Donor__c = affiliationaccountIdwithContactId.get(opp.accountId);
                    } else{
                        opp.HAM_Primary_Donor_organization__c = opp.AccountId;
                    }
                }
            }else  if(String.isNotBlank(opp.ucinn_ascendv2__Contact__c)){
                Contact objConsti = associatedContact.get(opp.ucinn_ascendv2__Contact__c);
                // Contact Use Case 1: Household account has primary contact 
                // Contact Use Case 1: Household account doesn't has primary contact
                 if(String.isNotBlank(objConsti.Account.ucinn_ascendv2__Primary_Contact__c)){
                    opp.HAM_Primary_Donor__c = objConsti.Account.ucinn_ascendv2__Primary_Contact__c;
                 }else{
                    opp.HAM_Primary_Donor__c = opp.ucinn_ascendv2__Contact__c;
                 }
            }
       }
       return opportunities;
   }

  
}