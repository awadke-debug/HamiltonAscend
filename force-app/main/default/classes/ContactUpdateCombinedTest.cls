@isTest
public class ContactUpdateCombinedTest {

    @testsetup static void setup(){
        Contact con1 = new Contact(FirstName = 'Test',
                                 LastName = 'Data1',
                                 ucinn_ascendv2__Contact_Type__c = 'Surviving Spouse;Past Parent;Grandparent');
        Contact con2 = new Contact(FirstName = 'Test',
                                 LastName = 'Data2',
                                 ucinn_ascendv2__Contact_Type__c = 'Grandparent');
        insert con1;
        insert con2;
        System.debug('CONTACTS::::'+con1.Id);
        Id recordTypeId = Schema.SObjectType.ucinn_ascendv2__Degree_Information__c.getRecordTypeInfosByDeveloperName().get('School_Degree_Information').getRecordTypeId();
        ucinn_ascendv2__Degree_Information__c degInfo1 = new ucinn_ascendv2__Degree_Information__c(Name = 'DEG-1000001',
                                                                                                 RecordTypeId = recordTypeId,
                                                                                                 ucinn_ascendv2__Contact__c = con1.Id,
                                                                                                 ucinn_ascendv2__Reunion_Year__c = '2023');
        ucinn_ascendv2__Degree_Information__c degInfo2 = new ucinn_ascendv2__Degree_Information__c(Name = 'DEG-1000002',
                                                                                                 RecordTypeId = recordTypeId,
                                                                                                 ucinn_ascendv2__Contact__c = con1.Id,
                                                                                                 ucinn_ascendv2__Reunion_Year__c = '2022');
        
        
        insert degInfo1;
        insert degInfo2;
        List<Id> degIds = new List<Id>();
        degIds.add(degInfo1.Id);
        degIds.add(degInfo2.Id);
        System.debug('degInfo');
        List<ucinn_ascendv2__Degree_Information__c> degRecs = new List<ucinn_ascendv2__Degree_Information__c>([Select Id, HAM_Reunion_Integer_Date_Formula__c from ucinn_ascendv2__Degree_Information__c where Id In :degIds]);
        
        ucinn_ascendv2__Reciprocal_Relationships__c rr1 = new ucinn_ascendv2__Reciprocal_Relationships__c (Name='Parent', ucinn_ascendv2__Reciprocal__c = 'Parent');
        ucinn_ascendv2__Reciprocal_Relationships__c rr2 = new ucinn_ascendv2__Reciprocal_Relationships__c (Name='Child', ucinn_ascendv2__Reciprocal__c = 'Child');
        ucinn_ascendv2__Reciprocal_Relationships__c rr3 = new ucinn_ascendv2__Reciprocal_Relationships__c (Name='Grandparent', ucinn_ascendv2__Reciprocal__c = 'Grandparent');
        ucinn_ascendv2__Reciprocal_Relationships__c rr4 = new ucinn_ascendv2__Reciprocal_Relationships__c (Name='Grandchild', ucinn_ascendv2__Reciprocal__c = 'Grandchild');
        ucinn_ascendv2__Reciprocal_Relationships__c rr5 = new ucinn_ascendv2__Reciprocal_Relationships__c (Name='Deceased Spouse', ucinn_ascendv2__Reciprocal__c = 'Deceased Spouse');
        ucinn_ascendv2__Reciprocal_Relationships__c rr6 = new ucinn_ascendv2__Reciprocal_Relationships__c (Name='Widow', ucinn_ascendv2__Reciprocal__c = 'Widow');
        insert rr1;
        insert rr2;
        insert rr3;
        insert rr4;
        insert rr5;
        insert rr6;
        
        ucinn_ascendv2__Relationship__c rel1 = new ucinn_ascendv2__Relationship__c(ucinn_ascendv2__Related_Contact__c = con2.Id,
                                                                                 ucinn_ascendv2__Contact__c = con1.Id,
                                                                                 ucinn_ascendv2__Related_Contact_Role__c = 'Child');	  
        ucinn_ascendv2__Relationship__c rel2 = new ucinn_ascendv2__Relationship__c(ucinn_ascendv2__Related_Contact__c = con2.Id,
                                                                                 ucinn_ascendv2__Contact__c = con1.Id,
                                                                                 ucinn_ascendv2__Related_Contact_Role__c = 'Grandchild');
        ucinn_ascendv2__Relationship__c rel3 = new ucinn_ascendv2__Relationship__c(ucinn_ascendv2__Related_Contact__c = con2.Id,
                                                                                 ucinn_ascendv2__Contact__c = con1.Id,
                                                                                 ucinn_ascendv2__Related_Contact_Role__c = 'Deceased Spouse');

        List<ucinn_ascendv2__Relationship__c> relRecs = new List<ucinn_ascendv2__Relationship__c>();
        relRecs.add(rel1);
        relRecs.add(rel2);
        relRecs.add(rel3);
        insert relRecs;
    }	
    
	@isTest static void contactUpdateCombinedTestMethod(){
        Contact con1 = [Select Id,ucinn_ascendv2__Contact_Type__c from Contact where LastName = 'Data1' Limit 1];
        con1.LastName = 'Updated Data1';
        Test.startTest();
        update con1;
        Test.stopTest();
        System.debug('Update::'+con1);
        Contact con2 = [Select Id,ucinn_ascendv2__Contact_Type__c from Contact where LastName = 'Data2' Limit 1];
        con2.LastName = 'Updated Data';
        update con2;
        
    }
    
}