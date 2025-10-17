public with sharing class HAMManageSIForIncomingParents implements Database.Batchable<sObject>,  Database.Stateful  {
    Boolean isFallIntake = false;
    Date endDate = Date.today();
    Map<String, ID> mapOfServiceIndicatorIds = new Map<String, ID>();
    
    public Database.QueryLocator start(Database.BatchableContext bc){
        String queryStrNew = 'SELECT Id,Name, ucinn_ascendv2__Primary_Contact_Type__c FROM CONTACT WHERE ucinn_ascendv2__Primary_Contact_Type__c =\'Incoming Parent\' AND CreatedDate = >= LAST_N_DAYS:1 ';
        System.debug('QueryStrNew'+ queryStrNew);
        setEndDateFlag();
        return Database.getQueryLocator(queryStrNew);
    }
    public void execute(Database.BatchableContext bc, List<Contact> lstContacts){
        List<ucinn_ascendv2__Service_Indicator__c> serviceIndicatorsToInsert = new List<ucinn_ascendv2__Service_Indicator__c>();
        for(Contact objContact :lstContacts){
            for(Id serviceIndicatorvalue: mapOfServiceIndicatorIds.values()){
                ucinn_ascendv2__Service_Indicator__c objServiceIndicator = new ucinn_ascendv2__Service_Indicator__c();
                objServiceIndicator.ucinn_ascendv2__Contact__c = objContact.Id;
                objServiceIndicator.ucinn_ascendv2__End_Date__c = endDate;
                objServiceIndicator.ucinn_ascendv2__Service_Indicator_Value__c = serviceIndicatorvalue;
                serviceIndicatorsToInsert.add(objServiceIndicator);
            }
        }
        try{
            insert serviceIndicatorsToInsert;
        }catch(Exception e){
            System.debug('Error occured while inserting Service Indicator Records'+e.getMessage());
        }
    }
    public void finish(Database.BatchableContext bc){}

    public void setEndDateFlag(){
        Integer year = Date.Today().year();
        Date may31st = date.newinstance(year, 5, 31);
        Date aug31st = date.newinstance(year, 8, 31);
        if(Date.Today() > may31st && Date.Today() <= aug31st){
            endDate = Date.newInstance(year, 9, 1);
            isFallIntake = true;
        }else{
            isFallIntake = true;
            endDate = Date.newInstance(year+1, Date.Today().month(), Date.Today().day());
        }
        fillServiceIndicatorMap();
    }

    public void fillServiceIndicatorMap(){
        System.debug('Started');
        List<String> lstServiceIndicatorValues = new List<String>();
        lstServiceIndicatorValues.add('No Solicit Mass Call');
        lstServiceIndicatorValues.add('No Solicit Mass Email');
        lstServiceIndicatorValues.add('No Solicit Mass Text');
        lstServiceIndicatorValues.add('No Solicit Mass Mail');
        for(ucinn_ascendv2__Service_Indicator_Value__c objServiceValue : [SELECT Id, Name FROM ucinn_ascendv2__Service_Indicator_Value__c WHERE Name IN: lstServiceIndicatorValues]){
            mapOfServiceIndicatorIds.put(objServiceValue.name, objServiceValue.Id);
        }
    }
}