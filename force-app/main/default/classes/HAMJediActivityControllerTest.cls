@IsTest
private class HAMJediActivityControllerTest {

    @TestSetup
    static void setupData() {
        // Create test data
        Account a = HAMJediTestDataFactory.makeAccount();
        Contact c = HAMJediTestDataFactory.makeContact(a.Id);
        HAMJediTestDataFactory.seedBasicActivityDataset(c.Id);
    }

    @IsTest
    static void testGetActivityDetails() {
        // Get the test contact
        Contact con = [SELECT Id FROM Contact LIMIT 1];

        // Call the method we're testing
        Test.startTest();
        HAMJediActivityController.ActivityWrapper wrap =
            HAMJediActivityController.getactivityDetails(con.Id);
        Test.stopTest();

        // Check that we got data back
        System.assertNotEquals(null, wrap);
        System.assertNotEquals(null, wrap.upcomingMeeting);
        System.assertNotEquals(null, wrap.pastMeeting);
        System.assertNotEquals(null, wrap.rejectedMeeting);
        System.assertNotEquals(null, wrap.dueTask);

        // Check the counts match what we created
        System.assertEquals(1, wrap.pastMeeting.size());
        System.assertEquals(1, wrap.rejectedMeeting.size());
        System.assertEquals(1, wrap.upcomingMeeting.size());
        System.assert(wrap.dueTask.size() >= 1);
    }

    //Test with No Activities
    @IsTest
    static void testGetActivityDetails_NoActivities() {
        // Create contact WITHOUT activities
        Account a = HAMJediTestDataFactory.makeAccount();
        Contact con = HAMJediTestDataFactory.makeContact(a.Id);
        // NOT calling seedBasicActivityDataset - no activities created
        
        // Test
        Test.startTest();
        HAMJediActivityController.ActivityWrapper wrap =
            HAMJediActivityController.getactivityDetails(con.Id);
        Test.stopTest();
        
        // Verify empty lists
        System.assertNotEquals(null, wrap);
        System.assertEquals(0, wrap.upcomingMeeting.size());
        System.assertEquals(0, wrap.pastMeeting.size());
        System.assertEquals(0, wrap.rejectedMeeting.size());
        System.assertEquals(0, wrap.dueTask.size());
    }

    //Test with Multiple Activities
    @IsTest
    static void testGetActivityDetails_MultipleActivities() {
        // Create contact
        Account a = HAMJediTestDataFactory.makeAccount();
        Contact con = HAMJediTestDataFactory.makeContact(a.Id);
        
        // Create multiple activities of each type
        Datetime now = System.now();
        for (Integer i = 1; i <= 3; i++) {
            HAMJediTestDataFactory.makeCompletedEvent(con.Id, now.addDays(-i));
            HAMJediTestDataFactory.makeCancelledEvent(con.Id, now.addDays(i));
            HAMJediTestDataFactory.makePlannedEvent(con.Id, now.addDays(i + 3));
            HAMJediTestDataFactory.makeOpenTask(con.Id, Date.today().addDays(i));
        }
        
        // Test
        Test.startTest();
        HAMJediActivityController.ActivityWrapper wrap =
            HAMJediActivityController.getactivityDetails(con.Id);
        Test.stopTest();
        
        // Verify multiple records returned
        System.assertEquals(3, wrap.pastMeeting.size());
        System.assertEquals(3, wrap.rejectedMeeting.size());
        System.assertEquals(3, wrap.upcomingMeeting.size());
        System.assert(wrap.dueTask.size() >= 3);
    }

    //Test with Invalid Contact ID
    @IsTest
    static void testGetActivityDetails_InvalidId() {
        // Create fake ID
        Id fakeId = Contact.sObjectType.getDescribe().getKeyPrefix() + '000000000000';
        
        // Test
        Test.startTest();
        HAMJediActivityController.ActivityWrapper wrap =
            HAMJediActivityController.getactivityDetails(fakeId);
        Test.stopTest();
        
        // Should return empty wrapper
        System.assertNotEquals(null, wrap);
        System.assertEquals(0, wrap.upcomingMeeting.size());
        System.assertEquals(0, wrap.pastMeeting.size());
        System.assertEquals(0, wrap.rejectedMeeting.size());
        System.assertEquals(0, wrap.dueTask.size());
    }

    //Test with Null Contact ID 
    @IsTest
    static void testGetActivityDetails_NullId() {
        // Your controller doesn't check for null, so it will run queries with null
        // This will find records where WhoId IS NULL
        
        // Test with null
        Test.startTest();
        HAMJediActivityController.ActivityWrapper wrap =
            HAMJediActivityController.getactivityDetails(null);
        Test.stopTest();
        
        // Should return wrapper with lists initialized
        System.assertNotEquals(null, wrap);
        System.assertNotEquals(null, wrap.upcomingMeeting);
        System.assertNotEquals(null, wrap.pastMeeting);
        System.assertNotEquals(null, wrap.rejectedMeeting);
        System.assertNotEquals(null, wrap.dueTask);
        
        // The controller will query for records where WhoId = null (IS NULL)
        // Your test data has all activities linked to a contact, so no orphaned records
        // EXCEPT: The task query also checks HAM_Contact_Report__r.ucinn_ascendv2__Contact__c
        // which might find orphaned tasks
        
        // These should be 0 (no orphaned events in test data)
        System.assertEquals(0, wrap.upcomingMeeting.size());
        System.assertEquals(0, wrap.pastMeeting.size());
        System.assertEquals(0, wrap.rejectedMeeting.size());
        
        // Tasks might find orphaned records due to the OR condition
        // Just check it doesn't error out
        System.assertNotEquals(null, wrap.dueTask);
    }
}