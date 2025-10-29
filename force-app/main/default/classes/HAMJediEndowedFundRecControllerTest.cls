@IsTest
private class HAMJediEndowedFundRecControllerTest {

    @TestSetup
    static void setupData() {
        // Create test Account and Contact
        Account a = HAMJediTestDataFactory.makeAccount();
        Contact c = HAMJediTestDataFactory.makeContact(a.Id);

        // Create Designation (Fund) with Record Type
        ucinn_ascendv2__Designation__c designation = new ucinn_ascendv2__Designation__c(
            Name = 'Test Fund XF-001',
            ucinn_ascendv2__Fund_Name__c = 'Test Scholarship Fund',
            RecordTypeId = '012U1000000lheLIAQ',
            HAM_Fund_Status__c = 'Active'
        );
        insert designation;

        // Create Designation Stewardship (links Contact to Designation)
        ucinn_ascendv2__Designation_Stewardship__c stewardship = new ucinn_ascendv2__Designation_Stewardship__c(
            ucinn_ascendv2__Contact_Stewardee__c = c.Id,
            ucinn_ascendv2__Designation__c = designation.Id,
            ucinn_ascendv2__Status__c = 'Current',
            HAM_Reporting_Type__c = 'Comprehensive'
        );
        insert stewardship;

        // Create test student Contact
        Contact student1 = HAMJediTestDataFactory.makeContact('Student One', a.Id);
        Contact student2 = HAMJediTestDataFactory.makeContact('Student Two', a.Id);

        // Create Designation Beneficiaries (recipients)
        // Note: HAM_Sort_Fiscal_Year__c is a formula/readonly field, so we don't set it
        List<ucinn_ascendv2__Designation_Beneficiary__c> beneficiaries = new List<ucinn_ascendv2__Designation_Beneficiary__c>{
            // Student 1 - Fall (FA)
            new ucinn_ascendv2__Designation_Beneficiary__c(
                ucinn_ascendv2__Designation__c = designation.Id,
                ucinn_ascendv2__Contact__c = student1.Id,
                HAM_Award_Session__c = 'FA',
                HAM_Anonymous__c = false
            ),
            // Student 1 - Spring (SP) (same year, should be grouped if fiscal year matches)
            new ucinn_ascendv2__Designation_Beneficiary__c(
                ucinn_ascendv2__Designation__c = designation.Id,
                ucinn_ascendv2__Contact__c = student1.Id,
                HAM_Award_Session__c = 'SP',
                HAM_Anonymous__c = true // Different anonymous value - should result in true
            ),
            // Student 2 - Fall (FA)
            new ucinn_ascendv2__Designation_Beneficiary__c(
                ucinn_ascendv2__Designation__c = designation.Id,
                ucinn_ascendv2__Contact__c = student2.Id,
                HAM_Award_Session__c = 'FA',
                HAM_Anonymous__c = false
            )
        };
        insert beneficiaries;
    }

    @IsTest
    static void testGetFundsWithBeneficiaries() {
        // Get the test contact (steward)
        Contact steward = [SELECT Id FROM Contact WHERE LastName LIKE 'Test%' LIMIT 1];

        // Call the original method
        Test.startTest();
        List<HAMJediEndowedFundRecipientsController.FundWithBeneficiaries> result =
            HAMJediEndowedFundRecipientsController.getFundsWithBeneficiaries(steward.Id);
        Test.stopTest();

        // Verify results
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(1, result.size(), 'Should return 1 fund');

        HAMJediEndowedFundRecipientsController.FundWithBeneficiaries fund = result[0];
        System.assertNotEquals(null, fund.stewardshipId, 'Stewardship ID should be populated');
        System.assertEquals('Test Scholarship Fund', fund.fundName, 'Fund name should match');
        System.assertEquals(3, fund.beneficiaries.size(), 'Should have 3 beneficiary records');
    }

