/**
* @File Name : HAM_AlumniProfileOverviewController.cls
* @Description : This class is used to fetch contact's profile overview details on alumni directory page of the portal.
* @Author : Cube84 - Sachin
* @Last Modified By : Sachin
* @Last Modified On : August 28, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | August 28, 2025 |  Sachin | Initial Version
* 1.1 | Sep 03, 2025 |  Aswhin S | Optimization
* 1.2 | Sep 30, 2025 |  Sachin | removing residence halls value if primary constituent type is 'Student'.
**/
public without sharing class HAM_AlumniProfileOverviewController {
    // A wrapper class to structure the output data as required by the front end
    public class AlumniProfileOverviewCard {
        @AuraEnabled public Id contactId;
        @AuraEnabled public String contactName;
        @AuraEnabled public String contactEmail;
        @AuraEnabled public String contactlinkedIn;
        @AuraEnabled public String profilePictureUrl;
        @AuraEnabled public List<FieldWrapper> fields;
    }

    // Wrapper to hold a field's value and its order
    public class FieldWrapper implements Comparable {
        @AuraEnabled public String label;
        @AuraEnabled public Decimal order;
        @AuraEnabled public Object value;

        public Integer compareTo(Object obj) {
            FieldWrapper other = (FieldWrapper)obj;
            if (this.order == other.order) {
                return 0;
            }
            return (this.order > other.order) ? 1 : -1; // Ascending
        }
    }

    /*
    * @description: A method to retrieve an alumni contact's profile overview details dynamically.
    *               It fetches fields from a custom metadata type to build the query and a structured output.
    * @param:       contactId - The ID of the Contact record to retrieve.
    * @return:       A list of AlumniProfileOverviewCard wrapper objects. This list will contain a single card for the requested contact.
    */
    @AuraEnabled(cacheable=true)
    public static List<AlumniProfileOverviewCard> getAlumniOverview(String contactId) {

        // A set to store API names of standard and non-custom fields.
        Set<String> fieldApiNames = new Set<String>();

        // Define the WHERE clause for querying the custom metadata type.
        String whereClauseImpactMetadata = 'HAM_Level_1__c IN (\'Alumni\') AND HAM_Level_2__c IN (\'Alumni Profile Overview\')';

        // Retrieve metadata fields.
        List<HAM_MyImpactController.MyImpactMetadata> myImpactMetadataFieldsToQuery = HAM_MyImpactController.getMyImpactMetadata(whereClauseImpactMetadata);
        
        for(HAM_MyImpactController.MyImpactMetadata field : myImpactMetadataFieldsToQuery) {
            if(field.type != HAM_ConstantsUtil.CUSTOM){
                fieldApiNames.add(field.fieldApiName);
            }
        }
        fieldApiNames.add('HAM_Profile_Picture_URL__c');

        // Define the WHERE clause for the main Contact query.
        String whereClause = ' Where Id = :contactId';

        // Join all non-custom field API names into a single string for the SELECT clause.
        String queryFields = String.join(new List<String>(fieldApiNames), ', ');

        // Define the subquery for related Degree Information records.
        String degreeSubquery = '(SELECT Id, ucinn_ascendv2__Major_Degree_Formula__c, ucinn_ascendv2__Second_Major_Formula__c,Third_Concentration_Formula__c,ucinn_ascendv2__Minor_Degree_Formula__c,Second_Minor__c,Third_Minor__c, RecordType.DeveloperName FROM ucinn_ascendv2__Degree_Information_Contact__r)';

        // Define the subquery for related Involvement records.
        String involvmentSubquery = '(SELECT Id, HAM_Category__c, ucinn_ascendv2__Involvement_Code_Description_Formula__c FROM ucinn_ascendv2__Involvements_Contact__r)';
        
        // Construct the final dynamic SOQL query string.
        String queryString = 'SELECT Id, HAM_Name_w_Suffix__c, Email, ucinn_ascendv2__Primary_Contact_Type__c, HAM_LiveAlumni_LinkedIn_URL__c, ' + queryFields + ', ' + degreeSubquery + ', ' + involvmentSubquery + ' FROM Contact ' + whereClause;
        
        List<Contact> alumniContacts = new List<Contact>();
        try {
            alumniContacts = Database.query(queryString);
        } catch (System.QueryException e) {
            System.debug('Query Error: ' + e.getMessage());
            return new List<AlumniProfileOverviewCard>();
        }
        
        // List to store the final structured data for the UI.
        List<AlumniProfileOverviewCard> alumniProfileOverview = new List<AlumniProfileOverviewCard>();
        
        // Process the queried contact records.
        for (Contact con : alumniContacts) {
            // Create a new wrapper card for the current contact.
            AlumniProfileOverviewCard card = new AlumniProfileOverviewCard();

            // Map standard Contact fields to the wrapper class properties.
            card.contactId = con.Id;
            card.contactEmail = con.Email;
            card.contactName = con.HAM_Name_w_Suffix__c;
            card.contactlinkedIn = con.HAM_LiveAlumni_LinkedIn_URL__c;
            card.profilePictureUrl = con.HAM_Profile_Picture_URL__c;
            card.fields = new List<FieldWrapper>();
            
            for (HAM_MyImpactController.MyImpactMetadata metadata : myImpactMetadataFieldsToQuery) {
                if(metadata.fieldApiName != HAM_ConstantsUtil.RESIDENCE_HALLS || con.ucinn_ascendv2__Primary_Contact_Type__c != HAM_ConstantsUtil.STUDENT){
                    FieldWrapper field = new FieldWrapper();
                    field.label = metadata.displayLabel;
                    field.order = metadata.displayOrder;
                    
                    if(metadata.type == HAM_ConstantsUtil.CUSTOM) {
                        // Call the helper method to handle custom fields
                        field.value = getCustomFieldValue(con, metadata.fieldApiName);
                    } else {
                        if (metadata.fieldApiName.contains('.')) {
                            String[] parts = metadata.fieldApiName.split('\\.');
                            SObject relatedObject = con.getSObject(parts[0]);
                            if (relatedObject != null) {
                                field.value = relatedObject.get(parts[1]);
                            } else {
                                field.value = null;
                            }
                        } else {
                            field.value = con.get(metadata.fieldApiName);
                        }
                    }
                    card.fields.add(field);
                }
            }
            card.fields.sort();
            alumniProfileOverview.add(card);
        }
        return alumniProfileOverview;
    }

    /*
    * @description: Retrieves the value for a specific custom field on a Contact record by processing related child records.
    *               This helper method centralizes logic for fields that cannot be directly queried using a simple SOQL SELECT.
    *               The method uses if-else statements to handle different field API names, filtering and concatenating data from related lists.
    * @param:       con The Contact SObject record, which must include its related ucinn_ascendv2__Degree_Information_Contact__r and ucinn_ascendv2__Involvements_Contact__r records.
    * @param:       fieldApiName The API name of the custom field whose value is to be retrieved.
    * @return:      An Object containing the formatted string value of the custom field, or null if no value is found.
    */
    @TestVisible
    private static Object getCustomFieldValue(Contact con, String fieldApiName) {
        Set<String> degreeCheckSet = new Set<String>{HAM_ConstantsUtil.UNDERGRADUATE_DEGREE, HAM_ConstantsUtil.UNDERGRADUATE_MINOR,HAM_ConstantsUtil.POST_GRADUATE_DEGREE};
        Set<String> involvementCheckSet = new Set<String>{HAM_ConstantsUtil.UNDERGRADUATE_ATHLETICS,HAM_ConstantsUtil.RESIDENCE_HALLS, HAM_ConstantsUtil.STUDENT_ORGANIZATIONS};
        List<String> resultList = new List<String>();

        if (degreeCheckSet.contains(fieldApiName) && con.ucinn_ascendv2__Degree_Information_Contact__r != null) {
            for (ucinn_ascendv2__Degree_Information__c degree : con.ucinn_ascendv2__Degree_Information_Contact__r) {
                // Handle 'Undergraduate_Degree' by collecting Major Degree values from 'School_Degree_Information' records.
                if (fieldApiName == HAM_ConstantsUtil.UNDERGRADUATE_DEGREE && degree.RecordType.DeveloperName == HAM_ConstantsUtil.SCHOOL_DEGREE_INFORMATION) {
                    if(degree.ucinn_ascendv2__Major_Degree_Formula__c != null){
                        resultList.add(degree.ucinn_ascendv2__Major_Degree_Formula__c);
                    }
                    if(degree.ucinn_ascendv2__Second_Major_Formula__c != null){
                        resultList.add(degree.ucinn_ascendv2__Second_Major_Formula__c);
                    }
                    if(degree.Third_Concentration_Formula__c != null){
                        resultList.add(degree.Third_Concentration_Formula__c);
                    }
                }
                // Handle 'Undergraduate_Minor' by collecting Minor Degree values from 'School_Degree_Information' records.
                else if (fieldApiName == HAM_ConstantsUtil.UNDERGRADUATE_MINOR && degree.RecordType.DeveloperName == HAM_ConstantsUtil.SCHOOL_DEGREE_INFORMATION) {
                    if(degree.ucinn_ascendv2__Minor_Degree_Formula__c != null){
                        resultList.add(degree.ucinn_ascendv2__Minor_Degree_Formula__c);
                    }
                    if(degree.Second_Minor__c != null){
                        resultList.add(degree.Second_Minor__c);
                    }
                    if(degree.Third_Minor__c != null){
                        resultList.add(degree.Third_Minor__c);
                    }
                }
                // Handle 'Post_Graduate_Degree' by collecting Major Degree values from 'Non_School_Degree_Information' records.
                else if(fieldApiName == HAM_ConstantsUtil.POST_GRADUATE_DEGREE && degree.RecordType.DeveloperName == HAM_ConstantsUtil.NON_SCHOOL_DEGREE_INFORMATION && degree.ucinn_ascendv2__Major_Degree_Formula__c != null) {
                    resultList.add(degree.ucinn_ascendv2__Major_Degree_Formula__c);
                }
            }
        } 

        else if (involvementCheckSet.contains(fieldApiName) && con.ucinn_ascendv2__Involvements_Contact__r != null) {
            for (ucinn_ascendv2__Involvement__c involvement : con.ucinn_ascendv2__Involvements_Contact__r) {
                // Handle 'Undergraduate_Athletics' by collecting involvement codes from 'Student NCAA Athletics' records.
                // Handle 'Residence_Halls' by collecting involvement codes from 'Student Housing' records.
                // Handle 'Student_Organizations' by collecting involvement codes from 'Student Private Societies' records.
                if ((
                        (fieldApiName == HAM_ConstantsUtil.UNDERGRADUATE_ATHLETICS && involvement.HAM_Category__c == HAM_ConstantsUtil.STUDENT_NCAA_ATHLETICS) ||
                        (fieldApiName == HAM_ConstantsUtil.RESIDENCE_HALLS && involvement.HAM_Category__c == HAM_ConstantsUtil.STUDENT_HOUSING) ||
                        (fieldApiName == HAM_ConstantsUtil.STUDENT_ORGANIZATIONS && (involvement.HAM_Category__c == HAM_ConstantsUtil.STUDENT_CLUBS || involvement.HAM_Category__c == HAM_ConstantsUtil.STUDENT_PRIVATE_SOCIETIES))
                    )
                    && involvement.ucinn_ascendv2__Involvement_Code_Description_Formula__c != null) {
                    resultList.add(involvement.ucinn_ascendv2__Involvement_Code_Description_Formula__c);
                }
            }
        }
        return (!resultList.isEmpty()) ? String.join(resultList, '; ') : null;
    }
}