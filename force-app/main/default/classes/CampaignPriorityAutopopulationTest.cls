@isTest
public class CampaignPriorityAutopopulationTest {
    static testMethod void cpaTestMethod(){
        Id designationRecordTypeId = Schema.SObjectType.ucinn_ascendv2__Designation__c.getRecordTypeInfosByDeveloperName().get('HAM_Gift_Designation').getRecordTypeId();
       	ucinn_ascendv2__Designation__c desg = new ucinn_ascendv2__Designation__c(Name = 'Test Fund',
                                                                           RecordTypeId = designationRecordTypeId,
                                                                           ucinn_ascendv2__G_L_Effective_Date__c = Date.newInstance(2008, 03, 03),
                                                                           ucinn_ascendv2__G_L_Account__c = '1234567898765',
                                                                           ucinn_ascendv2__Designation_Name__c = 'Test Fund',
                                                                           ucinn_ascendv2__CASE_Purpose_v1__c = 'Financial Aid');
        insert desg;
        Id campaignRecordTypeId = Schema.SObjectType.Campaign.getRecordTypeInfosByDeveloperName().get('Comprehensive_Campaign').getRecordTypeId();
        Campaign cp1 = new Campaign(Name = 'Test1',
                                  EndDate = Date.newInstance(2017, 06, 30),
                                  StartDate = Date.newInstance(2012, 06, 30),
                                  Status = 'Completed',
                                  Type = 'Initiative',
                                  RecordTypeId = campaignRecordTypeId);
        Campaign cp2 = new Campaign(Name = 'Test2',
                                  EndDate = Date.newInstance(2017, 06, 28),
                                  StartDate = Date.newInstance(2017, 06, 27),
                                  Status = 'Completed',
                                  Type = 'Initiative',
                                  RecordTypeId = campaignRecordTypeId);
        insert cp1;
        insert cp2;
        HAM_Designation_Priority__c dp1 = new HAM_Designation_Priority__c(HAM_Designation__c = desg.Id,
                                                                        HAM_Campaign_Priority__c = cp1.Id); 
        HAM_Designation_Priority__c dp2 = new HAM_Designation_Priority__c(HAM_Designation__c = desg.Id,
                                                                        HAM_Campaign_Priority__c = cp2.Id); 
        insert dp1;
        insert dp2;
        Opportunity opp = new Opportunity(Name = 'RN0000130',
                                         CloseDate = Date.newInstance(2024, 06, 09),
                                         StageName = 'Active',
                                         ucinn_ascendv2__Credit_Date__c = Date.newInstance(2023, 06,20));
        insert opp;
        ucinn_ascendv2__Designation_Detail__c newDD = new ucinn_ascendv2__Designation_Detail__c(Name = 'DD-1000051', ucinn_ascendv2__Opportunity__c = opp.Id,
                                                                                               ucinn_ascendv2__Designation__c = desg.Id);
        insert newDD;
        ucinn_ascendv2__Designation_Detail__c dd = [Select ID, Name, ucinn_ascendv2__Pledge_Date_Formula__c from ucinn_ascendv2__Designation_Detail__c where id =: newDD.id];
        System.debug('Opp Credit Date::'+opp.ucinn_ascendv2__Credit_Date__c + 'Opp Id:::'+opp.Id);
        System.debug('Pledge Date::'+dd.ucinn_ascendv2__Pledge_Date_Formula__c);
        System.debug('Id::'+dd.Id);
        DateTime now = DateTime.NOW(); // Get current date and time in the local time zone
		
        Test.setCreatedDate(dd.Id, DateTime.newInstance(now.year(),now.month(),now.day()-1,now.hour(),now.minute(),now.second()));

        String timing = '0 0 10 ? * MON-FRI';
        test.startTest();
        CampaignPriorityAutopopulation cpa = new CampaignPriorityAutopopulation();
        system.schedule('Test Sched', timing, cpa);
        test.stopTest();
    }

}