    @IsTest
    static void testGetFundsWithGroupedBeneficiaries() {
        // Get the test contact (steward)
        Contact steward = [SELECT Id FROM Contact WHERE LastName LIKE 'Test%' LIMIT 1];

        // Call the grouped method
        Test.startTest();
        List<HAMJediEndowedFundRecipientsController.FundWithGroupedBeneficiaries> result =
            HAMJediEndowedFundRecipientsController.getFundsWithGroupedBeneficiaries(steward.Id);
        Test.stopTest();

        // Verify results
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(1, result.size(), 'Should return 1 fund');

        HAMJediEndowedFundRecipientsController.FundWithGroupedBeneficiaries fund = result[0];
        System.assertNotEquals(null, fund.stewardshipId, 'Stewardship ID should be populated');
        System.assertEquals('Test Scholarship Fund', fund.fundName, 'Fund name should match');

        // Verify we get beneficiary records (grouping depends on fiscal year formula)
        System.assert(fund.beneficiaries.size() >= 1, 'Should have at least 1 grouped beneficiary record');

        // Verify grouping logic - find Student One records
        HAMJediEndowedFundRecipientsController.GroupedBeneficiary student1Group = null;

        for (HAMJediEndowedFundRecipientsController.GroupedBeneficiary gb : fund.beneficiaries) {
            if (gb.contactName.contains('Student One')) {
                student1Group = gb;
                break;
            }
        }

        // Verify Student 1 data
        System.assertNotEquals(null, student1Group, 'Student One should be in results');
        System.assertNotEquals(null, student1Group.fiscalYear, 'Fiscal year should be populated');
        // If same fiscal year, should have 2 semesters; if different years, would be 1
        System.assert(student1Group.semesters.size() >= 1, 'Should have at least 1 semester');
        // Verify Anonymous OR logic: if ANY semester was true, group should be true
        System.assertEquals(true, student1Group.isAnonymous, 'Should be anonymous (OR logic - one semester was true)');
    }

    @IsTest
    static void testGetSemestersDisplay() {
        // Test the helper method
        HAMJediEndowedFundRecipientsController.GroupedBeneficiary gb =
            new HAMJediEndowedFundRecipientsController.GroupedBeneficiary();

        // Test with multiple semesters
        gb.semesters = new List<String>{'Fall', 'Spring'};
        String display = gb.getSemestersDisplay();
        System.assertEquals('Fall, Spring', display, 'Should return comma-separated semesters');

        // Test with single semester
        gb.semesters = new List<String>{'Fall'};
        display = gb.getSemestersDisplay();
        System.assertEquals('Fall', display, 'Should return single semester');

        // Test with empty list
        gb.semesters = new List<String>();
        display = gb.getSemestersDisplay();
        System.assertEquals('', display, 'Should return empty string for empty list');

        // Test with null
        gb.semesters = null;
        display = gb.getSemestersDisplay();
        System.assertEquals('', display, 'Should return empty string for null');
    }

    @IsTest
    static void testNoStewardships() {
        // Create contact without any stewardships
        Account a = HAMJediTestDataFactory.makeAccount();
        Contact c = HAMJediTestDataFactory.makeContact(a.Id);

        // Test both methods with contact that has no stewardships
        Test.startTest();
        List<HAMJediEndowedFundRecipientsController.FundWithBeneficiaries> result1 =
            HAMJediEndowedFundRecipientsController.getFundsWithBeneficiaries(c.Id);
        List<HAMJediEndowedFundRecipientsController.FundWithGroupedBeneficiaries> result2 =
            HAMJediEndowedFundRecipientsController.getFundsWithGroupedBeneficiaries(c.Id);
        Test.stopTest();

        // Verify empty results
        System.assertNotEquals(null, result1, 'Result should not be null');
        System.assertEquals(0, result1.size(), 'Should return empty list');
        System.assertNotEquals(null, result2, 'Result should not be null');
        System.assertEquals(0, result2.size(), 'Should return empty list');
    }

    @IsTest
    static void testInactiveAndFilteredStewardships() {
        // Create test data
        Account a = HAMJediTestDataFactory.makeAccount();
        Contact c = HAMJediTestDataFactory.makeContact(a.Id);

        // Create designation with Inactive status
        ucinn_ascendv2__Designation__c inactiveDesignation = new ucinn_ascendv2__Designation__c(
            Name = 'Inactive Fund',
            ucinn_ascendv2__Fund_Name__c = 'Inactive Scholarship',
            RecordTypeId = '012U1000000lheLIAQ',
            HAM_Fund_Status__c = 'Inactive'
        );
        insert inactiveDesignation;

        // Create stewardship with Status != 'Current' (use Former)
        ucinn_ascendv2__Designation_Stewardship__c inactiveStewardship = new ucinn_ascendv2__Designation_Stewardship__c(
            ucinn_ascendv2__Contact_Stewardee__c = c.Id,
            ucinn_ascendv2__Designation__c = inactiveDesignation.Id,
            ucinn_ascendv2__Status__c = 'Former',
            HAM_Reporting_Type__c = 'Comprehensive'
        );
        insert inactiveStewardship;

        // Test
        Test.startTest();
        List<HAMJediEndowedFundRecipientsController.FundWithGroupedBeneficiaries> result =
            HAMJediEndowedFundRecipientsController.getFundsWithGroupedBeneficiaries(c.Id);
        Test.stopTest();

        // Should not return inactive stewardships
        System.assertEquals(0, result.size(), 'Should not return inactive stewardships');
    }

