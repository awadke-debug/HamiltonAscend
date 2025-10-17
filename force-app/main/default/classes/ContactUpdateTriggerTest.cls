@isTest
public class ContactUpdateTriggerTest {

    @testSetup
    static void setup() {
        // Create Contact records
        Contact con1 = new Contact(
            FirstName = 'Test',
            LastName = 'Data1',
            ucinn_ascendv2__Contact_Type__c = 'Surviving Spouse;Past Parent;Grandparent'
        );
        Contact con2 = new Contact(
            FirstName = 'Test',
            LastName = 'Data2',
            ucinn_ascendv2__Contact_Type__c = 'Grandparent'
        );
        insert new List<Contact>{con1, con2};

    }

    @isTest
    static void testBeforeInsert() {
        // Test before insert context
        Contact newCon = new Contact(
            FirstName = 'Before',
            LastName = 'InsertTest',
            ucinn_ascendv2__Contact_Type__c = 'Friend'
        );
        Test.startTest();
        insert newCon;
        Test.stopTest();

    }

    @isTest
    static void testBeforeUpdate() {
        // Query a contact to update
        Contact conToUpdate = [SELECT Id, LastName FROM Contact LIMIT 1];
        conToUpdate.LastName = 'Updated';

        Test.startTest();
        update conToUpdate;
        Test.stopTest();

    }

    @isTest
    static void testAfterUpdate() {

    }

}