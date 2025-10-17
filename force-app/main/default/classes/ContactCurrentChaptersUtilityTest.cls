@isTest
private class ContactCurrentChaptersUtilityTest {
	@TestSetup
    static void makeTestData(){
        ucinn_ascendv2__Trigger_Handler__c accHandler = new ucinn_ascendv2__Trigger_Handler__c(
        	Name = 'ascend_TRIG_AccountHandler',
        	ucinn_ascendv2__Class__c = 'ascend_TRIG_AccountHandler',
        	ucinn_ascendv2__Is_Active__c = true,
        	ucinn_ascendv2__Is_Asynchronous__c = false,
        	ucinn_ascendv2__Is_User_Managed__c = true,
        	ucinn_ascendv2__Owned_by_Namespace__c = 'ucinn_ascendv2',
        	ucinn_ascendv2__Load_Order__c = 1.0,
        	ucinn_ascendv2__Object__c = 'Account',
        	ucinn_ascendv2__Trigger_Action__c = 'BeforeInsert;BeforeUpdate;BeforeDelete;AfterInsert;AfterUpdate;AfterDelete;AfterUndelete'
        );
        
        ucinn_ascendv2__Trigger_Handler__c conHandler = new ucinn_ascendv2__Trigger_Handler__c(
        	Name = 'ascend_TRIG_ContactHandler',
        	ucinn_ascendv2__Class__c = 'ascend_TRIG_ContactHandler',
        	ucinn_ascendv2__Is_Active__c = true,
        	ucinn_ascendv2__Is_Asynchronous__c = false,
        	ucinn_ascendv2__Is_User_Managed__c = true,
        	ucinn_ascendv2__Owned_by_Namespace__c = 'ucinn_ascendv2',
        	ucinn_ascendv2__Load_Order__c = 1.0,
        	ucinn_ascendv2__Object__c = 'Contact',
        	ucinn_ascendv2__Trigger_Action__c = 'BeforeInsert;BeforeUpdate;BeforeDelete;AfterInsert;AfterUpdate;AfterDelete;AfterUndelete'
        );
        
        ucinn_ascendv2__Trigger_Handler__c addrHandler = new ucinn_ascendv2__Trigger_Handler__c(
        	Name = 'ascend_TRIG_AddressHandler',
        	ucinn_ascendv2__Class__c = 'ascend_TRIG_AddressHandler',
        	ucinn_ascendv2__Is_Active__c = true,
        	ucinn_ascendv2__Is_Asynchronous__c = false,
        	ucinn_ascendv2__Is_User_Managed__c = true,
        	ucinn_ascendv2__Owned_by_Namespace__c = 'ucinn_ascendv2',
        	ucinn_ascendv2__Load_Order__c = 1.0,
        	ucinn_ascendv2__Object__c = 'ucinn_ascendv2__Address__c',
        	ucinn_ascendv2__Trigger_Action__c = 'BeforeInsert;BeforeUpdate;BeforeDelete;AfterInsert;AfterUpdate;AfterDelete;AfterUndelete'
        );
        
        ucinn_ascendv2__Trigger_Handler__c addrRelHandler = new ucinn_ascendv2__Trigger_Handler__c(
        	Name = 'ascend_TRIG_AddressRelationHandler',
        	ucinn_ascendv2__Class__c = 'ascend_TRIG_AddressRelationHandler',
        	ucinn_ascendv2__Is_Active__c = true,
        	ucinn_ascendv2__Is_Asynchronous__c = false,
        	ucinn_ascendv2__Is_User_Managed__c = true,
        	ucinn_ascendv2__Owned_by_Namespace__c = 'ucinn_ascendv2',
        	ucinn_ascendv2__Load_Order__c = 1.0,
        	ucinn_ascendv2__Object__c = 'ucinn_ascendv2__Address_Relation__c',
        	ucinn_ascendv2__Trigger_Action__c = 'BeforeInsert;BeforeUpdate;BeforeDelete;AfterInsert;AfterUpdate;AfterDelete;AfterUndelete'
        );
        
        insert new List<ucinn_ascendv2__Trigger_Handler__c>{accHandler, conHandler, addrHandler, addrRelHandler};

        ucinn_ascendv2__Address_Type_Mapping__c conMailingSetting = new ucinn_ascendv2__Address_Type_Mapping__c(
            Name = 'Contact_Mailing', 
            ucinn_ascendv2__Address_Type_Label_Backend_Message__c = 'residence', 
            ucinn_ascendv2__Object_API_Name__c = 'Contact', 
            ucinn_ascendv2__Address_Relation_Type__c = 'Residence', 
            ucinn_ascendv2__Backend_Address_Type_API_Name__c = 'Residence',
            ucinn_ascendv2__Object_Address_Field_Name__c = 'MailingAddress'
        );

        ucinn_ascendv2__Address_Type_Mapping__c conOtherSetting = new ucinn_ascendv2__Address_Type_Mapping__c(
            Name = 'Contact_Other', 
            ucinn_ascendv2__Address_Type_Label_Backend_Message__c = 'business', 
            ucinn_ascendv2__Object_API_Name__c = 'Contact', 
            ucinn_ascendv2__Address_Relation_Type__c = 'Business', 
            ucinn_ascendv2__Backend_Address_Type_API_Name__c = 'Business',
            ucinn_ascendv2__Object_Address_Field_Name__c = 'OtherAddress'
        );
        insert new List<ucinn_ascendv2__Address_Type_Mapping__c>{conMailingSetting, conOtherSetting};
        
        insert new ucinn_ascendv2__Org_Wide_Configuration__c(Name = 'Default Org Wide Config', ucinn_ascendv2__Is_Multiple_Current_Addresses_Enabled__c = true);
        
        Contact testCon = new Contact(
            FirstName = 'Testing',
            LastName = 'Test Constituent',
            ucinn_ascendv2__Contact_Type__c = 'Employee'
        );
        insert testCon;
        
        HAM_Chapter_Lookup__c chapterFLOR = new HAM_Chapter_Lookup__c(
        	Name = 'Florida (Orlando)',
            HAM_Chapter_Code__c = 'FLOR',
            HAM_Chapter_Type__c = 'Domestic'
        );
        
        HAM_Chapter_Lookup__c chapterCHI = new HAM_Chapter_Lookup__c(
        	Name = 'Illinois (Chicago)',
            HAM_Chapter_Code__c = 'CHIL',
            HAM_Chapter_Type__c = 'Domestic'
        );
        
        HAM_Chapter_Lookup__c chapterNYC = new HAM_Chapter_Lookup__c(
        	Name = 'New York (New York City)',
            HAM_Chapter_Code__c = 'NYNY',
            HAM_Chapter_Type__c = 'Domestic'
        );
        insert new List<HAM_Chapter_Lookup__c>{chapterFLOR, chapterCHI, chapterNYC};

        HAM_ChapterZipCode__c flZip = new HAM_ChapterZipCode__c(
            HAM_Chapter_Lookup__c = chapterFLOR.Id,
            HAM_Zip_Code__c = '32830'
        );

        HAM_ChapterZipCode__c chiZip = new HAM_ChapterZipCode__c(
            HAM_Chapter_Lookup__c = chapterCHI.Id,
            HAM_Zip_Code__c = '60601'
        );

        HAM_ChapterZipCode__c nycZip = new HAM_ChapterZipCode__c(
            HAM_Chapter_Lookup__c = chapterNYC.Id,
            HAM_Zip_Code__c = '10012'
        );
        insert new List<HAM_ChapterZipCode__c>{flZip, chiZip, nycZip};
        
        ucinn_ascendv2__Address__c addressFLOR = new ucinn_ascendv2__Address__c(
            ucinn_ascendv2__Address_Line_1__c = '1375 East Buena Vista Drive',
            ucinn_ascendv2__City__c = 'Orlando',
            ucinn_ascendv2__State__c = 'Florida',
            ucinn_ascendv2__Postal_Code__c = '32830',
            ucinn_ascendv2__Country__c = 'United States',
            ucinn_ascendv2__External_System_ID__c = '1',
            HAM_External_System_ID__c = '11',
            HAM_Chapter__c = chapterFLOR.Id
        );
        
        ucinn_ascendv2__Address__c addressCHI = new ucinn_ascendv2__Address__c(
            ucinn_ascendv2__Address_Line_1__c = '201 East Randolph Street',
            ucinn_ascendv2__City__c = 'Chicago',
            ucinn_ascendv2__State__c = 'Illinois',
            ucinn_ascendv2__Postal_Code__c = '60601',
            ucinn_ascendv2__Country__c = 'United States',
            ucinn_ascendv2__External_System_ID__c = '2',
            HAM_External_System_ID__c = '22',
            HAM_Chapter__c = chapterCHI.Id
        );
        
        ucinn_ascendv2__Address__c addressNYC = new ucinn_ascendv2__Address__c(
            ucinn_ascendv2__Address_Line_1__c = '117 MacDougal Street',
            ucinn_ascendv2__City__c = 'New York',
            ucinn_ascendv2__State__c = 'New York',
            ucinn_ascendv2__Postal_Code__c = '10012',
            ucinn_ascendv2__Country__c = 'United States',
            ucinn_ascendv2__External_System_ID__c = '3',
            HAM_External_System_ID__c = '33',
            HAM_Chapter__c = chapterNYC.Id
        );
        
        insert new List<ucinn_ascendv2__Address__c>{addressFLOR, addressCHI, addressNYC};

        Id conARRecordTypeId = Schema.SObjectType.ucinn_ascendv2__Address_Relation__c.getRecordTypeInfosByDeveloperName().get('Contact_Address_Relation').getRecordTypeId();
        
        ucinn_ascendv2__Address_Relation__c	arFLOR = new ucinn_ascendv2__Address_Relation__c(
        	ucinn_ascendv2__Contact__c = testCon.Id,
            HAM_Chapter__c = chapterFLOR.Id,
            ucinn_ascendv2__Address__c = addressFLOR.Id,
            ucinn_ascendv2__Status__c = 'Current',
            ucinn_ascendv2__Type__c = 'Business',
            RecordTypeId = conARRecordTypeId,
            ucinn_ascendv2__Start_Date__c = Date.ValueOf('2025-01-01')
        );
        
        ucinn_ascendv2__Address_Relation__c	arCHI = new ucinn_ascendv2__Address_Relation__c(
        	ucinn_ascendv2__Contact__c = testCon.Id,
            HAM_Chapter__c = chapterCHI.Id,
            ucinn_ascendv2__Address__c = addressCHI.Id,
            ucinn_ascendv2__Status__c = 'Current',
            ucinn_ascendv2__Type__c = 'Residence',
            RecordTypeId = conARRecordTypeId,
            ucinn_ascendv2__Start_Date__c = Date.ValueOf('2025-01-01')
        );
        
        ucinn_ascendv2__Address_Relation__c	arNYC = new ucinn_ascendv2__Address_Relation__c(
        	ucinn_ascendv2__Contact__c = testCon.Id,
            HAM_Chapter__c = chapterNYC.Id,
            ucinn_ascendv2__Address__c = addressNYC.Id,
            ucinn_ascendv2__Status__c = 'Current',
            ucinn_ascendv2__Type__c = 'Business',
            RecordTypeId = conARRecordTypeId,
            ucinn_ascendv2__Start_Date__c = Date.ValueOf('2025-01-01')
        );

        insert new List<ucinn_ascendv2__Address_Relation__c>{arFLOR, arCHI, arNYC};        
    }
    
