public with sharing class HamGivingPageController {
    // String resp= HamGivingPageController.createExperienceCloudUser('jezkie00secondary@gmail.com', 'Partner Community Login User');
    @AuraEnabled
    public static string createExperienceCloudUser(String email, String profileName){
        String msg = 'User created successfully.';

        List<Profile> profiles = [SELECT Id FROM Profile WHERE Name = :profileName];
        List<Contact> foundContacts = [SELECT Id, Email, FirstName, LastName, AccountId FROM Contact WHERE Email = :email];

        if (profiles == null || profiles.size() == 0) {
            return 'Unable to create Experience Cloud User. Profile not found.';
        }
        if (foundContacts == null || foundContacts.size() == 0) {
            return 'Unable to create Experience Cloud User. Contact not found.';
        }

        Contact foundContact = foundContacts[0];

        User newUser = buildUser(foundContact, profiles[0]);

        try {
            insert newUser;
        } catch (DmlException dmlEx) {
            System.debug('@@dmlEx = ' + dmlEx.getMessage());
            msg = dmlEx.getMessage();
        } catch (Exception e) {
            msg = e.getMessage();
        }

        // String userID = Site.createPortalUser(newUser, foundContact.AccountId, null, true);
        System.debug('@@userID = ' + newUser.Id);

        return msg;

    }

    @TestVisible
    private static User buildUser(Contact foundContact, Profile profile) {
        User newUser = new User();
        newUser.ContactId = foundContact.Id;
        newUser.Username = generateUserName(foundContact);
        newUser.Email = foundContact.Email;
        newUser.FirstName = foundContact.FirstName;
        newUser.LastName = foundContact.LastName;
        newUser.CommunityNickname = foundContact.FirstName + foundContact.LastName + + System.hashCode(foundContact.Id);
        newUser.ProfileId = profile.Id;
        newUser.LocaleSidKey = 'en_US';
        newUser.TimeZoneSidKey = 'America/Los_Angeles';
        newUser.LanguageLocaleKey = 'en_US';
        newUser.Alias = foundContact.FirstName.substring(0, 1) + foundContact.LastName.substring(0, 1);
        newUser.EmailEncodingKey = 'UTF-8';

        return newUser;
    }

    @TestVisible
    private static String generateUserName(Contact foundContact) {
        return foundContact.Email.substring(0, foundContact.Email.indexOf('@')) + '+' + 'giving_page' + foundContact.Email.substring(foundContact.Email.indexOf('@'));
    }
}