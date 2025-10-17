/**
* @File Name : HAM_AlumniDirectoryController.cls
* @Description : This class is used to fetch all contact details on alumni directory page, based on user search.
* @Author : Cube84 - Sachin
* @Last Modified By : Sachin
* @Last Modified On : August 28, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | August 28, 2025 |  Sachin | Initial Version
* 1.1 | Sept 04, 2025 |  Sachin |  Done as part of Optimization
* 1.2 | Sept 29, 2025 |  Sachin |  updated buildWhereClause to incorporate middle name in search key using ucinn_ascendv2__Expanded_Name_Formula__c
* 1.3 | Oct 03, 2025 |  Sachin |  updated buildWhereClause to add default filter: exclude records with primary constituent type ('Student' AND 'Friend') And only include records with HAM_Is_Active__c = true. 
**/
public without sharing class HAM_AlumniDirectoryController {
    // A wrapper class to structure the output data as required by the front end
    public class AlumniCardData {
        @AuraEnabled public Id contactId;
        @AuraEnabled public String contactName;
        @AuraEnabled public String profilePictureUrl;
        @AuraEnabled public List<FieldWrapper> fields;
    }

    // Wrapper to hold a field's value and its order
    public class FieldWrapper implements Comparable {
        @AuraEnabled public String label;
        @AuraEnabled public Decimal order;
        @AuraEnabled public Object value; 
        @AuraEnabled public Object isCustom;

        public Integer compareTo(Object obj) {
            FieldWrapper other = (FieldWrapper)obj;
            if (this.order == other.order) {
                return 0;
            }
            return (this.order > other.order) ? 1 : -1; // Ascending
        }
    }

    // Wrapper class to pass filter metadata and options to the LWC
    public class FilterWrapper {
        @AuraEnabled public String fieldApiName;
        @AuraEnabled public String placeholder;
        @AuraEnabled public String type;
        @AuraEnabled public Decimal order;
        @AuraEnabled public List<String> values;
    }
    
    /**
    * @description: Method to fetch HAM_Filters__mdt field configuration. 
    *               Based on the metadata configuration fetch actual filter values whether it is a picklist value or custom values assigned in metadata
    * @return:      List<FilterWrapper> - A list of HAM_Filters__mdt metadata records
    **/
    @AuraEnabled(cacheable=true)
    public static List<FilterWrapper> getFilterMetadataAndValues() {
        List<HAM_Filters__mdt> filtersMetadata = [SELECT Id, HAM_Reference_Type__c, HAM_Reference_Object_API__c, HAM_Reference_Field_API__c, HAM_Reference_Values__c, HAM_Order__c, HAM_Placeholder__c FROM HAM_Filters__mdt WITH SECURITY_ENFORCED ORDER BY HAM_Order__c];
        List<FilterWrapper> filterWrappers = new List<FilterWrapper>();
        
        for (HAM_Filters__mdt filterMdt : filtersMetadata) {
            FilterWrapper fw = new FilterWrapper();
            fw.fieldApiName = filterMdt.HAM_Reference_Field_API__c; // Used for actual value retrieval
            fw.placeholder = filterMdt.HAM_Placeholder__c;
            fw.type = filterMdt.HAM_Reference_Type__c;
            fw.order = filterMdt.HAM_Order__c;
            fw.values = new List<String>();

            if (filterMdt.HAM_Reference_Type__c == HAM_ConstantsUtil.PICKLIST ) {
                // Call the getPicklistValues private method for picklist logic
                // fw.values = getPicklistValues(filterMdt.HAM_Reference_Object_API__c, filterMdt.HAM_Reference_Field_API__c);
            } else if (filterMdt.HAM_Reference_Type__c == HAM_ConstantsUtil.CUSTOM && String.isNotBlank(filterMdt.HAM_Reference_Values__c)) {
                // Handle multiple delimiters: comma, semicolon, newline
                fw.values.addAll(filterMdt.HAM_Reference_Values__c.split('[,;\\n]+'));
                // Trim whitespace from each value
                for(Integer i = 0; i < fw.values.size(); i++) {
                    fw.values[i] = fw.values[i].trim();
                }
            }
            filterWrappers.add(fw);
        }
        return filterWrappers;
    }

    /**
    * @description Retrieves the picklist values for a given SObject and field API name.
    * @param sObjName The API name of the SObject (e.g., 'Contact').
    * @param fieldName The API name of the picklist field (e.g., 'Industry').
    * @return A list of picklist values as strings. Returns an empty list if the SObject or field is invalid, or if the field is not a picklist.
    */
    // @TestVisible
    // private static List<String> getPicklistValues(String sObjName, String fieldName) {
    //     List<String> picklistValues = new List<String>();
    //     try {
    //         if (String.isNotBlank(sObjName) && String.isNotBlank(fieldName)) {
    //             SObjectType sObjType = Schema.getGlobalDescribe().get(sObjName);
    //             if (sObjType != null) {
    //                 Map<String, SObjectField> fieldMap = sObjType.getDescribe().fields.getMap();
    //                 DescribeFieldResult fieldDesc = (fieldMap.containsKey(fieldName)) ? fieldMap.get(fieldName).getDescribe() : null;
    //                 Boolean isPicklist = (fieldDesc != null && fieldDesc.getType() == Schema.DisplayType.Picklist);
    //                 List<PicklistEntry> picklistEntries = isPicklist ? fieldDesc.getPicklistValues() : new List<PicklistEntry>();
    //                 for (PicklistEntry p: picklistEntries) {
    //                     picklistValues.add(p.getValue());
    //                 }
    //             }
    //         }
    //     } catch (Exception e) {
    //         System.debug('Error getting picklist values for object: ' + sObjName + ', field: ' + fieldName + '. Error: ' + e.getMessage());
    //     }
    //     return picklistValues;
    // }
    
    /**
    * @description: Method to fetch total constituent record number based on user search input. 
    * @param:       searchKey - string input in search bar from the user.
    * @param:       selectedFilters - List<Map<String, String>> it is the selected filter on the UI Eg; (placeholder: Class Year, Value: 1979)
    * @return:      Integer - Number of records found in database.
    **/
    @AuraEnabled(cacheable=true)
    public static Integer getAlumniRecordCount(String searchKey, List<Map<String, String>> selectedFilters) {
        if((searchKey == null || String.isBlank(searchKey)) && selectedFilters.isEmpty()){
            return 0;
        }
        else{
            String whereClause = buildWhereClause(searchKey, selectedFilters);
            String queryString = 'SELECT COUNT() FROM Contact ' + whereClause;
            try {
                return Database.countQuery(queryString);
            } catch(QueryException e) {
                System.debug('Count Query Error: ' + e.getMessage());
                return 0;
            }
        }        
    }

    /**
    * @description: Method to fetch all constituent records based on user search input. 
    * @param:       searchKey - string input in search bar from the user.
    * @param:       selectedFilters - List<Map<String, String>> it is the selected filter on the UI Eg; (placeholder: Class Year, Value: 1979)
    * @param:       Integer pageSize - number of records to be displayed at a time.
    * @param:       Integer recordsToSkip - acts as offset to skip records. Eg: (On page-1 display records 1-9 and on page-72 records 649-657)
    * @return:      List<AlumniCardData> - List of wrapper object.
    **/
    @AuraEnabled(cacheable=true)
    public static List<AlumniCardData> getAlumniRecords(Integer pageSize, Integer recordsToSkip, String searchKey, List<Map<String, String>> selectedFilters) {
        
        if((searchKey == null || String.isBlank(searchKey)) && selectedFilters.isEmpty()){
            return new List<AlumniCardData>();
        }
        else {
            String whereClause = buildWhereClause(searchKey, selectedFilters);
            
            String lastRecordName;
            Set<String> fieldApiNames = new Set<String>();
            String whereClauseImpactMetadata = 'HAM_Level_1__c IN (\'Alumni\') AND HAM_Level_2__c IN (\'Alumni Display\')';
            List<HAM_MyImpactController.MyImpactMetadata> myImpactMetadataFieldsToQuery = HAM_MyImpactController.getMyImpactMetadata(whereClauseImpactMetadata);
            
            for(HAM_MyImpactController.MyImpactMetadata field : myImpactMetadataFieldsToQuery) {
                fieldApiNames.add(field.fieldApiName);
            }
            fieldApiNames.add('HAM_Profile_Picture_URL__c');
            
            String queryFields = String.join(new List<String>(fieldApiNames), ', ');
            String degreeSubquery = '(SELECT Id, ucinn_ascendv2__Major_Degree_Formula__c FROM ucinn_ascendv2__Degree_Information_Contact__r where RecordType.DeveloperName = \'School_Degree_Information\')';
            String queryString = 'SELECT Id, Name, '+ queryFields +', '+ degreeSubquery + ' FROM Contact ' + whereClause;
            
            // page 1
            if(recordsToSkip == 0 && (lastRecordName == null || String.isBlank(lastRecordName))){
                queryString += ' ORDER BY Name ASC LIMIT :pageSize';
                
            }
            // pages greater than 1
            else {
                String query = 'SELECT Id, Name from Contact ' + whereClause + ' ORDER BY Name ASC LIMIT :recordsToSkip';
                List<Contact> lstContact = Database.query(query);
                system.debug('lstContact: '+ lstContact);
                lastRecordName = (lstContact != null && !lstContact.isEmpty()) ? lstContact[recordsToSkip-1].Name : null;
                queryString = (lastRecordName != null) ? (queryString  + ' AND Name > :lastRecordName ORDER BY Name ASC LIMIT :pageSize') : queryString;
            }
            system.debug('<<queryString>>'+queryString);
            List<Contact> alumniContacts = new List<Contact>();
            try {
                alumniContacts = Database.query(queryString);
                system.debug('alumniContacts: '+alumniContacts.size());
            } catch (System.QueryException e) {  
                System.debug('Query Error: ' + e.getMessage());
                return new List<AlumniCardData>();
            }
            List<AlumniCardData> alumniCards = new List<AlumniCardData>();
            
            for (Contact con : alumniContacts) {
                AlumniCardData card = new AlumniCardData();
                card.contactId = con.Id;
                card.contactName = con.Name;
                card.profilePictureUrl = con.HAM_Profile_Picture_URL__c;
                card.fields = new List<FieldWrapper>();
                
                for (HAM_MyImpactController.MyImpactMetadata metadata : myImpactMetadataFieldsToQuery) {
                    FieldWrapper field = new FieldWrapper();
                    field.label = metadata.displayLabel;
                    field.order = metadata.displayOrder;
                    
                    if (metadata.fieldApiName.contains('.')) {
                        // Handle relationship fields (Parent field)
                        String[] parts = metadata.fieldApiName.split('\\.');
                        SObject relatedObject = con.getSObject(parts[0]);
                        if (relatedObject != null) {
                            field.value = relatedObject.get(parts[1]);
                        } else {
                            field.value = null;
                        }
                    }
                    else {
                        field.value = con.get(metadata.fieldApiName);
                    }
                    
                    card.fields.add(field);
                }
                FieldWrapper fieldDeg = new FieldWrapper();
                fieldDeg.label = System.label.ham_Degree;
                fieldDeg.order = 2;
                fieldDeg.isCustom = true; // Indicating this is a custom field
                for (ucinn_ascendv2__Degree_Information__c degree : con.ucinn_ascendv2__Degree_Information_Contact__r){   
                    if(degree.ucinn_ascendv2__Major_Degree_Formula__c != null){
                        fieldDeg.value = (fieldDeg.value == null) ? degree.ucinn_ascendv2__Major_Degree_Formula__c
                        : fieldDeg.value + '; ' + degree.ucinn_ascendv2__Major_Degree_Formula__c; 
                    }  
                }

                card.fields.add(fieldDeg);
                card.fields.sort();
                alumniCards.add(card);
                
            }
            return alumniCards; 
        }  
    }

    /**
    * @description: builds the where clause dynamically for alumni directory. 
    * @param:       searchKey - string input in search bar from the user.
    * @param:       selectedFilters - List<Map<String, String>> it is the selected filter on the UI Eg; (placeholder: Class Year, Value: 1979)
    * @return:      String - a dynamically build where clause string.
    **/
    private static String buildWhereClause(String searchKey, List<Map<String, String>> selectedFilters) {
        List<String> conditions = new List<String>();

        if(System.Label.ham_AlumniDefaultFilter != 'null'){            
            conditions.add(System.Label.ham_AlumniDefaultFilter);
        }

        if (String.isNotBlank(searchKey)) {
            for(String key: searchKey.split(' ')){
                conditions.add('ucinn_ascendv2__Expanded_Name_Formula__c LIKE \'%' + String.escapeSingleQuotes(key) + '%\'');
            }            
        }

        List<HAM_Filters__mdt> allFiltersMdt = [SELECT HAM_Direct_Filter__c, HAM_Direct_Filter_Field__c, HAM_Related_Filter_Object__c, HAM_Related_Reference_Filter_Field__c,HAM_Related_Reference_Filter__c, HAM_Placeholder__c FROM HAM_Filters__mdt WITH SECURITY_ENFORCED];
        Map<String, HAM_Filters__mdt> filterMetadataMap = new Map<String, HAM_Filters__mdt>();
        for (HAM_Filters__mdt mdt : allFiltersMdt) {
            filterMetadataMap.put(mdt.HAM_Placeholder__c, mdt);
        }

        for (Map<String, String> filter : selectedFilters) {
            String placeholder = filter.get('placeholder');
            String value = filter.get('value');

            if (filterMetadataMap.containsKey(placeholder) && String.isNotBlank(value)) {
                HAM_Filters__mdt mdt = filterMetadataMap.get(placeholder);
                if (mdt.HAM_Direct_Filter__c) {
                    // Direct filter
                    conditions.add(mdt.HAM_Direct_Filter_Field__c + ' = \'' + String.escapeSingleQuotes(value) + '\'');
                } else {
                    // Subquery filter
                    String subquery = 'Id IN (SELECT '+ mdt.HAM_Related_Reference_Filter_Field__c + ' FROM ' +
                                    mdt.HAM_Related_Filter_Object__c + ' WHERE ' +
                                    mdt.HAM_Related_Reference_Filter__c + ' = \'' + String.escapeSingleQuotes(value) + '\')';
                    conditions.add(subquery);
                }
            }
        }
        return conditions.isEmpty() ? '' : 'WHERE ' + String.join(conditions, ' AND ');
    }

    /**
    * @description: Method to save slected filters as json string for the looge in user in HAM_Portal_User_Preference__c object. 
    * @param:       filtersJson - json input of selected filters from the user.
    * @param:       currentContactId - contactId of the logged in portal user.
    **/
    @AuraEnabled
    public static void saveUserPreferences(String filtersJson, String currentContactId ) {
        
        if (currentContactId != null) {
            List<HAM_Portal_User_Preference__c> existingPreferences = [
                SELECT Id, Alumni_Filter__c
                FROM HAM_Portal_User_Preference__c
                WHERE Portal_Contact__c = :currentContactId
                LIMIT 1
            ];
            
            if (!existingPreferences.isEmpty()) {
                HAM_Portal_User_Preference__c preferenceToUpdate = existingPreferences[0];
                preferenceToUpdate.Alumni_Filter__c = filtersJson;
                update preferenceToUpdate;
            } else {
                HAM_Portal_User_Preference__c newPreference = new HAM_Portal_User_Preference__c();
                newPreference.Alumni_Filter__c = filtersJson;
                newPreference.Portal_Contact__c = currentContactId;
                insert newPreference;
            }
        }
    }

    //  method to get saved user preferences
    @AuraEnabled
    public static String getSavedUserPreferences(String currentContactId) {
        
        if (currentContactId != null) {
            List<HAM_Portal_User_Preference__c> existingPreferences = [
                SELECT Alumni_Filter__c
                FROM HAM_Portal_User_Preference__c
                WHERE Portal_Contact__c = :currentContactId
                LIMIT 1
            ];
            
            if (!existingPreferences.isEmpty()) {
                return existingPreferences[0].Alumni_Filter__c;
            }
        }
        return null;
    }
}