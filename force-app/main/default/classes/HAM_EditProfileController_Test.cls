/**
 * @description Test class for `HAM_EditProfileController`. This class provides comprehensive test coverage
 * for methods that handle a user's profile information, including retrieval, saving, and profile picture management.
 * It uses a `@testSetup` method to create all necessary data and trigger handlers in a controlled environment.
 * @Author : Cube84 - Sachin
 * @Last Modified By : Sachin
 * @Last Modified On : August 28, 2025
 * @Modification Log :
 * ==============================================================================
 * Ver | Date | Author | Modification
 *==============================================================================
 * 1.0 | August 28, 2025 |  Sachin | Initial Version
 */
@IsTest
public class HAM_EditProfileController_Test {
    /**
     * @description Test setup method to create all necessary data for the test methods.
     * This ensures all tests run in a predictable state with consistent data.
     * It creates a test user, various custom settings, a contact with related records, and a portal user.
     */
    @TestSetup
    static void setup() {

        // Query a role to assign to the test user
        UserRole ur = [SELECT Id FROM UserRole Where Name = 'Admin' LIMIT 1];
        
        // Create an internal user with a role
        User internalUser = new User(
            FirstName = 'Test',
            LastName = 'Owner',
            Email = 'testowner' + System.currentTimeMillis() + '@example.com',
            Username = 'testowner' + System.currentTimeMillis() + '@example.com',
            Alias = 'towner',
            TimeZoneSidKey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1].Id,
            UserRoleId = ur.Id
        );
        insert internalUser;
        System.runAs(internalUser) {
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
            insert addrRelHandler;

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

            // Create Account (Employer)
            Account acc1 = new Account(Name = 'Test Account', OwnerId = internalUser.Id);
            Account acc2 = new Account(Name = 'Test Employer');
            insert new List<Account>{acc1, acc2}; 

            // Create Contact
            Contact con = new Contact(
                FirstName = 'John',
                LastName = 'Doe',
                Job_Title__c = 'Developer',
                HAM_LiveAlumni_LinkedIn_URL__c = 'https://linkedin.com/in/test',
                HAM_Profile_Picture_URL__c = 'https://img.com/pic.jpg',
                AccountId = acc1.Id,
                Constituent_Employer__c = acc2.Id,
                ucinn_ascendv2__Contact_Type__c = 'Employee',
                Phone = '(415) 555-1788'
            );
            insert con;

            HAM_Chapter_Lookup__c chapterFLOR = new HAM_Chapter_Lookup__c(
                Name = 'Florida (Orlando)',
                HAM_Chapter_Code__c = 'FLOR',
                HAM_Chapter_Type__c = 'Domestic'
            );
            insert chapterFLOR;

            HAM_ChapterZipCode__c flZip = new HAM_ChapterZipCode__c(
                HAM_Chapter_Lookup__c = chapterFLOR.Id,
                HAM_Zip_Code__c = '32830'
            );
            insert flZip;

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
            insert addressFLOR;

            Id conARRecordTypeId = Schema.SObjectType.ucinn_ascendv2__Address_Relation__c.getRecordTypeInfosByDeveloperName().get('Contact_Address_Relation').getRecordTypeId();

            ucinn_ascendv2__Address_Relation__c  arFLOR = new ucinn_ascendv2__Address_Relation__c(
                ucinn_ascendv2__Contact__c = con.Id,
                HAM_Chapter__c = chapterFLOR.Id,
                ucinn_ascendv2__Address__c = addressFLOR.Id,
                ucinn_ascendv2__Status__c = 'Current',
                ucinn_ascendv2__Type__c = 'Business',
                RecordTypeId = conARRecordTypeId,
                ucinn_ascendv2__Start_Date__c = Date.ValueOf('2025-01-01'),
                ucinn_ascendv2__Is_Preferred__c = true
            );
            insert arFLOR;

            // Create User
            String loggedInUsrEmail = [Select Id,Email from User Where Id = :UserInfo.getUserId()]?.Email;
            Profile p = [SELECT Id FROM Profile WHERE Name='Partner Community Login User' LIMIT 1];
            User u = new User(
                Username = 'testuserhameditprofile@test.com',
                Email = loggedInUsrEmail,
                LastName = 'Doe',
                Alias = 'jdoe',
                TimeZoneSidKey = 'America/New_York',
                LocaleSidKey = 'en_US',
                EmailEncodingKey = 'UTF-8',
                ProfileId = p.Id,
                LanguageLocaleKey = 'en_US',
                ContactId = con.Id
            );
            insert u;
        }
    }

    /**
     * @description Test case to verify that `getMyPersonalInformation` successfully retrieves
     * and correctly populates the `PersonalInfoWrapper` with data from a Contact and its related records.
     */
    @IsTest
    static void testGetMyPersonalInformation() {
        Contact c = [SELECT Id FROM Contact LIMIT 1];
        Test.startTest();
        HAM_EditProfileController.PersonalInfoWrapper info = HAM_EditProfileController.getMyPersonalInformation(c.Id);
        Test.stopTest();
        System.assertEquals('John', info.firstName);
        System.assertEquals('Doe', info.lastName);
        System.assertNotEquals(null, info.addressInfo);
        System.assertEquals('Orlando', info.addressInfo.city);
    }

    /**
     * @description Test case to verify that `saveMyPersonalInformation` correctly updates
     * multiple fields on the Contact record and inserts new related records for phone, email, and address.
     */
    @IsTest
    static void testSaveMyPersonalInformation_UpdateFields() {
        Contact c = [SELECT Id, HAM_Formatted_Phone__c, HAM_PreferredEmail__c FROM Contact LIMIT 1];
        // Insert a phone and email for update coverage
        ucinn_ascendv2__Phone__c phone = new ucinn_ascendv2__Phone__c(
            ucinn_ascendv2__Phone_Number__c = c.HAM_Formatted_Phone__c,
            ucinn_ascendv2__Contact__c = c.Id
        );
        insert phone;
        ucinn_ascendv2__Email__c email = new ucinn_ascendv2__Email__c(
            ucinn_ascendv2__Email_Address__c = c.HAM_PreferredEmail__c,
            ucinn_ascendv2__Contact__c = c.Id
        );
        insert email;

        // Prepare wrapper
        HAM_EditProfileController.PersonalInfoWrapper wrap = new HAM_EditProfileController.PersonalInfoWrapper();
        wrap.constId = c.Id;
        wrap.firstName = 'Jane';
        wrap.lastName = 'Smith';
        wrap.jobTitle = 'Architect';
        wrap.employerName = 'Test Employer';
        wrap.phoneNo = '(415) 555-1789';
        wrap.email = 'jane.smith@example.com';
        wrap.profilePictureUrl = 'https://img.com/newpic.jpg';
        wrap.linkedInUrl = 'https://linkedin.com/in/janesmith';
        wrap.addressInfo = new HAM_EditProfileController.AddressWrapper();
        wrap.addressInfo.street = '456 Elm St';
        wrap.addressInfo.city = 'Columbus';
        wrap.addressInfo.state = 'OH';
        wrap.addressInfo.country = 'USA';
        wrap.addressInfo.county = 'Franklin';
        wrap.addressInfo.postalCode = '43004';

        String jsonWrap = JSON.serialize(wrap);

        Test.startTest();
        String result = HAM_EditProfileController.saveMyPersonalInformation(jsonWrap, c.Id, null);
        Test.stopTest();
        System.assertEquals('Success', result);

        // Check address was inserted
        List<ucinn_ascendv2__Address__c> addrs = [SELECT Id FROM ucinn_ascendv2__Address__c WHERE ucinn_ascendv2__Address_Line_1__c = '456 Elm St'];
        System.assert(!addrs.isEmpty());
    }

    /**
     * @description Test case to ensure `saveMyPersonalInformation` handles a new employer name
     * by successfully updating the contact and not throwing an error if the new employer is not found.
     */
    @IsTest
    static void testSaveMyPersonalInformation_NewEmployer() {
        Contact c = [SELECT Id FROM Contact LIMIT 1];
        // Prepare wrapper with new employer
        HAM_EditProfileController.PersonalInfoWrapper wrap = new HAM_EditProfileController.PersonalInfoWrapper();
        wrap.constId = c.Id;
        wrap.firstName = 'John';
        wrap.lastName = 'Doe';
        wrap.jobTitle = 'Developer';
        wrap.employerName = 'New Employer';
        wrap.phoneNo = '(415) 555-1789';
        wrap.email = 'john.doe@example.com';
        wrap.profilePictureUrl = 'https://img.com/pic.jpg';
        wrap.linkedInUrl = 'https://linkedin.com/in/test';
        wrap.addressInfo = new HAM_EditProfileController.AddressWrapper();
        String jsonWrap = JSON.serialize(wrap);

        Test.startTest();
        String result = HAM_EditProfileController.saveMyPersonalInformation(jsonWrap, c.Id, null);
        Test.stopTest();
        System.assertEquals('Success', result);
    }

    /**
     * @description Test case to verify that `saveMyPersonalInformation` returns an error message
     * when a non-existent contact ID is provided.
     */
    @IsTest
    static void testSaveMyPersonalInformation_ErrorContactNotFound() {
        HAM_EditProfileController.PersonalInfoWrapper wrap = new HAM_EditProfileController.PersonalInfoWrapper();
        wrap.constId = '003000000000000AAA';
        wrap.firstName = 'Ghost';
        String jsonWrap = JSON.serialize(wrap);

        Test.startTest();
        String result = HAM_EditProfileController.saveMyPersonalInformation(jsonWrap, '003000000000000AAA', null);
        Test.stopTest();
        System.assert(result.startsWith('Error'));
    }

    /**
     * @description Test case to verify that `saveMyPersonalInformation` correctly links a
     * newly uploaded profile picture (ContentDocument) to the Contact record.
     */
    @IsTest
    static void testSaveMyPersonalInformation_ContentDocLink() {
        Contact c = [SELECT Id FROM Contact LIMIT 1];
        // Prepare wrapper
        HAM_EditProfileController.PersonalInfoWrapper wrap = new HAM_EditProfileController.PersonalInfoWrapper();
        wrap.constId = c.Id;
        wrap.firstName = 'John';
        wrap.lastName = 'Doe';
        wrap.jobTitle = 'Developer';
        wrap.employerName = 'Test Employer';
        wrap.phoneNo = '(415) 555-1789';
        wrap.email = 'john.doe@example.com';
        wrap.profilePictureUrl = 'https://img.com/pic.jpg';
        wrap.linkedInUrl = 'https://linkedin.com/in/test';
        wrap.addressInfo = new HAM_EditProfileController.AddressWrapper();
        String jsonWrap = JSON.serialize(wrap);

        // Insert ContentDocument
        ContentVersion cv = new ContentVersion(
            Title = 'TestDoc',
            PathOnClient = 'TestDoc.pdf',
            VersionData = Blob.valueOf('Test')
        );
        insert cv;
        Id docId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId;

        Test.startTest();
        String result = HAM_EditProfileController.saveMyPersonalInformation(jsonWrap, c.Id, docId);
        system.debug('<<result saveMyPersonalInformation>>'+result);
        System.assertEquals('Success', result);
        System.assertEquals(1, [SELECT COUNT() FROM ContentDocumentLink WHERE ContentDocumentId = :docId AND LinkedEntityId = :c.Id]);
        Test.stopTest();
    }

    /**
     * @description Test case to verify that `uploadProfilePic` successfully uploads a file
     * and returns a valid ContentDocumentId.
     */
    @IsTest
    static void testUploadProfilePic() {
        String fileName = 'profile.jpg';
        String base64Data = EncodingUtil.base64Encode(Blob.valueOf('testdata'));
        Test.startTest();
        String docId = HAM_EditProfileController.uploadProfilePic(fileName, base64Data);
        Test.stopTest();
        System.assertNotEquals(null, docId);
    }

    /**
     * @description Test case to verify that `deleteProfilePic` successfully deletes a ContentDocument.
     */
    @IsTest
    static void testDeleteProfilePic_Success() {
        // Insert ContentDocument
        ContentVersion cv = new ContentVersion(
            Title = 'DeleteMe',
            PathOnClient = 'DeleteMe.jpg',
            VersionData = Blob.valueOf('delete')
        );
        insert cv;
        Id docId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId;

        Test.startTest();
        String result = HAM_EditProfileController.deleteProfilePic(docId);
        Test.stopTest();
        System.assertEquals('Success', result);
    }

    /**
     * @description Test case to verify that `deleteProfilePic` throws an exception
     * when a non-existent ContentDocumentId is provided.
     */
    @IsTest
    static void testDeleteProfilePic_NotFound() {
        Test.startTest();
        try {
            HAM_EditProfileController.deleteProfilePic('069000000000000AAA');
            System.assert(false, 'Exception should have been thrown');
        } catch (AuraHandledException e) {
        }
        Test.stopTest();
    }

    /**
     * @description Test case for the helper method `areStringsDifferent` to ensure
     * it correctly compares two strings, including identical strings.
     */
    @IsTest
    static void testAreStringsDifferent() {
        System.assertEquals(false, HAM_EditProfileController.areStringsDifferent('s1','s1'), 'It should return false');
    }
}