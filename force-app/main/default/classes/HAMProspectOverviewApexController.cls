public with sharing class HAMProspectOverviewApexController {
    @AuraEnabled(cacheable=true)
    public static Contact searchProspectDetails(String contactId) {
        Contact objProspect = [SELECT ID, Name,HAM_Parents__c,HAM_Name_w_Suffix__c,ucinn_ascendv2__Donor_ID__c, ucinn_ascendv2__Contact_Type__c, HAM_Preferred_Chapter_Lookup__c,HAM_Preferred_Chapter_Lookup__r.name, HAM_Profile_Picture_URL__c,HAM_Current_Chapters__c,HAM_Alternate_Chapter__c,HAM_Alternate_Chapter__r.name, HAM_Phone_and_Type__c,HAM_PreferredEmail__c,HAM_LiveAlumni_Employer__c,HAM_LiveAlumni_Job_Title__c,ucinn_ascendv2__Preferred_Address_Formula__c,ucinn_ascendv2__PRM__c,ucinn_ascendv2__PRM__r.Name, ucinn_ascendv2__Preferred_Spouse__c,ucinn_ascendv2__Preferred_Spouse__r.name, HAM_Children__c,ucinn_ascendv2__Gender__c,Birthdate FROM Contact WHERE Id =:contactId];
        system.debug('recentlyViewedRecords-----'+objProspect);
        return objProspect;
    }

    @AuraEnabled(cacheable=true)
    public static ContactWrapper searchProspectGivingDetails(String contactId) {
        Contact objProspect = [SELECT ID, Name,HAM_Consecutive_Years_of_Giving__c, HAM_Total_Years_of_Giving__c, HAM_Lifetime_Committed__c, HAM_Lifetime_Paid__c,HAM_Current_Yr_Hamilton_Fund_Fundraising__c, HAM_Current_Year_Hamilton_Fund_Collected__c,
        HAM_1812__c, HAM_Founders_Circle__c,HAM_Ten_to_Fifth__c,HAM_Chapel_Bell__c,HAM_Couper_Guild__c,HAM_JBA__c,HAM_JBA_Anonymous__c, HAM_Lifetime_Committed_w_BQI__c, HAM_Lifetime_Bequest_Intention__c,
        HAM_Largest_gift_Amount__c,HAM_Largest_gift_Date__c,HAM_Largest_gift_purpose__c,HAM_Largest_Pledge_Amount__c,HAM_Largest_Pledge_Date__c,HAM_Largest_Pledge_Purpose__c,
        HAM_Largest_AF_gift_Amount__c,HAM_Largest_AF_gift_Date__c,HAM_Largest_AF_gift_Purpose__c,HAM_Largest_AF_Pledge_Amount__c,HAM_Largest_AF_Pledge_Date__c,HAM_Largest_AF_Pledge_Purpose__c,HAM_Last_Gift_Amount__c,HAM_Last_Gift_Date__c, HAM_Current_FY_Paid__c, ucinn_ascendv2__Wealth_Rating__c   
        FROM Contact WHERE Id =:contactId];
        system.debug('recentlyViewedRecords-----'+objProspect);
        String designationRecordTypeID = Schema.SObjectType.ucinn_ascendv2__Designation__c.getRecordTypeInfosByName().get('Fund').getRecordTypeId();

        List<ucinn_ascendv2__Designation_Stewardship__c> designations = [SELECT HAM_Fund_Name__c, ID FROM ucinn_ascendv2__Designation_Stewardship__c WHERE ucinn_ascendv2__Contact_Stewardee__c =:contactId AND ucinn_ascendv2__Status__c = 'Current' AND  HAM_Reporting_Type__c != 'None' AND  ucinn_ascendv2__Designation__r.HAM_Fund_Status__c != 'Inactive' AND ucinn_ascendv2__Designation__r.RecordTypeId =: designationRecordTypeID];
        system.debug('recentlyGiving Designations-----'+designations);    
        ContactWrapper objWrapper = new ContactWrapper();
        objWrapper.objRecord = objProspect;
        objWrapper.designations = designations; 
       return objWrapper;
    }

    @AuraEnabled(cacheable=true)
    public static ContactWrapper searchIndicatorDetails(String contactId) {
        ContactWrapper objWrapper = new ContactWrapper();
        objWrapper.isDeceased = false;
        objWrapper.isDoNotContact = false;
        Contact objProspect = [SELECT ID, ucinn_ascendv2__Is_Deceased__c FROM Contact WHERE Id =:contactId];
        system.debug('recentlyViewedRecords-----'+objProspect);
        objWrapper.isDeceased = objProspect.ucinn_ascendv2__Is_Deceased__c;
        Integer serviceIndicatorCount = [SELECT Count() FROM ucinn_ascendv2__Service_Indicator__c WHERE ucinn_ascendv2__Contact__c =:contactId AND ucinn_ascendv2__Service_Indicator_Description_Formula__c = 'No Contact with Hamilton'];
        if(serviceIndicatorCount > 0){
            objWrapper.isDoNotContact = true;
        }
        return objWrapper;
    }

     @AuraEnabled(cacheable=true)
    public static DegreeWrapper searchProspectEducation(String contactId) {
        DegreeWrapper objWrapper = new DegreeWrapper();
        
        objWrapper.hamiltonDegree = getDegreeRecord(contactId);

        objWrapper = getProspectInvolments(contactId, objWrapper);

        return objWrapper;
    }

    public static ucinn_ascendv2__Degree_Information__c getDegreeRecord(String contactId){
        String hamiltonDegreeType= 'Hamilton/Kirkland Degree Information';
        Map<String, Schema.RecordTypeInfo> recordTypeInfo = Schema.SObjectType.ucinn_ascendv2__Degree_Information__c.getRecordTypeInfosByName();
        system.debug('Record Type values---'+recordTypeInfo.keySet());
        Schema.RecordTypeInfo rt = recordTypeInfo.get(hamiltonDegreeType);
        Id recordTypeId;
        if (rt != null) {
            recordTypeId = rt.getRecordTypeId();
        }
        ucinn_ascendv2__Degree_Information__c objHamiltonDegree = new ucinn_ascendv2__Degree_Information__c();
        system.debug('recordTypeId---'+recordTypeId);
        system.debug('contactId---'+contactId);
        objHamiltonDegree = [SELECT ID, Name,ucinn_ascendv2__Major_Formula__c,ucinn_ascendv2__Minor_Formula__c,ucinn_ascendv2__Conferred_Degree_Year__c,HAM_Reunion_Milestone_Year__c FROM ucinn_ascendv2__Degree_Information__c WHERE ucinn_ascendv2__Contact__c =:contactId AND RecordTypeID =: recordTypeId ORDER BY CreatedDate DESC LIMIT 1];
        return objHamiltonDegree;
    }
    public static  DegreeWrapper getProspectInvolments(String contactId, DegreeWrapper objWrapper){
        List<ucinn_ascendv2__Involvement__c> involments = new list<ucinn_ascendv2__Involvement__c>();
        involments = [SELECT ucinn_ascendv2__Involvement_Code_Description_Formula__c, HAM_Category__c,ucinn_ascendv2__Award_Honor_Rec_d_Date__c,ucinn_ascendv2__Involvement_Code__c, ucinn_ascendv2__Involvement_Code__r.Name FROM ucinn_ascendv2__Involvement__c WHERE ucinn_ascendv2__Contact__c =:contactId];
        system.debug('involments---------'+involments);
        String athletics = '';
        String club = '';
        String societies = '';
        List<ucinn_ascendv2__Designation_Beneficiary__c> awards =  new list<ucinn_ascendv2__Designation_Beneficiary__c>();
        awards = [SELECT ID, Name,ucinn_ascendv2__Type__c,ucinn_ascendv2__Designation__c,ucinn_ascendv2__Designation__r.ucinn_ascendv2__Designation_Name__c, ucinn_ascendv2__Designation__r.ucinn_ascendv2__Fund_Name__c,ucinn_ascendv2__Fiscal_Year__c FROM ucinn_ascendv2__Designation_Beneficiary__c WHERE ucinn_ascendv2__Contact__c =:contactId WITH SECURITY_ENFORCED];
        system.debug('awards------'+awards);
        for(ucinn_ascendv2__Involvement__c involvement:involments){
            if(involvement.HAM_Category__c == 'Student NCAA Athletics'){
                athletics += involvement.ucinn_ascendv2__Involvement_Code_Description_Formula__c + ', ';
            }else if(involvement.HAM_Category__c == 'AwardHonor'){
              
            }else if(involvement.HAM_Category__c == 'Student Clubs'){
                club += involvement.ucinn_ascendv2__Involvement_Code_Description_Formula__c + ', ';
            }else if(involvement.HAM_Category__c == 'Student Private Societies'){
                societies += involvement.ucinn_ascendv2__Involvement_Code_Description_Formula__c + ', ';
            }
        }

        objWrapper.athletics = athletics.removeEnd(', ');
        objWrapper.clubs = club.removeEnd(', ');
        objWrapper.societies = societies.removeEnd(', ');
        objWrapper.awards = awards;
        return objWrapper;
    }

    public class ContactWrapper{
        @AuraEnabled
        public Contact objRecord;
        @AuraEnabled
        public List<ucinn_ascendv2__Designation_Stewardship__c> designations;
        @AuraEnabled
        public Boolean isDeceased;
        @AuraEnabled
        public Boolean isDoNotContact;
    }

    Public class DegreeWrapper{
        @AuraEnabled
        public ucinn_ascendv2__Degree_Information__c hamiltonDegree;
        @AuraEnabled
        public String athletics;
        @AuraEnabled
        public String clubs;
        @AuraEnabled
        public String societies;
        @AuraEnabled
        public List<ucinn_ascendv2__Designation_Beneficiary__c> awards;
    }

    // Method to parse HAM_Children__c string and create clickable links for children
    // Matches children by HAM_Name_w_Suffix__c field (includes graduation year)
    @AuraEnabled(cacheable=true)
    public static List<ChildContact> getChildrenLinks(String childrenString) {
        List<ChildContact> childContacts = new List<ChildContact>();

        if (String.isBlank(childrenString)) {
            return childContacts;
        }

        // Split by comma
        List<String> childNames = childrenString.split(',');
        List<String> cleanNames = new List<String>();

        for (String name : childNames) {
            String cleanName = name.trim();
            if (!String.isBlank(cleanName)) {
                cleanNames.add(cleanName);
            }
        }

        if (cleanNames.isEmpty()) {
            return childContacts;
        }

        // Query Contacts by HAM_Name_w_Suffix__c which includes graduation year
        List<Contact> contacts = [
            SELECT Id, Name, HAM_Name_w_Suffix__c
            FROM Contact
            WHERE HAM_Name_w_Suffix__c IN :cleanNames
            LIMIT 50
        ];

        // Build response with original display name and Contact ID
        for (String originalName : childNames) {
            String cleanName = originalName.trim();

            // Find matching contact by HAM_Name_w_Suffix__c
            Contact matchedContact = null;
            for (Contact c : contacts) {
                if (c.HAM_Name_w_Suffix__c == cleanName) {
                    matchedContact = c;
                    break;
                }
            }

            if (matchedContact != null) {
                childContacts.add(new ChildContact(
                    cleanName,
                    matchedContact.Id
                ));
            } else {
                // No match found - still add without link
                childContacts.add(new ChildContact(
                    cleanName,
                    null
                ));
            }
        }

        return childContacts;
    }

    public class ChildContact {
        @AuraEnabled public String displayName;
        @AuraEnabled public String contactId;

        public ChildContact(String displayName, String contactId) {
            this.displayName = displayName;
            this.contactId = contactId;
        }
    }
}