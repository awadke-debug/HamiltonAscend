/**
 * @description Controller class for the `ham_editProfileCmp` LWC component. 
 * It provides methods to retrieve, update, and manage a user's personal information, 
 * including contact details, employment, address, and profile picture.
 * The class uses wrapper classes to handle complex data structures for communication with the client-side component.
 *
 * @author Sachin
 * @Last Modified On : August 28, 2025
 * @Modification Log :
 *==============================================================================
 * Ver | Date | Author | Modification
 *==============================================================================
 * 1.0 | August 28, 2025 |  Sachin | Initial Version
 * 1.1 | Sept 04, 2025 | Sachin |  Done as part of Optimization
 * 1.2 | Oct 07,2025 | Immanuel | Implemented the duplicate phone number detection
 * 1.3 | Oct 10,2025 | Sachin | Removed county field from UI and Backend
 */
public without sharing class HAM_EditProfileController {

    /**
     * @description Retrieves the personal information of the current user's contact record.
     * The method queries the Contact, its related Address, and Employer records.
     * The data is then mapped into a `PersonalInfoWrapper` for structured transfer to the LWC.
     *
     * @param currentUserContactId The ID of the Contact record for the logged-in user.
     * @return A `PersonalInfoWrapper` object containing the user's personal and address details.
     */
    @AuraEnabled(cacheable=true)
    public static PersonalInfoWrapper getMyPersonalInformation(String currentUserContactId) {
        
        // Query the main Contact record and its related Address and Employer.
        Contact con = (currentUserContactId != null) ? [Select Id,FirstName,LastName,Job_Title__c,HAM_LiveAlumni_LinkedIn_URL__c,HAM_PreferredEmail__c,HAM_Formatted_Phone__c,HAM_Profile_Picture_URL__c,Constituent_Employer__c,Constituent_Employer__r.Name,(Select Id,ucinn_ascendv2__Address__c from ucinn_ascendv2__Address_Relations_Contact__r Where ucinn_ascendv2__Is_Preferred__c = true) from Contact where Id = :currentUserContactId LIMIT 1] : null;

        // Retrieve the ID of the preferred address from the related list.   
        Id currentAddressId = (con != null && !con.ucinn_ascendv2__Address_Relations_Contact__r.isEmpty()) ? con.ucinn_ascendv2__Address_Relations_Contact__r[0].ucinn_ascendv2__Address__c : null;
        
        // Query the Address record using the retrieved ID.
        ucinn_ascendv2__Address__c currentConstituentAddress = (currentAddressId != null) ? [SELECT Id,ucinn_ascendv2__Address_Line_1__c,ucinn_ascendv2__City__c,ucinn_ascendv2__State__c,ucinn_ascendv2__Country__c,ucinn_ascendv2__Postal_Code__c FROM ucinn_ascendv2__Address__c WHERE Id = :currentAddressId LIMIT 1] : null;
        
        // Instantiate the wrapper object and populate its fields.
        PersonalInfoWrapper personalInfoWrap = new PersonalInfoWrapper();
        personalInfoWrap.constId = (con.Id != null) ? con.Id: '';
        personalInfoWrap.firstName = (con.FirstName != null) ? con.FirstName : '';
        personalInfoWrap.lastName = (con.LastName != null) ? con.LastName : '';
        personalInfoWrap.jobTitle = (con.Job_Title__c != null) ? con.Job_Title__c : '';
        personalInfoWrap.employerName = (con.Constituent_Employer__c != null && con.Constituent_Employer__r != null && con.Constituent_Employer__r.Name != null) ? con.Constituent_Employer__r.Name : '';
        personalInfoWrap.phoneNo = (con.HAM_Formatted_Phone__c != null) ? con.HAM_Formatted_Phone__c : '';
        personalInfoWrap.email = (con.HAM_PreferredEmail__c != null) ? con.HAM_PreferredEmail__c : '';
        personalInfoWrap.profilePictureUrl = (con.HAM_Profile_Picture_URL__c != null) ? con.HAM_Profile_Picture_URL__c : '';
        personalInfoWrap.linkedInUrl = (con.HAM_LiveAlumni_LinkedIn_URL__c != null) ? con.HAM_LiveAlumni_LinkedIn_URL__c : '';

        // Handle address information, creating a new AddressWrapper if an address exists.
        if(currentConstituentAddress != null) {
            personalInfoWrap.addressInfo = new AddressWrapper();
            personalInfoWrap.addressInfo.street = (currentConstituentAddress.ucinn_ascendv2__Address_Line_1__c != null) ? currentConstituentAddress.ucinn_ascendv2__Address_Line_1__c : '';
            personalInfoWrap.addressInfo.city = (currentConstituentAddress.ucinn_ascendv2__City__c != null) ? currentConstituentAddress.ucinn_ascendv2__City__c : '';
            personalInfoWrap.addressInfo.state = (currentConstituentAddress.ucinn_ascendv2__State__c != null) ? currentConstituentAddress.ucinn_ascendv2__State__c : '';
            personalInfoWrap.addressInfo.country = (currentConstituentAddress.ucinn_ascendv2__Country__c != null) ? currentConstituentAddress.ucinn_ascendv2__Country__c : '';
            personalInfoWrap.addressInfo.postalCode = (currentConstituentAddress.ucinn_ascendv2__Postal_Code__c != null) ? currentConstituentAddress.ucinn_ascendv2__Postal_Code__c : '';
        }else{
            // Initialize with an empty AddressWrapper if no address exists.
            personalInfoWrap.addressInfo = new AddressWrapper();
            personalInfoWrap.addressInfo.street = '';
            personalInfoWrap.addressInfo.city = '';
            personalInfoWrap.addressInfo.state = '';
            personalInfoWrap.addressInfo.country = '';
            personalInfoWrap.addressInfo.postalCode = '';
        }
        
        return personalInfoWrap;
    }

    /**
     * @description Saves the updated personal information and handles related DML operations.
     * This method is decorated with `@AuraEnabled(cacheable=false)` because it performs DML operations.
     *
     * @param personalInfoResp A JSON string of the `PersonalInfoWrapper` with updated values.
     * @param currentUserContactId The ID of the Contact record being updated.
     * @param contentDocId The ID of the ContentDocument if a new profile picture was uploaded.
     * @return A 'Success' message or an error string if an exception occurs.
     */
    @AuraEnabled(cacheable=false)
    public static string saveMyPersonalInformation(String personalInfoResp, String currentUserContactId, String contentDocId) {
        
        // Deserialize the JSON string back into the wrapper class.
        PersonalInfoWrapper personalInfoUpdated = (PersonalInfoWrapper) JSON.deserialize(personalInfoResp, PersonalInfoWrapper.class);
        
        try {
            // Start of Transaction

            // Re-query the Contact record to get the current state for comparison.
            Contact con = (currentUserContactId != null) ? [Select Id,FirstName,LastName,Name,ucinn_ascendv2__PRM__c,Job_Title__c,HAM_LiveAlumni_LinkedIn_URL__c,HAM_PreferredEmail__c,HAM_Formatted_Phone__c,HAM_Profile_Picture_URL__c,Constituent_Employer__c,Constituent_Employer__r.Name,(Select Id,ucinn_ascendv2__Address__c from ucinn_ascendv2__Address_Relations_Contact__r Where ucinn_ascendv2__Is_Preferred__c = true) from Contact where Id = :currentUserContactId LIMIT 1] : null;
            Id currentAddressId = (con != null && !con.ucinn_ascendv2__Address_Relations_Contact__r.isEmpty()) ? con.ucinn_ascendv2__Address_Relations_Contact__r[0].ucinn_ascendv2__Address__c : null;
            
            if (con == null) {
                return 'Error: Contact not found.';
            }

            // Create a list to hold all DML operations for a single transaction
            List<SObject> recordsToUpsert = new List<SObject>();
            List<Task> tasksToInsert = new List<Task>();
            Contact contactToUpdate = new Contact(Id = con.Id);
            boolean isContactUpdated = false;

            // DML PERMISSION CHECKS: Start
            Boolean hasContactAccess = Contact.sObjectType.getDescribe().isUpdateable() && Contact.sObjectType.getDescribe().isAccessible();
            Boolean hasPhoneAccess = ucinn_ascendv2__Phone__c.sObjectType.getDescribe().isAccessible() && ucinn_ascendv2__Phone__c.sObjectType.getDescribe().isUpdateable() && ucinn_ascendv2__Phone__c.sObjectType.getDescribe().isCreateable();
            Boolean hasEmailAccess = ucinn_ascendv2__Email__c.sObjectType.getDescribe().isAccessible() && ucinn_ascendv2__Email__c.sObjectType.getDescribe().isUpdateable() && ucinn_ascendv2__Email__c.sObjectType.getDescribe().isCreateable();            
            Boolean hasAddressAccess = ucinn_ascendv2__Address__c.sObjectType.getDescribe().isAccessible() && ucinn_ascendv2__Address__c.sObjectType.getDescribe().isCreateable();
            Boolean hasAddressRelationAccess = ucinn_ascendv2__Address_Relation__c.sObjectType.getDescribe().isAccessible() && ucinn_ascendv2__Address_Relation__c.sObjectType.getDescribe().isUpdateable() && ucinn_ascendv2__Address_Relation__c.sObjectType.getDescribe().isCreateable();

            Boolean hasContentDocLinkAccess = ContentDocumentLink.sObjectType.getDescribe().isAccessible() && ContentDocumentLink.sObjectType.getDescribe().isCreateable();
            // DML PERMISSION CHECKS: End

            // Handle Contact field updates
            if (personalInfoUpdated.firstName != null && personalInfoUpdated.firstName != con.FirstName) {
                contactToUpdate.FirstName = personalInfoUpdated.firstName;
                isContactUpdated = true;
            }
            if (personalInfoUpdated.lastName != null && personalInfoUpdated.lastName != con.LastName) {
                contactToUpdate.LastName = personalInfoUpdated.lastName;
                isContactUpdated = true;
            }
            if (personalInfoUpdated.jobTitle != null && personalInfoUpdated.jobTitle != con.Job_Title__c) {
                contactToUpdate.Job_Title__c = personalInfoUpdated.jobTitle;
                isContactUpdated = true;
            }
            if (personalInfoUpdated.linkedInUrl != null && personalInfoUpdated.linkedInUrl != con.HAM_LiveAlumni_LinkedIn_URL__c) {
                contactToUpdate.HAM_LiveAlumni_LinkedIn_URL__c = personalInfoUpdated.linkedInUrl;
                isContactUpdated = true;
            }
            if (personalInfoUpdated.profilePictureUrl != null && personalInfoUpdated.profilePictureUrl != con.HAM_Profile_Picture_URL__c) {
                contactToUpdate.HAM_Profile_Picture_URL__c = personalInfoUpdated.profilePictureUrl;
                isContactUpdated = true;
            }
            
            // Handle Phone updates
            //Remove white spaces and special characters from the existing and updated phones
            String existingPhone = (con.HAM_Formatted_Phone__c != null) ? con.HAM_Formatted_Phone__c.replaceAll('[^0-9]', '') : null;
            String updatedPhone = (personalInfoUpdated.phoneNo != null) ? personalInfoUpdated.phoneNo.replaceAll('[^0-9]', '') : null;

            if (existingPhone != null && updatedPhone != null && existingPhone != updatedPhone && hasPhoneAccess) {
                // Get existing phones for the respective contact and Remove white spaces and special characters from all of them
                ucinn_ascendv2__Phone__c existingPhoneRec;
                for(ucinn_ascendv2__Phone__c existingPhNo: [SELECT Id,ucinn_ascendv2__Phone_Number__c,ucinn_ascendv2__Is_Preferred__c  FROM ucinn_ascendv2__Phone__c WHERE ucinn_ascendv2__Contact__c = :con.Id Order By CreatedDate DESC]){
                    String formattedPhone = (existingPhNo.ucinn_ascendv2__Phone_Number__c != null) ? existingPhNo.ucinn_ascendv2__Phone_Number__c.replaceAll('[^0-9]', '') : null;
                    if(formattedPhone != null && formattedPhone == updatedPhone){    
                        existingPhoneRec = new ucinn_ascendv2__Phone__c();
                        existingPhoneRec = existingPhNo;
                        break;
                    }
                }

                //Check if the phone number is a new one, or en existing. If new create a new ucinn_ascendv2__Phone__c record, else just make it preferred
                if(existingPhoneRec != null){
                    existingPhoneRec.ucinn_ascendv2__Is_Preferred__c = true;
                    recordsToUpsert.add(existingPhoneRec);
                }else{
                    recordsToUpsert.add(new ucinn_ascendv2__Phone__c(
                        ucinn_ascendv2__Phone_Number__c = personalInfoUpdated.phoneNo,
                        ucinn_ascendv2__Contact__c = con.Id,
                        ucinn_ascendv2__Is_Preferred__c = true,
                        ucinn_ascendv2__Status__c = HAM_ConstantsUtil.CURRENT,
                        ucinn_ascendv2__Type__c = HAM_ConstantsUtil.CELL,
                        ucinn_ascendv2__Start_Date__c = Date.today()
                    ));
                }
            }

            // Handle Email updates
            if (personalInfoUpdated.email != null && personalInfoUpdated.email != con.HAM_PreferredEmail__c && hasEmailAccess) {                
                // Find or create the new email record
                List<ucinn_ascendv2__Email__c> existingEmails = [SELECT Id FROM ucinn_ascendv2__Email__c WHERE ucinn_ascendv2__Contact__c = :con.Id AND ucinn_ascendv2__Email_Address__c = :personalInfoUpdated.email];
                if (existingEmails.isEmpty()) {
                    recordsToUpsert.add(new ucinn_ascendv2__Email__c(
                        ucinn_ascendv2__Email_Address__c = personalInfoUpdated.email,
                        ucinn_ascendv2__Contact__c = con.Id,
                        ucinn_ascendv2__Is_Preferred__c = true,
                        ucinn_ascendv2__Status__c = HAM_ConstantsUtil.CURRENT,
                        ucinn_ascendv2__Type__c = HAM_ConstantsUtil.PERSONAL,
                        ucinn_ascendv2__Start_Date__c = Date.today()
                    ));
                } else {
                    existingEmails[0].ucinn_ascendv2__Is_Preferred__c = true;
                    recordsToUpsert.add(existingEmails[0]);
                }
            }

            // Handle Employer updates
            if (personalInfoUpdated.employerName != null && personalInfoUpdated.employerName != con.Constituent_Employer__r.Name ) {
                List<Account> accounts = [SELECT Id FROM Account WHERE Name = :personalInfoUpdated.employerName LIMIT 1];
                if (!accounts.isEmpty()) {
                    contactToUpdate.Constituent_Employer__c = accounts[0].Id;
                    isContactUpdated = true;
                } else if (System.Label.HAM_TaskOwnerId != 'null') {
                    tasksToInsert.add(new Task(
                        Subject = System.Label.HAM_EmployerChangeSubject + ' ' + con.Name,
                        OwnerId = System.Label.HAM_TaskOwnerId,
                        WhoId = con.Id,
                        Description = System.Label.HAM_EmployerChangeDesc + ' ' + personalInfoUpdated.employerName,
                        ActivityDate = Date.today().addDays(Integer.valueOf(System.label.HAM_TaskDueDuration))
                    ));
                }
            }

            // Handle Address updates
            if (personalInfoUpdated.addressInfo != null) {
                ucinn_ascendv2__Address__c oldAddressRelation = (currentAddressId != null) ? [SELECT Id,ucinn_ascendv2__Address_Line_1__c,ucinn_ascendv2__City__c,ucinn_ascendv2__State__c,ucinn_ascendv2__Country__c,ucinn_ascendv2__Postal_Code__c FROM ucinn_ascendv2__Address__c WHERE Id = :currentAddressId LIMIT 1] : null;      
                
                boolean isAddressChanged = false;

                if (oldAddressRelation != null) {
                    isAddressChanged = areStringsDifferent(personalInfoUpdated.addressInfo.street, oldAddressRelation.ucinn_ascendv2__Address_Line_1__c) ||
                                    areStringsDifferent(personalInfoUpdated.addressInfo.city, oldAddressRelation.ucinn_ascendv2__City__c) ||
                                    areStringsDifferent(personalInfoUpdated.addressInfo.state, oldAddressRelation.ucinn_ascendv2__State__c) ||
                                    areStringsDifferent(personalInfoUpdated.addressInfo.country, oldAddressRelation.ucinn_ascendv2__Country__c) ||
                                    
                                    areStringsDifferent(personalInfoUpdated.addressInfo.postalCode, oldAddressRelation.ucinn_ascendv2__Postal_Code__c);
                } else {
                    isAddressChanged = (personalInfoUpdated.addressInfo.street != null ||
                                    personalInfoUpdated.addressInfo.city != null ||
                                    personalInfoUpdated.addressInfo.state != null ||
                                    personalInfoUpdated.addressInfo.country != null ||
                                    personalInfoUpdated.addressInfo.postalCode != null);
                }
               
                if (isAddressChanged && hasAddressAccess && hasAddressRelationAccess) {                    
                    
                    // check if the user updated address has an existing ucinn_ascendv2__Address__c record
                    List<ucinn_ascendv2__Address__c> existingAddRecList = [SELECT Id, ucinn_ascendv2__Address_Line_1__c, ucinn_ascendv2__City__c, ucinn_ascendv2__State__c, ucinn_ascendv2__Country__c,ucinn_ascendv2__Postal_Code__c,
                                                                    (SELECT ID, ucinn_ascendv2__Account__c, ucinn_ascendv2__Contact__c,ucinn_ascendv2__Is_Preferred__c FROM ucinn_ascendv2__Address_Relations_Address__r)
                                                                    FROM ucinn_ascendv2__Address__c 
                                                                    WHERE ucinn_ascendv2__Address_Line_1__c =: (personalInfoUpdated.addressInfo.street != null) ? personalInfoUpdated.addressInfo.street : oldAddressRelation.ucinn_ascendv2__Address_Line_1__c
                                                                    AND ucinn_ascendv2__City__c =: (personalInfoUpdated.addressInfo.city != null) ? personalInfoUpdated.addressInfo.city : oldAddressRelation.ucinn_ascendv2__City__c
                                                                    AND ucinn_ascendv2__State__c =: (personalInfoUpdated.addressInfo.state != null) ? personalInfoUpdated.addressInfo.state : oldAddressRelation.ucinn_ascendv2__State__c
                                                                    AND ucinn_ascendv2__Country__c =: (personalInfoUpdated.addressInfo.country != null) ? personalInfoUpdated.addressInfo.country : oldAddressRelation.ucinn_ascendv2__Country__c
                                                                    AND ucinn_ascendv2__Postal_Code__c=: (personalInfoUpdated.addressInfo.postalCode != null) ? personalInfoUpdated.addressInfo.postalCode : oldAddressRelation.ucinn_ascendv2__Postal_Code__c
                                                                ];
                    System.debug('<existingAddRecList>'+ existingAddRecList);          
                    if(!existingAddRecList.isEmpty()){
                        ucinn_ascendv2__Address__c existingAddRec = existingAddRecList[0];
                        for (ucinn_ascendv2__Address_Relation__c addRelation: existingAddRec.ucinn_ascendv2__Address_Relations_Address__r){
                            if(addRelation.ucinn_ascendv2__Contact__c == currentUserContactId){
                                addRelation.ucinn_ascendv2__Is_Preferred__c = true;
                                recordsToUpsert.add(addRelation);
                                break;
                            }
                        }
                    }
                    else{

                        // Creating a new Address record by combining old and new values
                        ucinn_ascendv2__Address__c newAddress = new ucinn_ascendv2__Address__c();
                        
                        // Copy existing values from the old address first
                        if (oldAddressRelation != null) {
                            newAddress.ucinn_ascendv2__Address_Line_1__c = oldAddressRelation.ucinn_ascendv2__Address_Line_1__c;
                            newAddress.ucinn_ascendv2__City__c = oldAddressRelation.ucinn_ascendv2__City__c;
                            newAddress.ucinn_ascendv2__State__c = oldAddressRelation.ucinn_ascendv2__State__c;
                            newAddress.ucinn_ascendv2__Country__c = oldAddressRelation.ucinn_ascendv2__Country__c;
                            newAddress.ucinn_ascendv2__Postal_Code__c = oldAddressRelation.ucinn_ascendv2__Postal_Code__c;
                        }
                        
                        // Overwrite with new values if they exist
                        if (personalInfoUpdated.addressInfo.street != null) {
                            newAddress.ucinn_ascendv2__Address_Line_1__c = personalInfoUpdated.addressInfo.street;
                        }
                        if (personalInfoUpdated.addressInfo.city != null) {
                            newAddress.ucinn_ascendv2__City__c = personalInfoUpdated.addressInfo.city;
                        }
                        if (personalInfoUpdated.addressInfo.state != null) {
                            newAddress.ucinn_ascendv2__State__c = personalInfoUpdated.addressInfo.state;
                        }
                        if (personalInfoUpdated.addressInfo.country != null) {
                            newAddress.ucinn_ascendv2__Country__c = personalInfoUpdated.addressInfo.country;
                        }
                        if (personalInfoUpdated.addressInfo.postalCode != null) {
                            newAddress.ucinn_ascendv2__Postal_Code__c = personalInfoUpdated.addressInfo.postalCode;
                        }

                        Id currentUserId = UserInfo.getUserId();
                        createAscendBypassMethod(currentUserId);
                        insert newAddress;
                        removeAscendBypassMethod(currentUserId);

                        // Address Relation
                        if (con.Id != null) {
                            ucinn_ascendv2__Address_Relation__c newAddressRelation = new ucinn_ascendv2__Address_Relation__c(
                                ucinn_ascendv2__Contact__c = con.Id,
                                ucinn_ascendv2__Address__c = newAddress.Id, 
                                ucinn_ascendv2__Status__c = HAM_ConstantsUtil.CURRENT,
                                ucinn_ascendv2__Is_Preferred__c = true
                            );
                            insert newAddressRelation;
                        }

                    
                        if (System.Label.HAM_TaskOwnerId != 'null') {
                            tasksToInsert.add(new Task(
                                Subject = System.Label.HAM_AddressChangeSubject + ' ' + con.Name,
                                OwnerId = System.Label.HAM_TaskOwnerId,
                                WhoId = con.Id,
                                Description = System.Label.HAM_AddressChangeDesc +' ' + con.Name,
                                ActivityDate = Date.today().addDays(Integer.valueOf(System.label.HAM_TaskDueDuration))
                            ));
                        }
                    }

                  
                }
            }            
            
            // After other updates.
            if(contentDocId != null && hasContentDocLinkAccess) {
                ContentDocumentLink cdl = new ContentDocumentLink();
                cdl.ContentDocumentId = contentDocId;
                cdl.LinkedEntityId = currentUserContactId;
                cdl.ShareType = 'V';
                cdl.Visibility = HAM_ConstantsUtil.ALL_USERS;
                insert cdl;
                ContentDocument linkedDoc = [SELECT Title FROM ContentDocument WHERE Id = :contentDocId LIMIT 1];

                if (System.Label.HAM_TaskOwnerId != 'null') {
                    tasksToInsert.add(new Task(
                        Subject = System.Label.HAM_ProfilePicChangeSubject + ' ' + con.Name,
                        OwnerId = System.Label.HAM_TaskOwnerId,
                        WhoId = con.Id,
                        Description = System.Label.HAM_ProfilePicChangeDesc + ' ' + ((linkedDoc.Title != null) ? linkedDoc.Title : ' '),
                        ActivityDate = Date.today().addDays(Integer.valueOf(System.label.HAM_TaskDueDuration))
                    ));
                }
            }

            // Perform DML operations in a single block
            if (!recordsToUpsert.isEmpty()) {
                upsert recordsToUpsert;
            }
            if (isContactUpdated && hasContactAccess) {
                update contactToUpdate;
            }
            if (!tasksToInsert.isEmpty()) {
                insert tasksToInsert;
            }
            
            // End of Transaction
            return 'Success';

        } catch (Exception e) {
            System.debug('Error in saveMyPersonalInformation: ' + e.getMessage());
            // An error occurred, the entire transaction is rolled back.
            return 'Error: ' + e.getMessage();
        }
    }

    /**
     * @description A wrapper class to structure personal and professional information 
     * for easy serialization and deserialization between Apex and LWC.
     */
    public class PersonalInfoWrapper {
        @AuraEnabled public String constId;
        @AuraEnabled public String firstName;
        @AuraEnabled public String lastName;
        @AuraEnabled public String jobTitle;
        @AuraEnabled public String employerName;
        @AuraEnabled public String phoneNo;
        @AuraEnabled public String email;
        @AuraEnabled public String profilePictureUrl;
        @AuraEnabled public String linkedInUrl;
        @AuraEnabled public AddressWrapper addressInfo;
    }

    /**
     * @description A nested wrapper class to hold address information.
     */
    public class AddressWrapper {
        @AuraEnabled public String street;
        @AuraEnabled public String city;
        @AuraEnabled public String state;
        @AuraEnabled public String country;
        @AuraEnabled public String postalCode;
    }

    /**
     * @description Deletes an uploaded profile picture by deleting its ContentDocument record.
     * This is useful for cleaning up temporary files on a 'Cancel' action.
     *
     * @param contentDocId The ID of the ContentDocument to delete.
     * @return A 'Success' message or throws an `AuraHandledException` on failure.
     */
    @AuraEnabled(cacheable=false)
    public static String deleteProfilePic(String contentDocId) {
        try {
            ContentDocument cd = [SELECT Id FROM ContentDocument WHERE Id = :contentDocId];
            if(cd != null && ContentDocumentLink.sObjectType.getDescribe().isAccessible() && ContentDocumentLink.sObjectType.getDescribe().isDeletable() ) {
                delete cd;
                return 'Success';
            } else {
                throw new AuraHandledException('Content Document not found');
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * @description Helper method to check if two strings are different, handling null and empty values gracefully.
     * This method is marked with @TestVisible to be accessible from a test class for unit testing.
     *
     * @param s1 The first string to compare.
     * @param s2 The second string to compare.
     * @return True if the strings are different, otherwise false.
     */
    @TestVisible
    private static boolean areStringsDifferent(String s1, String s2) {
        // Treat both null and empty strings as equal for comparison.
        return String.isNotBlank(s1) != String.isNotBlank(s2) || (String.isNotBlank(s1) && s1 != s2);
    }

    /**
     * @description Helper method to create ucinn_ascendv2__Bypass_Settings__c record to bypass ascend validation while creating new address.
     * This method is marked with @TestVisible to be accessible from a test class for unit testing.
     *
     * @param userId 
     */
    @TestVisible
    private static void createAscendBypassMethod(Id userId) {
        ucinn_ascendv2__Bypass_Settings__c ascBypass = new ucinn_ascendv2__Bypass_Settings__c();
        ascBypass.SetupOwnerId = userId;
        ascBypass.ucinn_ascendv2__Bypass_Process_Builders__c = true;
        ascBypass.ucinn_ascendv2__Bypass_Triggers__c = true;
        ascBypass.ucinn_ascendv2__Bypass_Validation_Rules__c = true;
        ascBypass.ucinn_ascendv2__Bypass_Workflows__c = true;
        insert ascBypass;
    }

    /**
     * @description Helper method to delete ucinn_ascendv2__Bypass_Settings__c record to restore ascend validation logic.
     * This method is marked with @TestVisible to be accessible from a test class for unit testing.
     *
     * @param userId
     */
    @TestVisible
    private static void removeAscendBypassMethod(Id userId) {
        List<ucinn_ascendv2__Bypass_Settings__c> ascBypassList = new List<ucinn_ascendv2__Bypass_Settings__c>();
        ascBypassList = [Select Id,SetupOwnerId from ucinn_ascendv2__Bypass_Settings__c Where SetupOwnerId = :userId];
        if(!ascBypassList.isEmpty()) {
            delete ascBypassList;
        }
    }
}