    @IsTest
    static void testNullContactId() {
        // Test with null contact ID
        Test.startTest();
        List<HAMJediEndowedFundRecipientsController.FundWithBeneficiaries> result1 =
            HAMJediEndowedFundRecipientsController.getFundsWithBeneficiaries(null);
        List<HAMJediEndowedFundRecipientsController.FundWithGroupedBeneficiaries> result2 =
            HAMJediEndowedFundRecipientsController.getFundsWithGroupedBeneficiaries(null);
        Test.stopTest();

        // Should return empty lists, not throw exception
        System.assertNotEquals(null, result1, 'Result should not be null');
        System.assertEquals(0, result1.size(), 'Should return empty list for null ID');
        System.assertNotEquals(null, result2, 'Result should not be null');
        System.assertEquals(0, result2.size(), 'Should return empty list for null ID');
    }

    @IsTest
    static void testMultipleFunds() {
        // Get existing contact
        Contact steward = [SELECT Id FROM Contact WHERE LastName LIKE 'Test%' LIMIT 1];

        // Create additional designation and stewardship
        ucinn_ascendv2__Designation__c designation2 = new ucinn_ascendv2__Designation__c(
            Name = 'Test Fund XF-002',
            ucinn_ascendv2__Fund_Name__c = 'Second Scholarship Fund',
            RecordTypeId = '012U1000000lheLIAQ',
            HAM_Fund_Status__c = 'Active'
        );
        insert designation2;

        ucinn_ascendv2__Designation_Stewardship__c stewardship2 = new ucinn_ascendv2__Designation_Stewardship__c(
            ucinn_ascendv2__Contact_Stewardee__c = steward.Id,
            ucinn_ascendv2__Designation__c = designation2.Id,
            ucinn_ascendv2__Status__c = 'Current',
            HAM_Reporting_Type__c = 'Financial Only'
        );
        insert stewardship2;

        // Test
        Test.startTest();
        List<HAMJediEndowedFundRecipientsController.FundWithGroupedBeneficiaries> result =
            HAMJediEndowedFundRecipientsController.getFundsWithGroupedBeneficiaries(steward.Id);
        Test.stopTest();

        // Should return 2 funds
        System.assertEquals(2, result.size(), 'Should return 2 funds');
    }

    @IsTest
    static void testBeneficiariesWithoutSemester() {
        // Create test data
        Account a = HAMJediTestDataFactory.makeAccount();
        Contact steward = HAMJediTestDataFactory.makeContact(a.Id);
        Contact student = HAMJediTestDataFactory.makeContact('Student Three', a.Id);

        ucinn_ascendv2__Designation__c designation = new ucinn_ascendv2__Designation__c(
            Name = 'Test Fund XF-003',
            ucinn_ascendv2__Fund_Name__c = 'Test Fund Without Semester',
            RecordTypeId = '012U1000000lheLIAQ',
            HAM_Fund_Status__c = 'Active'
        );
        insert designation;

        ucinn_ascendv2__Designation_Stewardship__c stewardship = new ucinn_ascendv2__Designation_Stewardship__c(
            ucinn_ascendv2__Contact_Stewardee__c = steward.Id,
            ucinn_ascendv2__Designation__c = designation.Id,
            ucinn_ascendv2__Status__c = 'Current',
            HAM_Reporting_Type__c = 'Comprehensive'
        );
        insert stewardship;

        // Create beneficiary WITHOUT semester
        ucinn_ascendv2__Designation_Beneficiary__c beneficiary = new ucinn_ascendv2__Designation_Beneficiary__c(
            ucinn_ascendv2__Designation__c = designation.Id,
            ucinn_ascendv2__Contact__c = student.Id,
            HAM_Award_Session__c = null, // No semester
            HAM_Anonymous__c = false
        );
        insert beneficiary;

        // Test
        Test.startTest();
        List<HAMJediEndowedFundRecipientsController.FundWithGroupedBeneficiaries> result =
            HAMJediEndowedFundRecipientsController.getFundsWithGroupedBeneficiaries(steward.Id);
        Test.stopTest();

        // Verify handling of null semester
        System.assertEquals(1, result.size(), 'Should return 1 fund');
        HAMJediEndowedFundRecipientsController.FundWithGroupedBeneficiaries fund = result[0];
        System.assertEquals(1, fund.beneficiaries.size(), 'Should have 1 beneficiary');

        HAMJediEndowedFundRecipientsController.GroupedBeneficiary gb = fund.beneficiaries[0];
        System.assertNotEquals(null, gb.semesters, 'Semesters list should not be null');
        System.assertEquals('', gb.getSemestersDisplay(), 'Should return empty string for no semesters');
    }
}