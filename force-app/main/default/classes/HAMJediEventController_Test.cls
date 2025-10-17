@IsTest
private class HAMJediEventController_Test {
    
    @IsTest
    static void testGetEventsDetail_returnsAttendees() {
        // Arrange: full dataset (Account, Contact, 3 Attendees, 2 Email Results)
        Map<String, Object> ds = HAMJediTestDataFactory.createEventControllerTestDataset();
        Contact con = (Contact) ds.get('contact');
        List<conference360__Attendee__c> createdAttendees =
            (List<conference360__Attendee__c>) ds.get('attendees');

        Test.startTest();
        // Act
        List<conference360__Attendee__c> got =
            HAMJediEventController.getEventsDetail(String.valueOf(con.Id));
        Test.stopTest();

        // Assert
        System.assertEquals(createdAttendees.size(), got.size(),
            'Should return all attendees for the contact');

        // Compare Id sets to avoid ordering assumptions
        Set<Id> expected = new Set<Id>();
        for (conference360__Attendee__c a : createdAttendees) expected.add(a.Id);

        Set<Id> actual = new Set<Id>();
        for (conference360__Attendee__c a : got) actual.add(a.Id);

        System.assertEquals(expected, actual, 'Returned attendee Ids should match created ones');
    }

    @IsTest
    static void testGetEmailDetail_returnsEmails() {
        // Arrange
        Map<String, Object> ds = HAMJediTestDataFactory.createEventControllerTestDataset();
        Contact con = (Contact) ds.get('contact');
        List<et4ae5__IndividualEmailResult__c> createdEmails =
            (List<et4ae5__IndividualEmailResult__c>) ds.get('emails');

        Test.startTest();
        // Act
        List<et4ae5__IndividualEmailResult__c> got =
            HAMJediEventController.getEmailDetail(String.valueOf(con.Id));
        Test.stopTest();

        // Assert
        System.assertEquals(createdEmails.size(), got.size(),
            'Should return all email results for the contact');

        // Compare Id sets to avoid ordering assumptions
        Set<Id> expected = new Set<Id>();
        for (et4ae5__IndividualEmailResult__c e : createdEmails) expected.add(e.Id);

        Set<Id> actual = new Set<Id>();
        for (et4ae5__IndividualEmailResult__c e : got) actual.add(e.Id);

        System.assertEquals(expected, actual, 'Returned email result Ids should match created ones');
    }

    @IsTest
    static void testEmptyResults_forContactWithNoRecords() {
        // Arrange: create a fresh contact with no attendees/emails
        Account a = HAMJediTestDataFactory.makeAccount('No Activity Acct');
        Contact c = HAMJediTestDataFactory.makeContact('No Activity Contact', a.Id);

        Test.startTest();
        // Act
        List<conference360__Attendee__c> attendees =
            HAMJediEventController.getEventsDetail(String.valueOf(c.Id));
        List<et4ae5__IndividualEmailResult__c> emails =
            HAMJediEventController.getEmailDetail(String.valueOf(c.Id));
        Test.stopTest();

        // Assert
        System.assertEquals(0, attendees.size(), 'No attendees expected for new contact');
        System.assertEquals(0, emails.size(), 'No email results expected for new contact');
    }
}