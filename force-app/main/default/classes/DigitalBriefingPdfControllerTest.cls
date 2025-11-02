@IsTest
public with sharing class DigitalBriefingPdfControllerTest {
    @TestSetup
    static void makeData(){
        User usr = new User(
            Username = 'McTesty@acme.com',
            Email =  'foo@ba.com',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User'].Id,
            FirstName = 'Mc',
            LastName = 'Testy',
            Alias = 'MTI',
            EmailEncodingKey = 'ISO-8859-1',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            LanguageLocaleKey = 'en_US'
        );
        insert usr;
        
        Contact contact = new Contact();
        contact.LastName = 'Test';
        contact.ucinn_ascendv2__PRM__c = usr.Id;
        insert contact;

        Event evt = new Event();
        evt.OwnerId = usr.Id;
        evt.WhoId = contact.Id;
        evt.HAM_Meeting_Status__c = 'Scheduled';
        evt.DurationInMinutes = 30;
        Datetime today = System.now().addDays(1);
        evt.ActivityDateTime = today;
        evt.StartDateTime = today;
        insert evt;

    }

    @IsTest
    static void methodName(){
        Contact contact = [SELECT Id FROM Contact WHERE LastName = 'Test' LIMIT 1];
        String contactId = contact.Id;

        Test.startTest();
            PageReference pageRef = Page.digitalBriefingPdf;
            pageRef.getParameters().put('contactId', contactId);
            Test.setCurrentPage(pageRef);

            DigitalBriefingPdfController controller = new DigitalBriefingPdfController();
            controller.getGiftOfficer();
            controller.getMeetingSchedule();
            controller.getConstituent();
            controller.getProfilePicUrl();
            controller.getEndowedFunds();
            controller.getPhoneNumber();
            controller.getRecentGivingBriefing();

            DigitalBriefingPdfController.EndowedFund endFund = new DigitalBriefingPdfController.EndowedFund('Test Title', 1.0, 1.0);

        Test.stopTest();
        
    }

    @IsTest
    static void testGetBaseUrl(){
        
        Test.startTest();
        DigitalBriefingPdfController.getBaseUrl();
        Test.stopTest();
        
    }

    @IsTest
    static void testGetContactBriefings(){
        Contact contact = [SELECT Id FROM Contact WHERE LastName = 'Test' LIMIT 1];
        String contactId = contact.Id;

        Test.startTest();
        DigitalBriefingPdfController.getContactsBriefing(contactId);
        Test.stopTest();
        
    }

    @IsTest
    static void testGeneratePdf(){
        Contact contact = [SELECT Id FROM Contact WHERE LastName = 'Test' LIMIT 1];
        String contactId = contact.Id;

        Test.startTest();
        DigitalBriefingPdfController.generatePdf(contactId);

        Test.stopTest();
        
    }

    @IsTest
    static void testSaveBriefing(){
        ucinn_ascendv2__Briefing__c briefing = new ucinn_ascendv2__Briefing__c();
        briefing.HAM_Briefing_Details__c = '<p>Test</p>';
        insert briefing;

        Test.startTest();
        DigitalBriefingPdfController.saveBriefing(briefing.Id, '<p>Test update</p>');
        Test.stopTest();
        
    }

    @IsTest
    static void testSanitizeLineBreaks(){
        
        Test.startTest();
        String result = DigitalBriefingPdfController.sanitizeLineBreaks('foo<p><br></p><p><br></p>bar');
        Test.stopTest();

        System.Assert.areEqual('foo<br>bar', result);
    }

    @IsTest
    static void testGetBriefingHeader(){
        
        String result = DigitalBriefingPdfController.getBriefingHeader('Alumni Service');
        System.Assert.areEqual('<p><strong>Alumni Service:</strong></p>', result);

        result = DigitalBriefingPdfController.getBriefingHeader('Connections to Other Alumni');
        System.Assert.areEqual('<p><strong>Connections to Other Alumni:</strong></p>', result);

        result = DigitalBriefingPdfController.getBriefingHeader('Context for Capacity');
        System.Assert.areEqual('<p><strong>Context for Capacity:</strong></p>', result);

        result = DigitalBriefingPdfController.getBriefingHeader('Background');
        System.Assert.areEqual('', result);
    }
}