@isTest
private class TestContactUpdateCombinedTrigger {
    @isTest
    static void testContactInsert() {
        // Setup - Insert a new Contact to test 'before insert' and 'after insert'
        Contact newContact = new Contact(LastName = 'Test', FirstName = 'Trigger', ucinn_ascendv2__Contact_Type__c = 'Friend');
        
        Test.startTest();
        insert newContact;
        Test.stopTest();
        
        // Verify insert logic if applicable
        // Add assertions to verify the logic after insert
    }

    @isTest
    static void testContactUpdate() {
        // Setup - Create and insert a contact
        Contact existingContact = new Contact(LastName = 'Existing', FirstName = 'Test');
        insert existingContact;

        // Prepare for update - This should trigger 'before update' and 'after update'
        existingContact.LastName = 'UpdatedTest';

        Test.startTest();
        update existingContact;
        Test.stopTest();
        
        // Verify update logic
        Contact updatedContact = [SELECT LastName FROM Contact WHERE Id = :existingContact.Id];
        System.assertEquals('UpdatedTest', updatedContact.LastName, 'The LastName should be updated.');
        
        // Add more assertions here to validate that your trigger has correctly updated the records
    }
}