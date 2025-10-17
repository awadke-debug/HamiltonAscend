@isTest
public class ConsecutiveGivingCalculatorTest {
    @isTest
    public static void givingCalcTestMethod(){
        //Create Test Data
        Account acc = new Account(Name = 'TestAcc');
        insert acc;
        Id designationRecordTypeId = Schema.SObjectType.ucinn_ascendv2__Designation__c.getRecordTypeInfosByDeveloperName().get('HAM_Gift_Designation').getRecordTypeId();
        ucinn_ascendv2__Designation__c desg = new ucinn_ascendv2__Designation__c(Name = 'Test Fund',
                                                                           RecordTypeId = designationRecordTypeId,
                                                                           ucinn_ascendv2__G_L_Effective_Date__c = Date.newInstance(2008, 03, 03),
                                                                           ucinn_ascendv2__G_L_Account__c = '1234567898765',
                                                                           ucinn_ascendv2__Designation_Name__c = 'Test Fund',
                                                                           ucinn_ascendv2__CASE_Purpose_v1__c = 'Financial Aid');
        insert desg;
        Opportunity opp = new Opportunity(Name = 'RN0000130',
                                         CloseDate = Date.newInstance(2024, 06, 09),
                                         StageName = 'Active',
                                         ucinn_ascendv2__Credit_Date__c = Date.newInstance(2023, 06,20));
        insert opp;
        Contact con = new Contact(FirstName = 'Test',
                                 LastName = 'Data',
                                 ucinn_ascendv2__Contact_Type__c = 'Hamilton Alumni');
        insert con;
        ucinn_ascendv2__Session__c sessionRec = new ucinn_ascendv2__Session__c(Name = 'S5311210148', 
                                                                            ucinn_ascendv2__Session_Date__c = Date.newInstance(2023, 11, 21));
        insert sessionRec;
        List<Id> sessionIds = new List<Id>();
        sessionIds.add(sessionRec.Id);
        ucinn_ascendv2__Designation_Detail__c newDD = new ucinn_ascendv2__Designation_Detail__c(Name = 'DD-1000051', ucinn_ascendv2__Opportunity__c = opp.Id,
                                                                                               ucinn_ascendv2__Designation__c = desg.Id);
        insert newDD;
        ucinn_ascendv2__Payment__c paymentRec = new ucinn_ascendv2__Payment__c(Name = 'T0001292',
                                                                           ucinn_ascendv2__Session__c = sessionRec.Id,
                                                                           ucinn_ascendv2__Contact__c = con.Id,
                                                                           ucinn_ascendv2__Account__c = acc.Id,
                                                                           ucinn_ascendv2__Designation_Detail__c = newDD.Id,
                                                                           ucinn_ascendv2__Transaction_Type__c = 'Pledge Payment',
                                                                           ucinn_ascendv2__Credit_Date__c = Date.newInstance(2023, 05, 01));
        insert paymentRec;
        ucinn_ascendv2__Hard_and_Soft_Credit__c hsRec = new ucinn_ascendv2__Hard_and_Soft_Credit__c(Name = 'Credit-231121-1173',
                                                                                                    ucinn_ascendv2__Credit_Type__c = 'Hard',
                                                                                                   ucinn_ascendv2__Contact__c = con.Id,
                                                                                                   ucinn_ascendv2__Source__c = 'Payment',
                                                                                                   ucinn_ascendv2__Designation_Detail__c = newDD.Id,
                                                                                                   ucinn_ascendv2__Payment__c = paymentRec.Id);
        insert hsRec;
        System.debug('Credit Date formula::'+ hsRec.ucinn_ascendv2__Credit_Date_Formula__c);
        ucinn_ascendv2__Hard_and_Soft_Credit__c hs = [Select ID, Name,ucinn_ascendv2__Gift_Type_Formula__c, ucinn_ascendv2__Credit_Date_Formula__c from ucinn_ascendv2__Hard_and_Soft_Credit__c where id =: hsRec.Id limit 1][0];                                                                                         
        System.debug('payment transaction type::'+paymentRec.ucinn_ascendv2__Transaction_Type__c+hs.ucinn_ascendv2__Gift_Type_Formula__c);
        Test.startTest();
        ConsecutiveGivingCalculator.calculateConsecutiveGiving(sessionIds);
        ConsecutiveGivingCalculatorOrganization.calculateConsecutiveGiving(sessionIds);
        Test.stopTest();
    }
}