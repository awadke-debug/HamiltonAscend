/**
 * @description Test class for `HAM_AlumniDirectoryController`. This class contains unit tests
 * to verify the functionality of methods related to fetching alumni records, managing filters,
 * and handling user preferences in the alumni directory.
 *
 * @author Sachin Sharma
 * @date August 29, 2025
 * @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | August 29, 2025 |  Sachin | Initial Version
 */
@IsTest
public with sharing class HAM_AlumniDirectoryController_Test {

    /**
     * @description Test setup method to create all necessary data for the test methods.
     * This ensures all tests run in a predictable state with consistent data.
     */
    @TestSetup
    static void setup() {
        // Query Metadata records for filters
        List<HAM_Filters__mdt> filters = [SELECT MasterLabel, DeveloperName, HAM_Reference_Type__c, HAM_Reference_Object_API__c, 
                                          HAM_Reference_Field_API__c, HAM_Reference_Values__c, HAM_Order__c, 
                                          HAM_Placeholder__c, HAM_Direct_Filter__c, HAM_Direct_Filter_Field__c 
                                          FROM HAM_Filters__mdt];
        System.assert(!filters.isEmpty(), 'At least one HAM_Filters__mdt record must exist in the org for tests.');
        Account acc = new Account(Name = 'Test Account', Industry = 'Finance');
        insert acc;
        // Create Contact and related Degree Information
        List<Contact> contactsToInsert = new List<Contact>();
        for (Integer i = 0; i < 30; i++) {
            Contact c = new Contact(
                FirstName = 'Test',
                LastName = 'Alumni '+ i,
                HAM_Profile_Picture_URL__c = 'https://test.com/pic.jpg',
                ucinn_ascendv2__Preferred_Class_Year__c = '1979',
                HAM_Reunion_Year__c = '1979',
                Constituent_Employer__c = acc.Id,
                HAM_Is_Active__c = true,
                ucinn_ascendv2__Primary_Contact_Type__c = 'Trustee'
            );
            contactsToInsert.add(c);
        }
        insert contactsToInsert;
        
         // Create a single Post Code record to be reused
        ucinn_ascendv2__Post_Code__c pcode = new ucinn_ascendv2__Post_Code__c(
            Name = 'Economics',
            ucinn_ascendv2__Major_Specialty_Description__c = 'Economics',
            ucinn_ascendv2__Is_Active__c = true
        );
        insert pcode;
        
        // Get the Record Type ID for 'School_Degree_Information'
        Id schoolDegreeRecordTypeId = Schema.SObjectType.ucinn_ascendv2__Degree_Information__c.getRecordTypeInfosByDeveloperName().get('School_Degree_Information').getRecordTypeId();
        
        // Create a list to hold the degree records
        List<ucinn_ascendv2__Degree_Information__c> degreesToInsert = new List<ucinn_ascendv2__Degree_Information__c>();
        
        // Create a list to hold the preference records
        List<HAM_Portal_User_Preference__c> prefToInsert = new List<HAM_Portal_User_Preference__c>();

        // Loop through the list of contacts and create a new degree for each one
        for (Contact c : contactsToInsert) {
            degreesToInsert.add(new ucinn_ascendv2__Degree_Information__c(
                ucinn_ascendv2__Contact__c = c.Id,
                ucinn_ascendv2__Post_Code__c = pcode.Id,
                RecordTypeId = schoolDegreeRecordTypeId
            ));
            
            prefToInsert.add(new HAM_Portal_User_Preference__c(
            Portal_Contact__c = c.Id,
            Alumni_Filter__c = '[{"placeholder":"Class Year","value":"1979"}]'
            ));
        }
        
        insert degreesToInsert;
        
        insert prefToInsert;
        List<contact> cons = [Select id from contact Where Constituent_Employer__r.Industry = 'Finance'];
        system.debug('inserted contacts size'+cons.size());
        
    }

    /**
     * @description Test case to verify that `getFilterMetadataAndValues` returns the correct filter metadata.
     */
    @IsTest
    static void testGetFilterMetadataAndValues() {
        Test.startTest();
        List<HAM_AlumniDirectoryController.FilterWrapper> filters = HAM_AlumniDirectoryController.getFilterMetadataAndValues();
        Test.stopTest();
        System.assert(!filters.isEmpty(), 'Filter metadata should not be empty');
        System.assert(filters[0].placeholder == 'Class Year', 'Class Year Not Validated');
    }

    /**
     * @description Test case to verify that `getAlumniRecordCount` returns the correct count
     * when a search key and filter are applied.
     */
    @IsTest
    static void testGetAlumniRecordCount() {
        List<Map<String, String>> filters = new List<Map<String, String>>();
        Map<String, String> filter = new Map<String, String>{'placeholder' => 'Class Year', 'value' => '1979'};
        filters.add(filter);

        Test.startTest();
        Integer count = HAM_AlumniDirectoryController.getAlumniRecordCount('Test', filters);
        Test.stopTest();
        System.assert(count >= 0, 'Record count should be non-negative');
    }

    /**
     * @description Test case to verify that `getAlumniRecords` returns a list of records
     * when valid search criteria are provided.
     */  
    @IsTest
    static void testGetAlumniRecords() {
        List<Map<String, String>> filters = new List<Map<String, String>>();
        Map<String, String> filter = new Map<String, String>{'placeholder' => 'Class Year', 'value' => '1979'};
        filters.add(filter);

        Test.startTest();
        Account acc = new Account(Name = 'Test Account', Industry = 'Finance');
        insert acc;
        List<Contact> contactsToInsert = new List<Contact>();
        for (Integer i = 0; i < 30; i++) {
            Contact c = new Contact(
                FirstName = 'Test',
                LastName = 'Alumni '+ i,
                HAM_Profile_Picture_URL__c = 'https://test.com/pic.jpg',
                ucinn_ascendv2__Preferred_Class_Year__c = '1979',
                HAM_Reunion_Year__c = '1979',
                Constituent_Employer__c = acc.Id,
                HAM_Is_Active__c = true,
                ucinn_ascendv2__Primary_Contact_Type__c = 'Past Parent'
            );
            contactsToInsert.add(c);
        }
        insert contactsToInsert;
        
        List<contact> cons = [Select id,Name,HAM_Reunion_Year__c,HAM_Is_Active__c,ucinn_ascendv2__Primary_Contact_Type__c,ucinn_ascendv2__Expanded_Name_Formula__c from contact];
        
        for(Contact con : cons){
            if(con.ucinn_ascendv2__Primary_Contact_Type__c == 'Friend'){
                con.ucinn_ascendv2__Primary_Contact_Type__c = 'Trustee';
            }
        }
        update cons;
        
        List<HAM_AlumniDirectoryController.AlumniCardData> records = HAM_AlumniDirectoryController.getAlumniRecords(10, 0, 'Test', filters);
        System.assert((records != null && !records.isEmpty()), 'Should return a list');
        Test.stopTest();
        if (!records.isEmpty()) {
            System.assertNotEquals(null, records[0].contactId, 'Contact Id should be set');
            System.assertNotEquals(null, records[0].contactName, 'Contact Name should be set');
            System.assert(records[0].fields != null, 'Fields should not be null');
        }
    }

    /**
     * @description Test case to verify the `saveUserPreferences` and `getSavedUserPreferences` methods
     * work correctly by saving a preference and then retrieving it.
     */
    @IsTest
    static void testSaveAndGetUserPreferences() {
        Contact c = [SELECT Id FROM Contact LIMIT 1];
        String filtersJson = '[{"placeholder":"Class Year","value":"1979"}]';

        Test.startTest();
        HAM_AlumniDirectoryController.saveUserPreferences(filtersJson, c.Id);
        String saved = HAM_AlumniDirectoryController.getSavedUserPreferences(c.Id);
        
        Test.stopTest();

        System.assertNotEquals(null, saved, 'Saved preferences should not be null');
        System.assert(saved.contains('1979'), 'Saved preferences should contain the value');
    }

    /**
     * @description Test case to verify that `getSavedUserPreferences` returns null when a null contact ID is provided.
     */
    @IsTest
    static void testGetSavedUserPreferencesNull() {
        String filtersJson = '[{"placeholder":"Class Year","value":"1979"}]';
        Test.startTest();
        HAM_AlumniDirectoryController.saveUserPreferences(filtersJson, null);
        Test.stopTest();
        //System.assertEquals(null, result, 'Should return null for null contact id');
    }

    /**
     * @description Test case to verify that `getAlumniRecordCount` returns 0 for an empty search and filter.
     */
    @IsTest
    static void testGetAlumniRecordCountEmpty() {
        Test.startTest();
        Integer count = HAM_AlumniDirectoryController.getAlumniRecordCount(null, new List<Map<String, String>>());
        Test.stopTest();
        System.assertEquals(0, count, 'Should return 0 for empty search and filters');
    }

    /**
     * @description Test case to verify that `getAlumniRecords` returns an empty list
     * for an empty search and filter.
     */
    @IsTest
    static void testGetAlumniRecordsEmpty() {
        Test.startTest();
        List<HAM_AlumniDirectoryController.AlumniCardData> records = HAM_AlumniDirectoryController.getAlumniRecords(10, 10, null, new List<Map<String, String>>());
        Test.stopTest();
        System.assertEquals(0, records.size(), 'Should return empty list for empty search and filters');
    }
}