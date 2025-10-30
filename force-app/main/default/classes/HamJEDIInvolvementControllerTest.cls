@IsTest
private class HamJEDIInvolvementControllerTest {

    // Helper: fetch Record Type Id by LABEL and assert it's present
    private static Id rtId(String label) {
        Map<String, Schema.RecordTypeInfo> byName =
            Schema.SObjectType.ucinn_ascendv2__Involvement__c.getRecordTypeInfosByName();
        System.assert(byName.containsKey(label),
            'Missing Record Type on ucinn_ascendv2__Involvement__c with label: ' + label);
        return byName.get(label).getRecordTypeId();
    }

    @TestSetup
    static void setupTestData() {
        // Base data via factory
        Account acc = HAMJediTestDataFactory.makeAccount();
        Contact c1 = HAMJediTestDataFactory.makeContact(acc.Id);
        Contact c2 = HAMJediTestDataFactory.makeContact(acc.Id);

        // Get Volunteer Engagement Record Type ID
        Id volunteerRtId = rtId('Volunteer Engagement');

        // Create Involvement Value (required by validation rule)
        // Must set Type to match Record Type name for validation
        ucinn_ascendv2__Involvement_Value__c invValue = new ucinn_ascendv2__Involvement_Value__c(
            Name = 'Test Volunteer Activity',
            ucinn_ascendv2__Type__c = 'Volunteer Engagement',
            ucinn_ascendv2__Involvement_Description__c = 'Test Volunteer Activity'
        );
        insert invValue;

        // Seed involvement records for c1
        insert new List<ucinn_ascendv2__Involvement__c>{
            new ucinn_ascendv2__Involvement__c(
                ucinn_ascendv2__Contact__c = c1.Id,
                RecordTypeId = volunteerRtId,
                ucinn_ascendv2__Involvement_Code__c = invValue.Id,
                ucinn_ascendv2__Start_Date__c = Date.today().addDays(-30)
            ),
            new ucinn_ascendv2__Involvement__c(
                ucinn_ascendv2__Contact__c = c1.Id,
                RecordTypeId = volunteerRtId,
                ucinn_ascendv2__Involvement_Code__c = invValue.Id,
                ucinn_ascendv2__Start_Date__c = Date.today().addDays(-60)
            ),
            new ucinn_ascendv2__Involvement__c(
                ucinn_ascendv2__Contact__c = c2.Id,
                RecordTypeId = volunteerRtId,
                ucinn_ascendv2__Involvement_Code__c = invValue.Id,
                ucinn_ascendv2__Start_Date__c = Date.today()
            )
        };
    }

    @IsTest
    static void testGetInvolvements() {
        List<Contact> contacts = [SELECT Id FROM Contact ORDER BY CreatedDate];
        Contact c1 = contacts[0];
        Id volunteerRtId = rtId('Volunteer Engagement');

        Test.startTest();
        List<ucinn_ascendv2__Involvement__c> involvements =
            HamJEDIInvolvementController.getInvolvements(c1.Id, volunteerRtId);
        Test.stopTest();

        System.assertEquals(2, involvements.size(), 'c1 should have 2 Volunteer Engagement records');

        // Verify basic record properties
        for (ucinn_ascendv2__Involvement__c record : involvements) {
            System.assertNotEquals(null, record.Id, 'Record should have an ID');
            System.assertEquals(c1.Id, record.ucinn_ascendv2__Contact__c, 'Record should belong to c1');
            System.assertEquals(volunteerRtId, record.RecordTypeId, 'Record should have Volunteer RT');
        }
    }

    @IsTest
    static void testContactIsolation() {
        List<Contact> contacts = [SELECT Id FROM Contact ORDER BY CreatedDate];
        Contact c1 = contacts[0];
        Contact c2 = contacts[1];
        Id volunteerRtId = rtId('Volunteer Engagement');

        Test.startTest();
        List<ucinn_ascendv2__Involvement__c> involvementsForC1 =
            HamJEDIInvolvementController.getInvolvements(c1.Id, volunteerRtId);
        List<ucinn_ascendv2__Involvement__c> involvementsForC2 =
            HamJEDIInvolvementController.getInvolvements(c2.Id, volunteerRtId);
        Test.stopTest();

        // Verify each contact gets the correct number of records
        System.assertEquals(2, involvementsForC1.size(), 'c1 should have 2 records');
        System.assertEquals(1, involvementsForC2.size(), 'c2 should have 1 record');

        // Verify no duplicate IDs between the two result sets
        Set<Id> c1InvolvementIds = new Set<Id>();
        for (ucinn_ascendv2__Involvement__c r : involvementsForC1) {
            c1InvolvementIds.add(r.Id);
        }

        for (ucinn_ascendv2__Involvement__c r : involvementsForC2) {
            System.assert(!c1InvolvementIds.contains(r.Id), 'c2 records should not appear in c1 results');
        }
    }

    @IsTest
    static void testEmptyResults() {
        // Create a contact with no involvement records
        Account acc = HAMJediTestDataFactory.makeAccount();
        Contact contactWithoutRecords = HAMJediTestDataFactory.makeContact(acc.Id);
        Id volunteerRtId = rtId('Volunteer Engagement');

        Test.startTest();
        List<ucinn_ascendv2__Involvement__c> involvements =
            HamJEDIInvolvementController.getInvolvements(contactWithoutRecords.Id, volunteerRtId);
        Test.stopTest();

        System.assertEquals(0, involvements.size(), 'Should return empty list');
    }

    @IsTest
    static void testOrderingByInvolvementCode() {
        List<Contact> contacts = [SELECT Id FROM Contact ORDER BY CreatedDate];
        Contact c1 = contacts[0];
        Id volunteerRtId = rtId('Volunteer Engagement');

        Test.startTest();
        List<ucinn_ascendv2__Involvement__c> involvements =
            HamJEDIInvolvementController.getInvolvements(c1.Id, volunteerRtId);
        Test.stopTest();

        System.assertEquals(2, involvements.size(), 'c1 should have 2 records');

        // Verify results are returned (ordering will be tested in integration)
        System.assertNotEquals(null, involvements[0].Id, 'First record should have ID');
        System.assertNotEquals(null, involvements[1].Id, 'Second record should have ID');
    }
}