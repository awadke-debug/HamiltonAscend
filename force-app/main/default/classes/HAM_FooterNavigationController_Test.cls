/**
* @File Name : HAM_FooterNavigationController_Test.cls
* @Author : Sachin
* @Last Modified By : Sachin
* @Last Modified On : August 21, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | August 21, 2025 | Sachin  | Initial Version
**/
@IsTest
private class HAM_FooterNavigationController_Test {

    /**
     * @description This test method validates the behavior of the `getHCFooterMetaData` method.
     * It tests that the method returns only the custom metadata records where `HAM_Level_1__c` is 'Footer'
     * and that the records are ordered correctly.
     */
    @IsTest
    static void testGetHCFooterMetaData() {
    	// Call the main method to get the list of footer metadata.
        List<HAM_Meta_Data__mdt> footerRecords = HAM_FooterNavigationController.getHCFooterMetaData();

        // --- Assert ---
        // Verify that the query returned some records. The exact number will depend on the org's metadata.
        System.assertNotEquals(null, footerRecords, 'The list of footer records should not be null.');
        System.assert(footerRecords.size() > 0, 'The query should return at least one footer record.');

        for (HAM_Meta_Data__mdt record : footerRecords) {
            System.assertEquals('Footer', record.HAM_Level_1__c, 'All returned records must have HAM_Level_1__c set to "Footer".');
        }

        // Verify the ordering. This checks if the records are sorted first by HAM_Level_2__c, then by HAM_Order__c.
        if (footerRecords.size() > 1) {
            boolean isOrderedCorrectly = true;
            for (Integer i = 0; i < footerRecords.size() - 1; i++) {
                HAM_Meta_Data__mdt currentRecord = footerRecords[i];
                HAM_Meta_Data__mdt nextRecord = footerRecords[i + 1];

                // Check ordering by HAM_Level_2__c
                if (currentRecord.HAM_Level_2__c.compareTo(nextRecord.HAM_Level_2__c) > 0) {
                    isOrderedCorrectly = false;
                    break;
                }
                // If HAM_Level_2__c is the same, check ordering by HAM_Order__c
                if (currentRecord.HAM_Level_2__c == nextRecord.HAM_Level_2__c && currentRecord.HAM_Order__c > nextRecord.HAM_Order__c) {
                    isOrderedCorrectly = false;
                    break;
                }
            }
            System.assert(isOrderedCorrectly, 'The records are not ordered correctly by HAM_Level_2__c and HAM_Order__c.');
        }
    }
}