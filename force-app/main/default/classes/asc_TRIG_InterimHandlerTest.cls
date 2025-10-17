@isTest
public with sharing class asc_TRIG_InterimHandlerTest {
    @TestSetup
    static void createTriggerHandlerRecord(){
        // Turn on TDTM Trigger
        ucinn_ascendv2__Trigger_Handler__c asc_TRIG_InterimHandler = new ucinn_ascendv2__Trigger_Handler__c();
        asc_TRIG_InterimHandler.Name = 'TRIG_Interim';
        asc_TRIG_InterimHandler.ucinn_ascendv2__Class__c = 'asc_TRIG_InterimHandler';
        asc_TRIG_InterimHandler.ucinn_ascendv2__Is_Active__c = true;
        asc_TRIG_InterimHandler.ucinn_ascendv2__Is_Asynchronous__c = false;
        asc_TRIG_InterimHandler.ucinn_ascendv2__Is_User_Managed__c = true;
        asc_TRIG_InterimHandler.ucinn_ascendv2__Load_Order__c = 2.0;
        asc_TRIG_InterimHandler.ucinn_ascendv2__Object__c = 'ucinn_ascendv2__Interim__c';
        asc_TRIG_InterimHandler.ucinn_ascendv2__Trigger_Action__c = 'BeforeInsert;BeforeUpdate;BeforeDelete;AfterInsert;AfterUpdate;AfterDelete;AfterUndelete';
        insert asc_TRIG_InterimHandler;

        
        
        ucinn_ascendv2__Trigger_Handler__c nameHandler = new ucinn_ascendv2__Trigger_Handler__c();
        nameHandler.Name = 'Name Handler';
        nameHandler.ucinn_ascendv2__Class__c = 'ascend_TRIG_NameHandler';
        nameHandler.ucinn_ascendv2__Is_Active__c = true;
        nameHandler.ucinn_ascendv2__Owned_by_Namespace__c = 'ucinn_ascendv2';
        nameHandler.ucinn_ascendv2__Object__c = 'ucinn_ascendv2__Contact_Name__c';
        nameHandler.ucinn_ascendv2__Trigger_Action__c = 'BeforeInsert;BeforeUpdate;BeforeDelete;AfterInsert;AfterUpdate;AfterDelete;AfterUndelete';
        nameHandler.ucinn_ascendv2__Load_Order__c = 1;
        insert nameHandler;
        
        insert new Account(
            Name = 'Test University',
            BillingStreet = '1 Test St',
            BillingCity = '1 City of Test',
            BillingCountry = 'United States'
        );
    }

    

    
    
   
    @isTest
    public static void testUpdteContactNames() {
        Contact testContact = new Contact();
        testContact.FirstName = 'Contact';
        testContact.LastName = 'Test';
        testContact.ucinn_ascendv2__Contact_Type__c = 'Friend';
        testContact.Email = 'sample1@uci.com';
        insert testContact;
        
        Contact testContact1 = new Contact();
        testContact1.FirstName = 'Contact1';
        testContact1.LastName = 'Test1';
        testContact1.ucinn_ascendv2__Contact_Type__c = 'Friend';
        testContact1.Email = 'sample2@uci.com';
        insert testContact1;

        List<ucinn_ascendv2__Contact_Name__c> contactNameList = new List<ucinn_ascendv2__Contact_Name__c>();
        ucinn_ascendv2__Contact_Name__c name1 = new ucinn_ascendv2__Contact_Name__c();
        name1.Name = '[Default Name]';
        name1.ucinn_ascendv2__Contact__c = testContact.Id;
        name1.ucinn_ascendv2__First_Name__c = 'Contact';
        name1.ucinn_ascendv2__Last_Name__c = 'Test';
        name1.ucinn_ascendv2__Type__c = 'Full Name';
        contactNameList.add(name1);
        ucinn_ascendv2__Contact_Name__c name2 = new ucinn_ascendv2__Contact_Name__c();
        name2.Name = '[Default Name]';
        name2.ucinn_ascendv2__Contact__c = testContact.Id;
        name2.ucinn_ascendv2__First_Name__c = 'Cont';
        name2.ucinn_ascendv2__Last_Name__c = 'Test';
        name2.ucinn_ascendv2__Type__c = 'Birth';
        contactNameList.add(name2);
        insert contactNameList;
        System.debug('contactNameList[' + contactNameList.size() + ']=' + contactNameList);

        ucinn_ascendv2__Interim__c interim = new ucinn_ascendv2__Interim__c();
        interim.RecordTypeId = Schema.SObjectType.ucinn_ascendv2__Interim__c.getRecordTypeInfosByDeveloperName().get('SIS_Interface').getRecordTypeId();
        interim.Name = 'INT-1234';
        interim.ucinn_ascendv2__Status__c = 'New';
        interim.ucinn_ascendv2__External_System_ID__c = 'STRC-TestInterim';
        interim.ucinn_ascendv2__Contact__c = testContact.Id;
        interim.HAM_Preferred_Name_Prefix__c = 'Prefer';
        interim.HAM_Preferred_Name_First_Name__c = 'Prefer';
        interim.HAM_Preferred_Name_Last_Name__c = 'Prefer';     
        interim.HAM_Legal_Name_Last_Name__c = 'Legal';
        interim.HAM_Legal_Name_First_Name__c = 'Legal';
        interim.HAM_Chosen_Name_First_Name__c = 'Chosen';
        interim.HAM_Chosen_Name_Last_Name__c = 'Chosen';
        interim.HAM_Birth_Name_First_Name__c = 'Birth';
        interim.HAM_Birth_Name_Last_Name__c = 'Birth';

        insert interim;
        
       

        ucinn_ascendv2.ascend_UTIL_TDTMTrigger.toggleTDTMTrigger('ucinn_ascendv2__Contact_Name__c', false);
        interim.ucinn_ascendv2__Status__c = 'Completed';
        update interim;       
        ucinn_ascendv2.ascend_UTIL_TDTMTrigger.toggleTDTMTrigger('ucinn_ascendv2__Contact_Name__c', true);
    }
    
    
    
    
}