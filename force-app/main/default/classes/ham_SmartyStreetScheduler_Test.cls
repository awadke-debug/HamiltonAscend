@isTest
public class ham_SmartyStreetScheduler_Test {
    @isTest
    static void testScheduledJob() {
        
        Test.startTest();
        ham_SmartyStreetScheduler newscheduler = new ham_SmartyStreetScheduler();
        Set<String> matchCodeSet = new Set<String>{'Y'};
        Set<String> vacantSet = new Set<String>{'N'};
        Set<String> verificationStatusSet = new Set<String>{'Verified'};
        Set<String> addressPrecisionSet = new Set<String>{'Premise', 'DeliveryPoint'};
        Map<String, Set<String>> usParam = new Map<String, Set<String>>();
        usParam.put('ucinn_ascendv2__DPV_Match_Code__c', matchCodeSet);
        usParam.put('ucinn_ascendv2__DPV_Vacant__c', vacantSet);
        Map<String, Set<String>> internationalParam = new Map<String, Set<String>>();
        internationalParam.put('ucinn_ascendv2__Verification_Status__c', verificationStatusSet);
        internationalParam.put('ucinn_ascendv2__Address_Precision__c', addressPrecisionSet);
        String whereClause = 'ucinn_ascendv2__Is_Verified__c = false';
        Integer batchSize = 200;
        newscheduler.whereClause = whereClause;
        newscheduler.usParam = usParam;
        newscheduler.internationalParam = internationalParam;
        newscheduler.batchSize = batchSize;
        String CRON_VAL = ' 0 0 0 15 3 ? 2080';
        String jobId = System.schedule('Smarty Street Job Testclass', CRON_VAL, newscheduler);
        Test.stopTest();
    }
}