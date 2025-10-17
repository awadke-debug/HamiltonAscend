public with sharing class HAMPopulatePrimaryDonorAndHardCredits implements Database.Batchable<sObject>,  Database.Stateful {
    List<DmlException> errors = new List<DmlException>(); 

    public Database.QueryLocator start(Database.BatchableContext bc){
        return Database.getQueryLocator([SELECT ID, Name, HAM_Primary_Donor_Count__c, HAM_Hard_Credit_Count__c,HAM_Soft_Credit_Count__c FROM Opportunity]);
    }
    public void execute(Database.BatchableContext bc, List<Opportunity> opportunities){
        Map<Id,Opportunity> mapOpportuniy = new Map<id, Opportunity>(opportunities);
        List<Opportunity> updatePrimaryDonor = new List<Opportunity>();
        
        List<ucinn_ascendv2__Hard_and_Soft_Credit__c > lstOppCredits = new List<ucinn_ascendv2__Hard_and_Soft_Credit__c>();
        lstOppCredits = [SELECT ID,ucinn_ascendv2__Credit_Type__c, ucinn_ascendv2__Opportunity__c,HAM_Is_Primary_Donor__c,ucinn_ascendv2__Contact__c,ucinn_ascendv2__Account__c FROM ucinn_ascendv2__Hard_and_Soft_Credit__c WHERE ucinn_ascendv2__Opportunity__c IN: opportunities];
        //Create a map of opportunity and its credits
        Map<Id,List<ucinn_ascendv2__Hard_and_Soft_Credit__c>> mapOppCredits = new Map<Id,List<ucinn_ascendv2__Hard_and_Soft_Credit__c>>();
        Map<Id,Integer> mapOppPrimaryDonors = new Map<Id,Integer>();
        Map<Id,Integer> mapOppHardCredits = new Map<Id,Integer>();
        for(ucinn_ascendv2__Hard_and_Soft_Credit__c objOppCredit : lstOppCredits){
            if(mapOppCredits.containsKey(objOppCredit.ucinn_ascendv2__Opportunity__c)){
                mapOppCredits.get(objOppCredit.ucinn_ascendv2__Opportunity__c).add(objOppCredit);
            }else{
                mapOppCredits.put(objOppCredit.ucinn_ascendv2__Opportunity__c, new List<ucinn_ascendv2__Hard_and_Soft_Credit__c>{objOppCredit});
            } 
        }

        for(Id oppId : mapOppCredits.keySet()){
           
            Opportunity objOpp = mapOpportuniy.get(oppId);
            Integer hardCreditCount = 0;
            Integer softCreditCount = 0;
            Integer primaryDonorCount = 0;
            for(ucinn_ascendv2__Hard_and_Soft_Credit__c objOppCredit : mapOppCredits.get(oppId)){
                if(objOppCredit.ucinn_ascendv2__Credit_Type__c.equalsIgnoreCase('Hard')){
                    hardCreditCount++;
                }else if(objOppCredit.ucinn_ascendv2__Credit_Type__c.equalsIgnoreCase('Soft')){
                    softCreditCount++;
                }
                if(objOppCredit.HAM_Is_Primary_Donor__c){
                    primaryDonorCount++;
                }
            }
            objOpp.HAM_Primary_Donor_Count__c = primaryDonorCount;
            objOpp.HAM_Hard_Credit_Count__c = hardCreditCount;
            objOpp.HAM_Soft_Credit_Count__c = softCreditCount;
            updatePrimaryDonor.add(objOpp);
        }

        //Finally update the opportunites with issue.
        if(!updatePrimaryDonor.isEmpty()){
            try{
                update updatePrimaryDonor;
            }catch(DmlException e) {
                System.debug('The following exception has occurred: ' + e.getMessage());
                errors.add(e);
            }
        }
         
    }
    
    public void finish(Database.BatchableContext bc){}
}