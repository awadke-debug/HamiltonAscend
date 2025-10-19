public with sharing class HAMJediSearchController {
   @AuraEnabled(cacheable=false)
    public static List<Contact> searchContact(string searchStr, string donorId, string classYear, string sportsAssociation, string studentOrganization) {

        String searchName = '\'%' + searchStr + '%\'';
        String queryString = 'SELECT ID, Name,HAM_Name_w_Suffix__c,HAM_Institutional_Suffix__c,ucinn_ascendv2__Primary_Contact_Type__c, ucinn_ascendv2__Donor_ID__c, HAM_PreferredEmail__c, HAM_Formatted_Phone__c FROM Contact WHERE ';
        
        List<String> whereConditions = new List<String>();

        // Add name search condition
        if(String.isNotBlank(searchStr)){
            whereConditions.add('HAM_Name_w_Suffix__c LIKE '+searchName);
        }

        // Add donor ID condition
        if(String.isNotBlank(donorId)){
            whereConditions.add('ucinn_ascendv2__Donor_ID__c= '+'\''+donorId+'\'');
        }

        // Add Class Year condition
        if(String.isNotBlank(classYear)){
            whereConditions.add('HAM_Reunion_Year__c = '+'\''+classYear+'\'');
        }

        // Add Sports Association and Student Organization conditions (need to join with Involvement records)
        // Build the query differently if we need involvement filters
        Boolean hasInvolvementFilters = String.isNotBlank(sportsAssociation) || String.isNotBlank(studentOrganization);

        if(whereConditions.isEmpty() && !hasInvolvementFilters) {
            // No search criteria provided
            return new List<Contact>();
        }

        if(!hasInvolvementFilters) {
            // Simple query without involvement join
            queryString += String.join(whereConditions, ' AND ');
            queryString+= ' ORDER BY HAM_Name_w_Suffix__c ASC';
            system.debug('Query Str -----'+queryString);
            List<Contact> constitiuents = Database.query(queryString);
            system.debug('Query Results -----'+constitiuents);
            return constitiuents;
        } else {
            // Need to join with Involvement records
            Set<Id> contactIds = new Set<Id>();

            String involvementQuery = 'SELECT ucinn_ascendv2__Contact__c FROM ucinn_ascendv2__Involvement__c WHERE ';
            List<String> involvementConditions = new List<String>();

            if(String.isNotBlank(sportsAssociation)) {
                involvementConditions.add('ucinn_ascendv2__Involvement_Value__r.ucinn_ascendv2__Involvement_Description__c = '+'\''+sportsAssociation+'\'');
            }

            if(String.isNotBlank(studentOrganization)) {
                involvementConditions.add('ucinn_ascendv2__Involvement_Value__r.ucinn_ascendv2__Involvement_Description__c = '+'\''+studentOrganization+'\'');
            }

            if(!involvementConditions.isEmpty()) {
                involvementQuery += String.join(involvementConditions, ' OR ');

                List<ucinn_ascendv2__Involvement__c> involvements = Database.query(involvementQuery);
                
                for(ucinn_ascendv2__Involvement__c inv : involvements) {
                    if(inv.ucinn_ascendv2__Contact__c != null) {
                        contactIds.add(inv.ucinn_ascendv2__Contact__c);
                    }
                }
            }

            // If no contacts found from involvement query, return empty list
            if(contactIds.isEmpty()) {
                return new List<Contact>();
            }

            // Add contact ID condition
            whereConditions.add('ID IN ' + '(\'' + String.join(new List<Id>(contactIds), '\',\'') + '\')');

            queryString += String.join(whereConditions, ' AND ');
            queryString+= ' ORDER BY HAM_Name_w_Suffix__c ASC';
            system.debug('Query Str -----'+queryString);
            List<Contact> constitiuents = Database.query(queryString);
            system.debug('Query Results -----'+constitiuents);
            return constitiuents;
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<Contact> searchRecentRecords() {
        List<Contact> recentlyViewedRecords= [SELECT ID, Name,HAM_Name_w_Suffix__c,ucinn_ascendv2__Donor_ID__c FROM Contact WHERE LastViewedDate != NULL ORDER BY LastViewedDate DESC Limit 10];
        return recentlyViewedRecords;
    }

    // NEW METHOD: Fetch unique Class Year values
    @AuraEnabled(cacheable=true)
    public static List<String> getClassYearOptions() {
        List<String> classYears = new List<String>();
        
        try {
            // Query to get distinct HAM_Reunion_Year__c values
            List<AggregateResult> results = [
                SELECT HAM_Reunion_Year__c 
                FROM Contact 
                WHERE HAM_Reunion_Year__c != null 
                GROUP BY HAM_Reunion_Year__c 
                ORDER BY HAM_Reunion_Year__c ASC
            ];
            
            // Convert AggregateResult to String list
            for (AggregateResult ar : results) {
                String year = (String)ar.get('HAM_Reunion_Year__c');
                if (String.isNotBlank(year)) {
                    classYears.add(year);
                }
            }
            
            system.debug('Class Years Found: ' + classYears);
        } catch (Exception e) {
            system.debug('Error fetching class years: ' + e.getMessage());
            throw new AuraHandledException('Error retrieving class year options: ' + e.getMessage());
        }
        
        return classYears;
    }

    // NEW METHOD: Fetch Sports Association options (Student NCAA Athletics)
    @AuraEnabled(cacheable=true)
    public static List<String> getSportsAssociationOptions() {
        List<String> sportsAssociations = new List<String>();
        
        try {
            // Query to get Involvement Descriptions for Student NCAA Athletics
            List<ucinn_ascendv2__Involvement_Value__c> results = [
                SELECT id, Name, HAM_Category__c, ucinn_ascendv2__Involvement_Description__c, ucinn_ascendv2__Type__c 
                FROM ucinn_ascendv2__Involvement_Value__c 
                WHERE HAM_Category__c = 'Student NCAA Athletics'
                ORDER BY ucinn_ascendv2__Involvement_Description__c ASC
            ];
            
            // Extract unique Involvement Descriptions
            for (ucinn_ascendv2__Involvement_Value__c record : results) {
                String description = record.ucinn_ascendv2__Involvement_Description__c;
                if (String.isNotBlank(description) && !sportsAssociations.contains(description)) {
                    sportsAssociations.add(description);
                }
            }
            
            system.debug('Sports Associations Found: ' + sportsAssociations);
        } catch (Exception e) {
            system.debug('Error fetching sports associations: ' + e.getMessage());
            throw new AuraHandledException('Error retrieving sports association options: ' + e.getMessage());
        }
        
        return sportsAssociations;
    }

    // NEW METHOD: Fetch Student Organizations options (Student Clubs and Student Private Societies)
    @AuraEnabled(cacheable=true)
    public static List<String> getStudentOrganizationsOptions() {
        List<String> studentOrganizations = new List<String>();
        
        try {
            // Query to get Involvement Descriptions for Student Clubs and Student Private Societies
            List<ucinn_ascendv2__Involvement_Value__c> results = [
                SELECT id, Name, HAM_Category__c, ucinn_ascendv2__Involvement_Description__c, ucinn_ascendv2__Type__c 
                FROM ucinn_ascendv2__Involvement_Value__c 
                WHERE HAM_Category__c = 'Student Clubs' OR HAM_Category__c = 'Student Private Societies'
                ORDER BY ucinn_ascendv2__Involvement_Description__c ASC
            ];
            
            // Extract unique Involvement Descriptions
            for (ucinn_ascendv2__Involvement_Value__c record : results) {
                String description = record.ucinn_ascendv2__Involvement_Description__c;
                if (String.isNotBlank(description) && !studentOrganizations.contains(description)) {
                    studentOrganizations.add(description);
                }
            }
            
            system.debug('Student Organizations Found: ' + studentOrganizations);
        } catch (Exception e) {
            system.debug('Error fetching student organizations: ' + e.getMessage());
            throw new AuraHandledException('Error retrieving student organizations options: ' + e.getMessage());
        }
        
        return studentOrganizations;
    }
}