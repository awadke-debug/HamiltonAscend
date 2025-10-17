@isTest
private class ConsecutiveGivingTriggerTest {

    @isTest static void testConsecutiveGivingUpdate() {
        // Setup - create a test session
        ucinn_ascendv2__Session__c session = new ucinn_ascendv2__Session__c(
            ucinn_ascendv2__Session_Totals_Approved__c = DateTime.newInstance(2023, 3, 16, 22, 12, 28),
            ucinn_ascendv2__Session_Date__c = Date.newInstance(2023, 3, 13)
        );
        insert session;

        // Prepare the session update to trigger the logic
        ucinn_ascendv2__Session__c updatedSession = [SELECT Id, ucinn_ascendv2__Session_Totals_Approved__c FROM ucinn_ascendv2__Session__c WHERE Id = :session.Id LIMIT 1];
        updatedSession.ucinn_ascendv2__Session_Totals_Approved__c = DateTime.newInstance(2023, 3, 16, 22, 15, 30); // Adjusting the time for the test
        Test.startTest();
        update updatedSession;
        Test.stopTest();

        // Assertions to verify the expected outcomes of the trigger's execution can be added here
    }
}