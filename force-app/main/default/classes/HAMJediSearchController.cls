public with sharing class HAMJediSearchController {
   @AuraEnabled(cacheable=false)
    public static List<Contact> searchContact(string searchStr, string donorId, string classYear, string sportsAssociation, string studentOrganization) {

        List<String> whereConditions = new List<String>();

        // Add name search condition
        if(String.isNotBlank(searchStr)){
            whereConditions.add('HAM_Name_w_Suffix__c LIKE \'%' + String.escapeSingleQuotes(searchStr) + '%\'');
        }

        // Add donor ID condition
        if(String.isNotBlank(donorId)){
            whereConditions.add('ucinn_ascendv2__Donor_ID__c = \'' + String.escapeSingleQuotes(donorId) + '\'');
        }

        // Add Class Year condition
        if(String.isNotBlank(classYear)){
            whereConditions.add('HAM_Reunion_Year__c = \'' + String.escapeSingleQuotes(classYear) + '\'');
        }

        // Check if we have involvement filters
        Boolean hasSportsAssociation = String.isNotBlank(sportsAssociation);
        Boolean hasStudentOrganization = String.isNotBlank(studentOrganization);
        Boolean hasInvolvementFilters = hasSportsAssociation || hasStudentOrganization;

        if(whereConditions.isEmpty() && !hasInvolvementFilters) {
            // No search criteria provided
            return new List<Contact>();
        }

        if(!hasInvolvementFilters) {
            // Simple query without involvement join
            String queryString = 'SELECT ID, Name, HAM_Name_w_Suffix__c, HAM_Institutional_Suffix__c, ucinn_ascendv2__Primary_Contact_Type__c, ucinn_ascendv2__Donor_ID__c, HAM_PreferredEmail__c, HAM_Formatted_Phone__c FROM Contact WHERE ';
            queryString += String.join(whereConditions, ' AND ');
            queryString += ' ORDER BY HAM_Name_w_Suffix__c ASC';
            
            system.debug('=== SIMPLE QUERY (NO INVOLVEMENT FILTERS) ===');
            system.debug('Query Str -----'+queryString);
            List<Contact> constitiuents = Database.query(queryString);
            system.debug('Query Results Count -----'+constitiuents.size());
            return constitiuents;
        } 
        
        // INVOLVEMENT FILTERS LOGIC
        Set<Id> sportsContactIds = new Set<Id>();
        Set<Id> organizationContactIds = new Set<Id>();
        Set<Id> finalContactIds = new Set<Id>();

        // Query for Sports Association
        if(hasSportsAssociation) {
            String sportsQuery = 'SELECT ucinn_ascendv2__Contact__c FROM ucinn_ascendv2__Involvement__c WHERE ucinn_ascendv2__Involvement_Code_Description_Formula__c = \'' + String.escapeSingleQuotes(sportsAssociation) + '\'';
            
            system.debug('Sports Query: ' + sportsQuery);
            List<ucinn_ascendv2__Involvement__c> sportsInvolvements = Database.query(sportsQuery);
            
            for(ucinn_ascendv2__Involvement__c inv : sportsInvolvements) {
                if(inv.ucinn_ascendv2__Contact__c != null) {
                    sportsContactIds.add(inv.ucinn_ascendv2__Contact__c);
                }
            }
            system.debug('Sports Contact Ids Count: ' + sportsContactIds.size());
            system.debug('Sports Contact Ids: ' + sportsContactIds);
        }

        // Query for Student Organization
        if(hasStudentOrganization) {
            String orgQuery = 'SELECT ucinn_ascendv2__Contact__c FROM ucinn_ascendv2__Involvement__c WHERE ucinn_ascendv2__Involvement_Code_Description_Formula__c = \'' + String.escapeSingleQuotes(studentOrganization) + '\'';
            
            system.debug('Organization Query: ' + orgQuery);
            List<ucinn_ascendv2__Involvement__c> orgInvolvements = Database.query(orgQuery);
            
            for(ucinn_ascendv2__Involvement__c inv : orgInvolvements) {
                if(inv.ucinn_ascendv2__Contact__c != null) {
                    organizationContactIds.add(inv.ucinn_ascendv2__Contact__c);
                }
            }
            system.debug('Organization Contact Ids Count: ' + organizationContactIds.size());
            system.debug('Organization Contact Ids: ' + organizationContactIds);
        }

        // Combine results using OR logic: union of both sets
        if(hasSportsAssociation && hasStudentOrganization) {
            finalContactIds = new Set<Id>(sportsContactIds);
            finalContactIds.addAll(organizationContactIds);  // OR logic - union of both
            system.debug('Both filters selected - combining with OR logic');
        } else if(hasSportsAssociation) {
            finalContactIds = sportsContactIds;
            system.debug('Only Sports filter selected');
        } else if(hasStudentOrganization) {
            finalContactIds = organizationContactIds;
            system.debug('Only Organization filter selected');
        }

        // If no contacts found from involvement query, return empty list
        if(finalContactIds.isEmpty()) {
            system.debug('No contacts found - returning empty list');
            return new List<Contact>();
        }

        // Add contact ID condition
        whereConditions.add('ID IN (\'' + String.join(new List<Id>(finalContactIds), '\',\'') + '\')');

        String queryString = 'SELECT ID, Name, HAM_Name_w_Suffix__c, HAM_Institutional_Suffix__c, ucinn_ascendv2__Primary_Contact_Type__c, ucinn_ascendv2__Donor_ID__c, HAM_PreferredEmail__c, HAM_Formatted_Phone__c FROM Contact WHERE ';
        queryString += String.join(whereConditions, ' AND ');
        queryString += ' ORDER BY HAM_Name_w_Suffix__c ASC';
        
        system.debug('=== FINAL QUERY WITH INVOLVEMENT FILTERS ===');
        system.debug('Sports Association: ' + sportsAssociation);
        system.debug('Student Organization: ' + studentOrganization);
        system.debug('Final Contact IDs Count: ' + finalContactIds.size());
        system.debug('Final Contact IDs: ' + String.join(new List<Id>(finalContactIds), ', '));
        system.debug('Final Query: ' + queryString);
        
        List<Contact> constitiuents = Database.query(queryString);
        system.debug('Final Results Count: ' + constitiuents.size());
        return constitiuents;
    }

    @AuraEnabled(cacheable=true)
    public static List<Contact> searchRecentRecords() {
        List<Contact> recentlyViewedRecords= [SELECT ID, Name,HAM_Name_w_Suffix__c,ucinn_ascendv2__Donor_ID__c FROM Contact WHERE LastViewedDate != NULL ORDER BY LastViewedDate DESC Limit 10];
        return recentlyViewedRecords;
    }

    @AuraEnabled(cacheable=true)
    public static List<String> getClassYearOptions() {
        List<String> classYears = new List<String>();
        
        try {
            List<AggregateResult> results = [
                SELECT HAM_Reunion_Year__c 
                FROM Contact 
                WHERE HAM_Reunion_Year__c != null 
                GROUP BY HAM_Reunion_Year__c 
                ORDER BY HAM_Reunion_Year__c ASC
            ];
            
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

    @AuraEnabled(cacheable=true)
    public static List<String> getSportsAssociationOptions() {
        List<String> sportsAssociations = new List<String>();
        
        try {
            List<ucinn_ascendv2__Involvement_Value__c> results = [
                SELECT id, Name, HAM_Category__c, ucinn_ascendv2__Involvement_Description__c, ucinn_ascendv2__Type__c 
                FROM ucinn_ascendv2__Involvement_Value__c 
                WHERE HAM_Category__c = 'Student NCAA Athletics'
                ORDER BY ucinn_ascendv2__Involvement_Description__c ASC
            ];
            
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

    @AuraEnabled(cacheable=true)
    public static List<String> getStudentOrganizationsOptions() {
        List<String> studentOrganizations = new List<String>();
        
        try {
            List<ucinn_ascendv2__Involvement_Value__c> results = [
                SELECT id, Name, HAM_Category__c, ucinn_ascendv2__Involvement_Description__c, ucinn_ascendv2__Type__c 
                FROM ucinn_ascendv2__Involvement_Value__c 
                WHERE HAM_Category__c = 'Student Clubs' OR HAM_Category__c = 'Student Private Societies'
                ORDER BY ucinn_ascendv2__Involvement_Description__c ASC
            ];
            
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