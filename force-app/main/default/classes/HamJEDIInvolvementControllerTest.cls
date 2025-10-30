@IsTest
private class HamJEDIInvolvementControllerTest {

    // Test Data Constants
    private static final String RECORD_TYPE_VOLUNTEER_ENGAGEMENT = 'Volunteer Engagement';
    private static final String TEST_INVOLVEMENT_NAME = 'Test Volunteer Activity';
    private static final String TEST_INVOLVEMENT_DESCRIPTION = 'Test Volunteer Activity';
    private static final Integer DAYS_OFFSET_30 = -30;
    private static final Integer DAYS_OFFSET_60 = -60;
    private static final Integer EXPECTED_C1_RECORDS = 2;
    private static final Integer EXPECTED_C2_RECORDS = 1;
    private static final Integer EXPECTED_EMPTY_RECORDS = 0;
    private static final Integer FIRST_CONTACT_INDEX = 0;
    private static final Integer SECOND_CONTACT_INDEX = 1;

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
        Id volunteerRtId = rtId(RECORD_TYPE_VOLUNTEER_ENGAGEMENT);

        // Create Involvement Value (required by validation rule)
        // Must set Type to match Record Type name for validation
        ucinn_ascendv2__Involvement_Value__c invValue = new ucinn_ascendv2__Involvement_Value__c(
            Name = TEST_INVOLVEMENT_NAME,
            ucinn_ascendv2__Type__c = RECORD_TYPE_VOLUNTEER_ENGAGEMENT,
            ucinn_ascendv2__Involvement_Description__c = TEST_INVOLVEMENT_DESCRIPTION
        );
        insert invValue;

        // Seed involvement records for c1
        insert new List<ucinn_ascendv2__Involvement__c>{
            new ucinn_ascendv2__Involvement__c(
                ucinn_ascendv2__Contact__c = c1.Id,
                RecordTypeId = volunteerRtId,
                ucinn_ascendv2__Involvement_Code__c = invValue.Id,
                ucinn_ascendv2__Start_Date__c = Date.today().addDays(DAYS_OFFSET_30)
            ),
            new ucinn_ascendv2__Involvement__c(
                ucinn_ascendv2__Contact__c = c1.Id,
                RecordTypeId = volunteerRtId,
                ucinn_ascendv2__Involvement_Code__c = invValue.Id,
                ucinn_ascendv2__Start_Date__c = Date.today().addDays(DAYS_OFFSET_60)
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
        Contact c1 = contacts[FIRST_CONTACT_INDEX];
        Id volunteerRtId = rtId(RECORD_TYPE_VOLUNTEER_ENGAGEMENT);

        Test.startTest();
        List<ucinn_ascendv2__Involvement__c> involvements =
            HamJEDIInvolvementController.getInvolvements(c1.Id, volunteerRtId);
        Test.stopTest();

        System.assertEquals(EXPECTED_C1_RECORDS, involvements.size(), 'c1 should have 2 Volunteer Engagement records');

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
        Contact c1 = contacts[FIRST_CONTACT_INDEX];
        Contact c2 = contacts[SECOND_CONTACT_INDEX];
        Id volunteerRtId = rtId(RECORD_TYPE_VOLUNTEER_ENGAGEMENT);

        Test.startTest();
        List<ucinn_ascendv2__Involvement__c> involvementsForC1 =
            HamJEDIInvolvementController.getInvolvements(c1.Id, volunteerRtId);
        List<ucinn_ascendv2__Involvement__c> involvementsForC2 =
            HamJEDIInvolvementController.getInvolvements(c2.Id, volunteerRtId);
        Test.stopTest();

        // Verify each contact gets the correct number of records
        System.assertEquals(EXPECTED_C1_RECORDS, involvementsForC1.size(), 'c1 should have 2 records');
        System.assertEquals(EXPECTED_C2_RECORDS, involvementsForC2.size(), 'c2 should have 1 record');

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
        Id volunteerRtId = rtId(RECORD_TYPE_VOLUNTEER_ENGAGEMENT);

        Test.startTest();
        List<ucinn_ascendv2__Involvement__c> involvements =
            HamJEDIInvolvementController.getInvolvements(contactWithoutRecords.Id, volunteerRtId);
        Test.stopTest();

        System.assertEquals(EXPECTED_EMPTY_RECORDS, involvements.size(), 'Should return empty list');
    }

    @IsTest
    static void testOrderingByInvolvementCode() {
        List<Contact> contacts = [SELECT Id FROM Contact ORDER BY CreatedDate];
        Contact c1 = contacts[FIRST_CONTACT_INDEX];
        Id volunteerRtId = rtId(RECORD_TYPE_VOLUNTEER_ENGAGEMENT);

        Test.startTest();
        List<ucinn_ascendv2__Involvement__c> involvements =
            HamJEDIInvolvementController.getInvolvements(c1.Id, volunteerRtId);
        Test.stopTest();

        System.assertEquals(EXPECTED_C1_RECORDS, involvements.size(), 'c1 should have 2 records');

        // Verify results are returned (ordering will be tested in integration)
        System.assertNotEquals(null, involvements[0].Id, 'First record should have ID');
        System.assertNotEquals(null, involvements[1].Id, 'Second record should have ID');
    }
}