    @isTest
    public static void testCurrentChaptersPositive(){
        List<ucinn_ascendv2__Address_Relation__c> testARs = [
            SELECT Id, HAM_Chapter__c, ucinn_ascendv2__Type__c, ucinn_ascendv2__Status__c, ucinn_ascendv2__Contact__c, HAM_Chapter__r.Name, HAM_Chapter__r.HAM_Chapter_Code__c
            FROM ucinn_ascendv2__Address_Relation__c
        ];
        
        ContactCurrentChaptersUtility.updateCurrentChapterOnContact(testARs);
        
        Contact updatedContact = [SELECT Id, HAM_Current_Chapters__c FROM Contact];
        Assert.areEqual('Florida (Orlando) - FLOR, Illinois (Chicago) - CHIL, New York (New York City) - NYNY', updatedContact.HAM_Current_Chapters__c);

        ucinn_ascendv2__Address_Relation__c ar = [
            SELECT Id, ucinn_ascendv2__Status__c
            FROM ucinn_ascendv2__Address_Relation__c
            WHERE HAM_Chapter__r.HAM_Chapter_Code__c = 'NYNY'
        ];

        ar.ucinn_ascendv2__Status__c = 'Former';
        update ar;

        updatedContact = [SELECT Id, HAM_Current_Chapters__c FROM Contact];
        Assert.areEqual('Florida (Orlando) - FLOR, Illinois (Chicago) - CHIL', updatedContact.HAM_Current_Chapters__c);
    }

    @isTest
    public static void testCurrentChaptersNegative(){
        ucinn_ascendv2__Address_Relation__c nycAR = [
            SELECT Id, HAM_Chapter__c, ucinn_ascendv2__Contact__c, HAM_Chapter__r.Name, HAM_Chapter__r.HAM_Chapter_Code__c
            FROM ucinn_ascendv2__Address_Relation__c
            WHERE HAM_Chapter__r.Name = 'New York (New York City)'
        ];
        nycAR.ucinn_ascendv2__Status__c = 'Former';
        update nycAR;

        List<ucinn_ascendv2__Address_Relation__c> testARs = [
            SELECT Id, HAM_Chapter__c, ucinn_ascendv2__Contact__c, HAM_Chapter__r.Name, HAM_Chapter__r.HAM_Chapter_Code__c
            FROM ucinn_ascendv2__Address_Relation__c
        ];

        ContactCurrentChaptersUtility.updateCurrentChapterOnContact(testARs);

        Contact updatedContact = [SELECT Id, HAM_Current_Chapters__c FROM Contact];
        Assert.areEqual('Florida (Orlando) - FLOR, Illinois (Chicago) - CHIL', updatedContact.HAM_Current_Chapters__c);
    }
}