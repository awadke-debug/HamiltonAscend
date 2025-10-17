@IsTest
private class HAMJEDIPledgeBalanceControllerTest {

    // Helper: fetch Record Type Id by LABEL and assert it's present
    private static Id rtId(String label) {
        Map<String, Schema.RecordTypeInfo> byName =
            Schema.SObjectType.HAM_Pledge_Balance__c.getRecordTypeInfosByName();
        System.assert(byName.containsKey(label),
            'Missing Record Type on HAM_Pledge_Balance__c with label: ' + label);
        return byName.get(label).getRecordTypeId();
    }

    @TestSetup
    static void setupTestData() {
        // Base data via factory
        Account acc = HAMJediTestDataFactory.makeAccount();
        Contact c1 = HAMJediTestDataFactory.makeContact(acc.Id);
        Contact c2 = HAMJediTestDataFactory.makeContact(acc.Id);

        // Seed one active record per RT for c1
        insert new List<HAM_Pledge_Balance__c>{
            new HAM_Pledge_Balance__c(Constituent__c=c1.Id, HAM_Status__c='active', RecordTypeId=rtId('Campaign')),
            new HAM_Pledge_Balance__c(Constituent__c=c1.Id, HAM_Status__c='active', RecordTypeId=rtId('Endowed Funds')),
            new HAM_Pledge_Balance__c(Constituent__c=c1.Id, HAM_Status__c='active', RecordTypeId=rtId('Giving By Purpose')),
            new HAM_Pledge_Balance__c(Constituent__c=c1.Id, HAM_Status__c='active', RecordTypeId=rtId('Last 5 year Giving')),
            new HAM_Pledge_Balance__c(Constituent__c=c1.Id, HAM_Status__c='active', RecordTypeId=rtId('Open Pledge'))
        };

        // Additional Campaign records for filtering tests
        insert new List<HAM_Pledge_Balance__c>{
            new HAM_Pledge_Balance__c(Constituent__c=c1.Id, HAM_Status__c='active', RecordTypeId=rtId('Campaign')),
            new HAM_Pledge_Balance__c(Constituent__c=c1.Id, HAM_Status__c='inactive', RecordTypeId=rtId('Campaign')),
            new HAM_Pledge_Balance__c(Constituent__c=c2.Id, HAM_Status__c='active', RecordTypeId=rtId('Campaign'))
        };
    }

    @IsTest
    static void testGetCampaignDetail() {
        List<Contact> contacts = [SELECT Id FROM Contact ORDER BY CreatedDate];
        Contact c1 = contacts[0];

        Test.startTest();
        List<HAM_Pledge_Balance__c> campaign = HAMJEDIPledgeBalanceController.getCampaignDetail(c1.Id);
        Test.stopTest();

        System.assertEquals(2, campaign.size(), 'c1 should have 2 active Campaign records');
        
        // Verify basic record properties without accessing unqueried fields
        for (HAM_Pledge_Balance__c record : campaign) {
            System.assertNotEquals(null, record.Id, 'Record should have an ID');
        }
    }

    @IsTest
    static void testGetEndowedFundsDetail() {
        List<Contact> contacts = [SELECT Id FROM Contact ORDER BY CreatedDate];
        Contact c1 = contacts[0];

        Test.startTest();
        List<HAM_Pledge_Balance__c> endowed = HAMJEDIPledgeBalanceController.getEndowdedFundsDetail(c1.Id);
        Test.stopTest();

        System.assertEquals(1, endowed.size(), 'c1 should have 1 Endowed Funds record');
        System.assertNotEquals(null, endowed[0].Id, 'Record should have an ID');
    }

    @IsTest
    static void testGetGivingByPurposeDetail() {
        List<Contact> contacts = [SELECT Id FROM Contact ORDER BY CreatedDate];
        Contact c1 = contacts[0];

        Test.startTest();
        List<HAM_Pledge_Balance__c> purpose = HAMJEDIPledgeBalanceController.getGivingByPurposeDetail(c1.Id);
        Test.stopTest();

        System.assertEquals(1, purpose.size(), 'c1 should have 1 Giving By Purpose record');
        System.assertNotEquals(null, purpose[0].Id, 'Record should have an ID');
    }

    @IsTest
    static void testGetLast5YearsDetail() {
        List<Contact> contacts = [SELECT Id FROM Contact ORDER BY CreatedDate];
        Contact c1 = contacts[0];

        Test.startTest();
        List<HAM_Pledge_Balance__c> last5Years = HAMJEDIPledgeBalanceController.getLast5YearsDetail(c1.Id);
        Test.stopTest();

        System.assertEquals(1, last5Years.size(), 'c1 should have 1 Last 5 year Giving record');
        System.assertNotEquals(null, last5Years[0].Id, 'Record should have an ID');
    }

    @IsTest
    static void testGetOpenPledgeDetail() {
        List<Contact> contacts = [SELECT Id FROM Contact ORDER BY CreatedDate];
        Contact c1 = contacts[0];

        Test.startTest();
        List<HAM_Pledge_Balance__c> open = HAMJEDIPledgeBalanceController.getOpenPledgeDetail(c1.Id);
        Test.stopTest();

        System.assertEquals(1, open.size(), 'c1 should have 1 Open Pledge record');
        System.assertNotEquals(null, open[0].Id, 'Record should have an ID');
    }

    @IsTest
    static void testCampaignStatusFiltering() {
        List<Contact> contacts = [SELECT Id FROM Contact ORDER BY CreatedDate];
        Contact c1 = contacts[0];
        
        // Get all Campaign records for c1 (both active and inactive)
        List<HAM_Pledge_Balance__c> allCampaignRecords = [
            SELECT Id, HAM_Status__c 
            FROM HAM_Pledge_Balance__c 
            WHERE Constituent__c = :c1.Id AND RecordTypeId = :rtId('Campaign')
        ];
        
        Id activeCampaignId = null;
        Id inactiveCampaignId = null;
        
        for (HAM_Pledge_Balance__c record : allCampaignRecords) {
            if (record.HAM_Status__c == 'active' && activeCampaignId == null) {
                activeCampaignId = record.Id;
            } else if (record.HAM_Status__c == 'inactive') {
                inactiveCampaignId = record.Id;
            }
        }

        Test.startTest();
        List<HAM_Pledge_Balance__c> campaign = HAMJEDIPledgeBalanceController.getCampaignDetail(c1.Id);
        Test.stopTest();

        // Verify filtering works - only active records returned
        Set<Id> campaignIds = new Set<Id>();
        for (HAM_Pledge_Balance__c r : campaign) campaignIds.add(r.Id);

        System.assert(campaignIds.contains(activeCampaignId), 'Active campaign for c1 must be included');
        System.assert(!campaignIds.contains(inactiveCampaignId), 'Inactive campaign for c1 must be excluded');
    }

    @IsTest
    static void testContactIsolation() {
        List<Contact> contacts = [SELECT Id FROM Contact ORDER BY CreatedDate];
        Contact c1 = contacts[0];
        Contact c2 = contacts[1];

        Test.startTest();
        List<HAM_Pledge_Balance__c> campaignForC1 = HAMJEDIPledgeBalanceController.getCampaignDetail(c1.Id);
        List<HAM_Pledge_Balance__c> campaignForC2 = HAMJEDIPledgeBalanceController.getCampaignDetail(c2.Id);
        Test.stopTest();

        // Verify each contact gets the correct number of records
        System.assertEquals(2, campaignForC1.size(), 'c1 should have 2 active Campaign records');
        System.assertEquals(1, campaignForC2.size(), 'c2 should have 1 active Campaign record');

        // Verify basic record properties
        for (HAM_Pledge_Balance__c r : campaignForC1) {
            System.assertNotEquals(null, r.Id, 'c1 records should have IDs');
        }

        for (HAM_Pledge_Balance__c r : campaignForC2) {
            System.assertNotEquals(null, r.Id, 'c2 records should have IDs');
        }

        // Verify no duplicate IDs between the two result sets
        Set<Id> c1CampaignIds = new Set<Id>();
        for (HAM_Pledge_Balance__c r : campaignForC1) {
            c1CampaignIds.add(r.Id);
        }

        for (HAM_Pledge_Balance__c r : campaignForC2) {
            System.assert(!c1CampaignIds.contains(r.Id), 'c2 records should not appear in c1 results');
        }
    }

    @IsTest
    static void testEmptyResults() {
        // Create a contact with no pledge balance records
        Account acc = HAMJediTestDataFactory.makeAccount();
        Contact contactWithoutRecords = HAMJediTestDataFactory.makeContact(acc.Id);

        Test.startTest();
        List<HAM_Pledge_Balance__c> campaign = HAMJEDIPledgeBalanceController.getCampaignDetail(contactWithoutRecords.Id);
        List<HAM_Pledge_Balance__c> endowed = HAMJEDIPledgeBalanceController.getEndowdedFundsDetail(contactWithoutRecords.Id);
        List<HAM_Pledge_Balance__c> purpose = HAMJEDIPledgeBalanceController.getGivingByPurposeDetail(contactWithoutRecords.Id);
        List<HAM_Pledge_Balance__c> last5Years = HAMJEDIPledgeBalanceController.getLast5YearsDetail(contactWithoutRecords.Id);
        List<HAM_Pledge_Balance__c> open = HAMJEDIPledgeBalanceController.getOpenPledgeDetail(contactWithoutRecords.Id);
        Test.stopTest();

        System.assertEquals(0, campaign.size(), 'Should return empty list for campaign');
        System.assertEquals(0, endowed.size(), 'Should return empty list for endowed');
        System.assertEquals(0, purpose.size(), 'Should return empty list for purpose');
        System.assertEquals(0, last5Years.size(), 'Should return empty list for last5Years');
        System.assertEquals(0, open.size(), 'Should return empty list for open');
    }
}