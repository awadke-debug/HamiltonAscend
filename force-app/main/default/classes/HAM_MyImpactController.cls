/**
* @File Name : HAM_MyImpactController.cls
* @Description : This class is used to fetch contact details and philanthropy details on my impact page.
* @Author : Cube84 - Sachin
* @Last Modified By : Sachin
* @Last Modified On : July 9, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | July 9, 2025 |  Sachin | Initial Version
* 1.1 | Sept 04, 2025 |  Sachin |  Done as part of Optimization
**/

public with sharing class HAM_MyImpactController {

	// Main Wrapper Class to hold all data
    public class MyImpactDataWrapper {
        @AuraEnabled public ContactInfo contact;
		@AuraEnabled public List<DegreeInfo> degree;
		@AuraEnabled public OtherInfo otherInfo;
		@AuraEnabled public List<MyProfileBioData> bioData;
		@AuraEnabled public List<MyProfileMyConnect> myConnect;
        @AuraEnabled public CampusContact campusContact;
        @AuraEnabled public List<HCBadge> hcBadges; 
        @AuraEnabled public List<PhilanthropyField> philanthropyField;
        @AuraEnabled public String error; // To pass error messages if any
    }

    // Wrapper to hold other info
    public class OtherInfo {
        @AuraEnabled public Boolean isGift;
        @AuraEnabled public String facebook;
    }
	
	// Wrapper for Contact Information
    public class ContactInfo {
		@AuraEnabled public String userPic;
        @AuraEnabled public Id Id;
        @AuraEnabled public String name;
        @AuraEnabled public String linkedIn;
    }

	// Wrapper class for Degree Information
	public class DegreeInfo {
		@AuraEnabled public String major;
		@AuraEnabled public String minor;
	}

    //Wrapper class for Campus Contact
    public class CampusContact {
        @AuraEnabled public String phone;
        @AuraEnabled public String email;
        @AuraEnabled public String name;
    }

	// Wrapper classes to represent the Constituent fields in My Profile section from metadata
    public class MyProfileBioData {
        @AuraEnabled public String displayLabel;
        @AuraEnabled public Decimal displayOrder;
        @AuraEnabled public String displayValue;
    }

	public class MyProfileMyConnect {
        @AuraEnabled public String displayLabel;
        @AuraEnabled public Decimal displayOrder;
        @AuraEnabled public String displayValue;
	}

    // New Wrapper for Dynamic HC Badges
    public class HCBadge {
        @AuraEnabled public String label;
        @AuraEnabled public String imageUrl;
    }

    // New Wrapper for Fields within a Philanthropy Section
    public class PhilanthropyField {
        @AuraEnabled public String label; 
        @AuraEnabled public String value; 
        @AuraEnabled public String type; 
        @AuraEnabled public Decimal order; 
        @AuraEnabled public String sectionLabel;        
        @AuraEnabled public Decimal sectionOrder;
    }

    // HAM_Metadata wrapper
    public class MyImpactMetadata {
		@AuraEnabled public String fieldApiName;
        @AuraEnabled public String displayLabel;
        @AuraEnabled public Decimal displayOrder;
        @AuraEnabled public String level2;
        @AuraEnabled public String level1;
        @AuraEnabled public Decimal sectionOrder;
        @AuraEnabled public String type;
        @AuraEnabled public Id Id;
	}

    // Badge Metadata wrapper
    public class BadgeMetadata {
        @AuraEnabled public String imagePath;
        @AuraEnabled public String displayName;
        @AuraEnabled public Decimal displayOrder;
        @AuraEnabled public String mappingFieldApi;
    }

    // Parent Wrapper to store data for accordions in MyImpact page (My Services, My Affinities and Teams)
    public class MyServiceAffinities {
        @AuraEnabled public List<MyService> myServices; 
        @AuraEnabled public List<MyAffinity> myAffinities;  
    }

    // Wrapper for My Services
    public class MyService {
        @AuraEnabled public String displaylabel; 
        @AuraEnabled public String displayType;
        @AuraEnabled public Decimal order; 
        @AuraEnabled public String displayValueText; 
        @AuraEnabled public List<String> displayValueList;
    }

    // Wrapper for My Affinity
    public class MyAffinity {
        @AuraEnabled public String displaylabel; 
        @AuraEnabled public String displayType;
        @AuraEnabled public Decimal order; 
        @AuraEnabled public String displayValueText; 
        @AuraEnabled public List<String> displayValueList;
    }

    // Parent wrapper for philanthropy details
    public class PhilanthropyDetail {
        @AuraEnabled public List<PhilanthropyField> philanthropyField;
        @AuraEnabled public List<PhilanthropyDataTable> philanthropyDataTables;
        @AuraEnabled public String error;
    }

    public class PhilanthropyDataTable {
        @AuraEnabled public String tableName;
        @AuraEnabled public List<SObject> records; 
        @AuraEnabled public List<String> columnLabels; 
        @AuraEnabled public List<String> columnApiNames;
        @AuraEnabled public List<String> fieldTypes;
        @AuraEnabled public Decimal displayLimit;
        @AuraEnabled public Boolean displayLoadMore;
        @AuraEnabled public Decimal order;
    }

    /**
    * @description: Method to fetch philanthropy details field configuration from HAM_Object_Fetcher__mdt.
    * @param:       additionalWhereClause - dynamic where clause for the metadata to fetch only required records for this section.
    * @return:      List<HAM_Object_Fetcher__mdt> - A list of HAM_Object_Fetcher__mdt metadata records
    **/
    public static List<HAM_Object_Fetcher__mdt> getPhilanthrophyDetailMetadata(String additionalWhereClause) {
		List<HAM_Object_Fetcher__mdt> objectFetchers = new List<HAM_Object_Fetcher__mdt>();
        String query = 'SELECT Id, DeveloperName, HAM_Level_1__c, HAM_Level_2__c, HAM_Related_Object__c, HAM_Display_Type__c, HAM_Default_Display_Value__c, HAM_Display_Label__c,'+ 
                        'HAM_Display_Field__c, HAM_Reference_Field__c, HAM_Additional_Filter__c, HAM_Order__c, HAM_Table_Default_Sort_Order__c,HAM_Table_Field_APIs__c,'+
                        'HAM_Table_Field_Labels__c, HAM_Table_Limit__c, HAM_Table_Field_Types__c, HAM_Table_Load_More__c '+
                        'FROM HAM_Object_Fetcher__mdt';

        // Append the additional WHERE clause if provided
        if (String.isNotBlank(additionalWhereClause)) {
            query += ' WHERE ' + additionalWhereClause;
        }
        // add the ORDER BY clause
        query += 'WITH SECURITY_ENFORCED ORDER By HAM_Level_1__c ASC, HAM_Level_2__c ASC, HAM_Order__c ASC';
        try{
            objectFetchers = (List<HAM_Object_Fetcher__mdt>)Database.query(query);
        }catch (QueryException qe) {
            System.debug('Query Error in getPhilanthrophyDetailMetadata: ' + qe.getMessage());
        }
        return objectFetchers;
    }

    /**
    * @description: Method to fetch My Impact(Profile section & My Philanthropy highlights section) field Configuration from Custom Metadata  
    * @param:       additionalWhereClause - dynamic where clause for the metadata to fetch only required records for this section.
    * @return:      List<MyImpactMetadata> - A list of MyImpactMetadata wrapper which objects.
    **/
    public static List<MyImpactMetadata> getMyImpactMetadata(String additionalWhereClause) {
        List<MyImpactMetadata> myImpactMetadaList = new List<MyImpactMetadata>();
        // base SOQL query
        String query = 'SELECT Id, HAM_Display_Label__c, HAM_Field_API__c, HAM_Field_Type__c, ' +
                       'HAM_Level_1__c, HAM_Level_2__c, HAM_Order__c, HAM_Section_Order__c ' +
                       'FROM HAM_Meta_Data__mdt';
        
        // Append the additional WHERE clause if provided
        if (String.isNotBlank(additionalWhereClause)) {
            query += ' WHERE ' + additionalWhereClause;
        }

        // Always add the ORDER BY clause
        query += 'WITH SECURITY_ENFORCED ORDER By HAM_Level_2__c, HAM_Order__c ASC';
        try{
            for (SObject sObjFieldConfig : Database.query(query)) {
                HAM_Meta_Data__mdt fieldConfig = (HAM_Meta_Data__mdt) sObjFieldConfig;

                // Only add if HAM_Field_API__c is not blank
                if (String.isNotBlank(fieldConfig.HAM_Field_API__c)) {
                    MyImpactMetadata metadata = new MyImpactMetadata();
                    metadata.fieldApiName = fieldConfig.HAM_Field_API__c != null ? fieldConfig.HAM_Field_API__c : ' ';
                    metadata.displayLabel = fieldConfig.HAM_Display_Label__c != null ? fieldConfig.HAM_Display_Label__c : '';
                    metadata.displayOrder = fieldConfig.HAM_Order__c != null ? fieldConfig.HAM_Order__c : 0;
                    metadata.sectionOrder = fieldConfig.HAM_Section_Order__c != null ? fieldConfig.HAM_Section_Order__c : 0;
                    metadata.level2 = fieldConfig.HAM_Level_2__c != null ? fieldConfig.HAM_Level_2__c : '';
                    metadata.level1 = fieldConfig.HAM_Level_1__c != null ? fieldConfig.HAM_Level_1__c : '';
                    metadata.type = (fieldConfig.HAM_Field_Type__c != null) ? fieldConfig.HAM_Field_Type__c : '';
                    metadata.Id = fieldConfig.Id;
                    myImpactMetadaList.add(metadata);
                }
            }
        } catch (QueryException qe) {
            System.debug('Query Error in getMyImpactMetadata: ' + qe.getMessage());
        }
        
        return myImpactMetadaList;
    }

    /**
    * @description: Method to fetch Badge field configuration from custom metadata
    * @return:      List<BadgeMetadata> - A list of BadgeMetadata wrapper which objects.
    **/
    public static List<BadgeMetadata> getBadgeMetadata() {
        List<BadgeMetadata> badgeMetadataList = new List<BadgeMetadata>();
		BadgeMetadata metadata;
        try{
            for (HAM_Badge__mdt fieldConfig : [SELECT HAM_Display_Name__c, HAM_Image_Path__c, HAM_Mapping_Field_API__c, HAM_Order__c FROM HAM_Badge__mdt WITH SECURITY_ENFORCED ORDER BY HAM_Order__c]) {            
                    metadata = new BadgeMetadata();
                    metadata.imagePath = fieldConfig.HAM_Image_Path__c != null ? fieldConfig.HAM_Image_Path__c : '';
                    metadata.displayName = fieldConfig.HAM_Display_Name__c != null ? fieldConfig.HAM_Display_Name__c : '';
                    metadata.displayOrder = fieldConfig.HAM_Order__c != null ? fieldConfig.HAM_Order__c : 0;
                    metadata.mappingFieldApi = fieldConfig.HAM_Mapping_Field_API__c != null ? fieldConfig.HAM_Mapping_Field_API__c : ''; 
                    badgeMetadataList.add(metadata);
            }
        }catch (QueryException qe) {
            System.debug('Query Error in getBadgeMetadata: ' + qe.getMessage());
        }
        
        return badgeMetadataList;
    }

    /**
    * @description : method to fetch records dynamically based on HAM_Object_Fetcher__mdt to populate philanthropycdetails in accordion.
    * @param : currentUserContactId - contactId of logged in portal user.
    * @return : PhilanthropyDetail - wrapper object.
    */
    @AuraEnabled(cacheable=true)
    public static PhilanthropyDetail getPhilanthropyDetails(String currentUserContactId) {
        
        PhilanthropyDetail philanthropyDetail = new PhilanthropyDetail();
        philanthropyDetail.philanthropyField = new List<PhilanthropyField>();
        philanthropyDetail.philanthropyDataTables = new List<PhilanthropyDataTable>();
        
        String whereClause = 'HAM_Level_1__c IN (\'My Philanthropy Detail\')';

        // Fetch Philanthropy detail fields which is preconfigured in HAM_Meta_data__mdt
        List<MyImpactMetadata> philanthropyDetailFieldsToQuery = getMyImpactMetadata(whereClause);

        // Fetch HAM_Object_Fetcher__mdt fields which is preconfigured
        List<HAM_Object_Fetcher__mdt> philanthropyDetailTablesToQuery = getPhilanthrophyDetailMetadata(whereClause);

        Set<String> fieldApiNames = new Set<String>();

        // Fetching details of philanthropy field for the accordion section
        for(MyImpactMetadata field : philanthropyDetailFieldsToQuery) {
            fieldApiNames.add(field.fieldApiName);            
        }

        // Fetching actual data from salesforce for philanthropy accordion based on the configurations in metadata
        String queryFields = String.join(new List<String>(fieldApiNames), ', ');

        String queryString = 'SELECT Id,'+ queryFields + ' FROM Contact WHERE Id = \'' + String.escapeSingleQuotes(currentUserContactId) + '\' LIMIT 1';
        
		Contact constituentSObject = null;
		try {
            List<Contact> results = (List<Contact>)Database.query(queryString);
            if (!results.isEmpty()) {
                constituentSObject = results[0];
            }
        } catch (System.QueryException e) {
             
             philanthropyDetail.error = 'Failed to retrieve constituent details. ' + e.getMessage();
             return philanthropyDetail;
        }
        if (constituentSObject != null) {
        for(MyImpactMetadata field: philanthropyDetailFieldsToQuery){
                if(field.level1 == HAM_ConstantsUtil.MY_PHILANTHROPY_DETAIL){
                    PhilanthropyField myPhilanthropy = new PhilanthropyField();
                    myPhilanthropy.label = field.displayLabel;
                    myPhilanthropy.order = field.displayOrder;
                    myPhilanthropy.sectionOrder = field.sectionOrder;
                    myPhilanthropy.value = (field.fieldApiName != null)? String.valueOf(constituentSObject.get(field.fieldApiName)) : ' '; 
                    myPhilanthropy.type = field.type;
                    myPhilanthropy.sectionLabel = field.level2;
                    philanthropyDetail.philanthropyField.add(myPhilanthropy);
                }
            }
        }
        // fetching philanthropy data table actual values 
        try {
            String recordLimit = System.Label.ham_PhilanthropyTableFetchLimit;
            for(HAM_Object_Fetcher__mdt field: philanthropyDetailTablesToQuery){
                
                String query = 'SELECT ' + field.HAM_Table_Field_APIs__c + 
                            ' FROM ' + field.HAM_Related_Object__c + 
                            ' WHERE ' + field.HAM_Reference_Field__c + ' = \'' + String.escapeSingleQuotes(currentUserContactId) + '\'' + 
                            ' AND ' + field.HAM_Additional_Filter__c + ' WITH SECURITY_ENFORCED ' + 
                            field.HAM_Table_Default_Sort_Order__c + ' ';
                            
                
                if(field.HAM_Table_Load_More__c) {
                    query += ' LIMIT ' + recordLimit;
                }
                else {
                    query += ' LIMIT ' + field.HAM_Table_Limit__c;
                } 
				 
                List<Sobject> tableData = Database.query(query);
                
                PhilanthropyDataTable dataTable = new PhilanthropyDataTable();
                dataTable.tableName = field.HAM_Display_Label__c; 
                dataTable.columnApiNames = field.HAM_Table_Field_APIs__c.split(','); // Store API names for columns
                dataTable.columnLabels = field.HAM_Table_Field_Labels__c.split(','); // Store Labels for columns
                dataTable.records = tableData;
                dataTable.fieldTypes = field.HAM_Table_Field_Types__c.split(',');
                dataTable.displayLimit = (Decimal) field.HAM_Table_Limit__c;
                dataTable.displayLoadMore = field.HAM_Table_Load_More__c;
                dataTable.order = (Decimal)field.HAM_Order__c;
                philanthropyDetail.philanthropyDataTables.add(dataTable);
                                            
            }
        } catch (System.QueryException e) {
             System.debug('QueryException when fetching Contact: ' + e.getMessage());
             philanthropyDetail.error = 'Failed to retrieve constituent details. ' + e.getMessage();
             return philanthropyDetail;
        }
        
        return philanthropyDetail;
    }

    /**
    * @description : method to fetch records dynamically based on HAM_Object_Fetcher__mdt.
    * @param : currentUserContactId - contactId of logged in portal user.
    * @Returns : MyServiceAffinities - wrapper  object.
    **/
    @AuraEnabled(cacheable=true)
    public static MyServiceAffinities getMyServiceAffinitiesData(String currentUserContactId) {

        MyServiceAffinities myServiceAffinities = new MyServiceAffinities();
        myServiceAffinities.myAffinities = new List<MyAffinity>();
        myServiceAffinities.myServices = new List<MyService>();

        //  Fetch all HAM_Object_Fetcher__mdt records
        String whereClause = 'HAM_Level_1__c IN (\'My Service\',\'My Affinities\')' ;
        List<HAM_Object_Fetcher__mdt> objectFetchers = getPhilanthrophyDetailMetadata(whereClause);

        // Process each metadata record
        for (HAM_Object_Fetcher__mdt fetcher : objectFetchers) {
            if ((String.isBlank(fetcher.HAM_Level_2__c) || String.isBlank(fetcher.HAM_Related_Object__c)) && fetcher.HAM_Display_Type__c != HAM_ConstantsUtil.HARDCODED_STRING) {
                System.debug('Skipping metadata record ' + fetcher.DeveloperName + ' due to missing HAM_Level_2__c or HAM_Related_Object__c.');
                continue;
            }

            List<String> formattedRecords = new List<String>();
            if(fetcher.HAM_Display_Type__c != HAM_ConstantsUtil.HARDCODED_STRING) {
                String objectApiName = fetcher.HAM_Related_Object__c;
                String displayField = fetcher.HAM_Display_Field__c != null ? fetcher.HAM_Display_Field__c : '';
                String referenceField = fetcher.HAM_Reference_Field__c;
                String filter = fetcher.HAM_Additional_Filter__c != null ? fetcher.HAM_Additional_Filter__c : '';

                // Construct the dynamic SOQL query
                Set<String> fieldsToSelect = new Set<String>{'Id'};
                if (String.isNotBlank(displayField)) {
                    fieldsToSelect.add(displayField);
                }

                String selectClause = String.join(new List<String>(fieldsToSelect), ',');
                String query = 'SELECT ' + selectClause + ' FROM ' + objectApiName;
                
                if (String.isNotBlank(referenceField)) {
                    query += ' WHERE ' + referenceField + ' = \'' + String.escapeSingleQuotes(currentUserContactId) + '\'';
                }
                if (String.isNotBlank(filter)) {
                    query += ' AND ' + filter;
                }
                query += ' WITH SECURITY_ENFORCED';         
                
                try {
                    if (String.isNotBlank(displayField)) {
                        for (SObject record : Database.query(query)) {    
                            Object fieldValue = record.get(displayField);
                            if (fieldValue != null) {
                                formattedRecords.add(String.valueOf(fieldValue));
                            }
                        }
                    }
                } catch (Exception e) {
                    System.debug('Error querying for ' + fetcher.DeveloperName + ': ' + e.getMessage());
                }
            }
            // Populate the appropriate wrapper class
            if (fetcher.HAM_Level_1__c == HAM_ConstantsUtil.MY_AFFINITIES) {
                MyAffinity myAffinity = new MyAffinity();
                myAffinity.displayLabel = fetcher.HAM_Display_Label__c;
                myAffinity.displayType = fetcher.HAM_Display_Type__c;
                myAffinity.order = fetcher.HAM_Order__c;
                
                if (fetcher.HAM_Display_Type__c == HAM_ConstantsUtil.LISTS) {
                    myAffinity.displayValueList = formattedRecords;
                } else {
                    myAffinity.displayValueText = (fetcher.HAM_Display_Type__c == HAM_ConstantsUtil.HARDCODED_STRING) ? 
                                                    ((fetcher.HAM_Default_Display_Value__c != null) ? fetcher.HAM_Default_Display_Value__c : null)
                                                    : (String.join(formattedRecords, '; '));
                }
                myServiceAffinities.myAffinities.add(myAffinity);

            }else if (fetcher.HAM_Level_1__c == HAM_ConstantsUtil.MY_SERVICE) {
                MyService myService = new MyService();
                myService.displayLabel = fetcher.HAM_Display_Label__c;
                myService.displayType = fetcher.HAM_Display_Type__c;
                myService.order = fetcher.HAM_Order__c;
                
                if (fetcher.HAM_Display_Type__c == HAM_ConstantsUtil.LISTS) {
                    myService.displayValueList = formattedRecords;
                } else {
                    myService.displayValueText = (fetcher.HAM_Display_Type__c == HAM_ConstantsUtil.HARDCODED_STRING) ? 
                                                    ((fetcher.HAM_Default_Display_Value__c != null) ? fetcher.HAM_Default_Display_Value__c : null)
                                                    : (String.join(formattedRecords, '; '));
                }
                myServiceAffinities.myServices.add(myService);
            }
        }

        return myServiceAffinities;
    }
    
    /**
    * @description : Method to get current user's Contact details and Philanthropy data
    * @param : currentUserContactId - contactId of logged in portal user.
    * @Returns : MyImpactDataWrapper - wrapper  object.
    **/
    @AuraEnabled(cacheable=true)
	public static MyImpactDataWrapper getContactAndPhilanthropyData(String currentUserContactId){
		MyImpactDataWrapper response = new MyImpactDataWrapper();
    
		// Dynamically building the SOQL query string for Constituent fields based on Custom Metadata and populating wrapper classes MyProfileBioData & MyProfileMyConnect
        String whereClause = 'HAM_Level_1__c IN (\'My Profile\',\'My Philanthropy Highlight\')';
        List<MyImpactMetadata> myImpactMetadataFieldsToQuery = getMyImpactMetadata(whereClause);
        List<BadgeMetadata> badgeMetdataFieldsToQuery = getBadgeMetadata();

        Set<String> fieldApiNames = new Set<String>();
        response.bioData = new list<MyProfileBioData>();
        response.myConnect = new list<MyProfileMyConnect>();
        response.philanthropyField = new list<philanthropyField>();
        
        for(MyImpactMetadata field : myImpactMetadataFieldsToQuery) {
            fieldApiNames.add(field.fieldApiName);            
        }

        for(BadgeMetadata field : badgeMetdataFieldsToQuery) {
            fieldApiNames.add(field.mappingFieldApi);            
        }

        String queryFields = String.join(new List<String>(fieldApiNames), ', ');


		// This subquery is used to fetch Degree Information.
        String degreeSubquery = '(SELECT Id, ucinn_ascendv2__Major_Degree_Formula__c, ucinn_ascendv2__Minor_Degree_Formula__c FROM ucinn_ascendv2__Degree_Information_Contact__r where RecordType.DeveloperName = \'School_Degree_Information\')';
		
        // This subquery is used to fetch my campus contact email and phone
        String campusContact = 'HAM_PRM_Email__c,HAM_PRM_Phone__c,ucinn_ascendv2__PRM__r.Id,ucinn_ascendv2__PRM__r.Name';
        
        // This subquery is used to fetch my class contact
        String classContact = '(SELECT Id, ucinn_ascendv2__Assigned_Relationship_Mngr_Name_Formula__c FROM ucinn_ascendv2__Assignments_Contact__r WHERE ucinn_ascendv2__Assignment_Type__c = \'Class Manager\' AND ucinn_ascendv2__Assignment_End_Date__c = null AND RecordType.DeveloperName = \'Contact_Assignment\')';
        
        // This subquery is used to fetch social media detail of facebook
		String socialMediaSubquery = '(SELECT Id,ucinn_ascendv2__URL__c FROM ucinn_ascendv2__Social_Media__r where ucinn_ascendv2__Platform__c= \'Facebook\')';
		
        // Main query to fetch constituent
		String queryString = 'SELECT Id, HAM_Profile_Picture_URL__c, HAM_Name_w_Suffix__c, HAM_Current_FY_Paid__c, HAM_LiveAlumni_LinkedIn_URL__c,'+ queryFields + ', ' + campusContact +', '+ classContact + ', '+ degreeSubquery + ', ' + socialMediaSubquery + ' FROM Contact WHERE Id = \'' + String.escapeSingleQuotes(currentUserContactId) + '\' LIMIT 1';
        
		Contact constituentSObject = null;
		try {
            List<Contact> results = (List<Contact>)Database.query(queryString);
            
            if (!results.isEmpty()) {
                constituentSObject = results[0];
            }
        } catch (System.QueryException e) {
             System.debug('QueryException when fetching Contact: ' + e.getMessage());
             response.error = 'Failed to retrieve constituent details. ' + e.getMessage();
             return response;
        }

        if (constituentSObject != null) {
           
            try{
                response.contact = new ContactInfo();
                // populate ContactInfo wrapper from SObject
                response.contact.Id = constituentSObject.get('Id') != null ? (Id)constituentSObject.get('Id') : '';
                response.contact.userPic = constituentSObject.get('HAM_Profile_Picture_URL__c') != null ? (String)constituentSObject.get('HAM_Profile_Picture_URL__c') : '';
                response.contact.name = constituentSObject.get('HAM_Name_w_Suffix__c') != null ? (String)constituentSObject.get('HAM_Name_w_Suffix__c') : '';
                response.contact.linkedIn = constituentSObject.get('HAM_LiveAlumni_LinkedIn_URL__c') != null ? (String)constituentSObject.get('HAM_LiveAlumni_LinkedIn_URL__c') : '';

                // Populate related ucinn_ascendv2__Degree_Information__c
                response.degree = new List<DegreeInfo>(); 
                List<ucinn_ascendv2__Degree_Information__c> rawDegrees = (List<ucinn_ascendv2__Degree_Information__c>)constituentSObject.getSobjects('ucinn_ascendv2__Degree_Information_Contact__r');
    
                if (rawDegrees != null && !rawDegrees.isEmpty()) {
                    for (ucinn_ascendv2__Degree_Information__c degreeRecord : rawDegrees) {
                        DegreeInfo singleDegree = new DegreeInfo();
                        singleDegree.major = degreeRecord.get('ucinn_ascendv2__Major_Degree_Formula__c') != null ? (String)degreeRecord.get('ucinn_ascendv2__Major_Degree_Formula__c') : '';
                        singleDegree.minor = degreeRecord.get('ucinn_ascendv2__Minor_Degree_Formula__c') != null ? (String)degreeRecord.get('ucinn_ascendv2__Minor_Degree_Formula__c') : '';
                        response.degree.add(singleDegree);
                    }
                }
                
                response.otherInfo = new OtherInfo();

                // Populate related social media Information
                List<ucinn_ascendv2__Social_Media__c> socialMedia = (List<ucinn_ascendv2__Social_Media__c>)constituentSObject.getSobjects('ucinn_ascendv2__Social_Media__r');
                if(socialMedia != null){
                    response.otherInfo.facebook = socialMedia[0].get('ucinn_ascendv2__URL__c') != null ? (String)socialMedia[0].get('ucinn_ascendv2__URL__c') : '';
                }
                
                response.otherInfo.isGift = (constituentSObject.get('HAM_Current_FY_Paid__c') != null && (Decimal)constituentSObject.get('HAM_Current_FY_Paid__c') > 0) ? false : true;
                
                // Populating class contact data
                List<ucinn_ascendv2__Assignment__c> assignments = (List<ucinn_ascendv2__Assignment__c>)constituentSObject.getSobjects('ucinn_ascendv2__Assignments_Contact__r');
                MyProfileMyConnect classContacts = new MyProfileMyConnect();
                classContacts.displayLabel = System.Label.ham_MyClassContact;
                classContacts.displayOrder = 1;
                if (assignments != null && !assignments.isEmpty()) {
                        
                    classContacts.displayValue = assignments[0].ucinn_ascendv2__Assigned_Relationship_Mngr_Name_Formula__c != null ? assignments[0].ucinn_ascendv2__Assigned_Relationship_Mngr_Name_Formula__c : '';  
                      
                }     
                response.myConnect.add(classContacts);          
    
                // Populate campus contact data            
                response.campusContact = new CampusContact();
                
                response.campusContact.name = constituentSObject.getSObject('ucinn_ascendv2__PRM__r')!= null ? (String)(((SObject)constituentSObject.getSObject('ucinn_ascendv2__PRM__r')).get('Name')) : '';
                response.campusContact.phone = constituentSObject.get('HAM_PRM_Phone__c') != null ? (String)constituentSObject.get('HAM_PRM_Phone__c') : '';
                response.campusContact.email = constituentSObject.get('HAM_PRM_Email__c') != null ? (String)constituentSObject.get('HAM_PRM_Email__c') : '';

                for(MyImpactMetadata field: myImpactMetadataFieldsToQuery){

                    //Populate Wrapper class MyProfileBioData
                    if(field.level2 == HAM_ConstantsUtil.BIO_DATA){
                        MyProfileBioData bioData = new MyProfileBioData();
                        bioData.displayLabel = field.displayLabel;
                        bioData.displayOrder = field.displayOrder;
                        bioData.displayValue = constituentSObject.get(field.fieldApiName) != null ? String.valueOf(constituentSObject.get(field.fieldApiName)) : '';
                                      
                        response.bioData.add(bioData);
                    }  
                    
                    //Populate Wrapper class MyProfileMyConnect
                    else if(field.level2 == HAM_ConstantsUtil.MY_CONNECT){
                        MyProfileMyConnect myConnect = new MyProfileMyConnect();
                        myConnect.displayLabel = field.displayLabel;
                        myConnect.displayOrder = field.displayOrder;
                        myConnect.displayValue = constituentSObject.get(field.fieldApiName) != null ? String.valueOf(constituentSObject.get(field.fieldApiName)) : '';  
                        response.myConnect.add(myConnect);
                    }

                    //Populate philanthropy wrapper fields
                    else if(field.level1 == HAM_ConstantsUtil.MY_PHILANTHROPY_HIGHLIGHT){
                        PhilanthropyField myPhilanthropy = new PhilanthropyField();
                        myPhilanthropy.label = field.displayLabel;
                        myPhilanthropy.order = field.displayOrder;
                        myPhilanthropy.sectionOrder = field.sectionOrder;
                        myPhilanthropy.value = ((field.fieldApiName != null) && constituentSObject.get(field.fieldApiName) != null)? String.valueOf(constituentSObject.get(field.fieldApiName)) : ' '; 
                        myPhilanthropy.type = field.type;
                        myPhilanthropy.sectionLabel = field.level2;
                        response.philanthropyField.add(myPhilanthropy);
                    }
                }

                // populate BadgeMetadata
                response.hcBadges = new List<HCBadge>();                

                for (BadgeMetadata badgeMdt : badgeMetdataFieldsToQuery) {
                    try {
                        // Check if the Contact has the corresponding boolean field set to true
                        Boolean hasBadge = constituentSObject.get(badgeMdt.mappingFieldApi) != null ? (Boolean)constituentSObject.get(badgeMdt.mappingFieldApi): false;
                        if (hasBadge == true) { 
                            HCBadge badge = new HCBadge();
                            badge.label = badgeMdt.displayName;
                            badge.imageUrl = badgeMdt.imagePath;
                            response.hcBadges.add(badge);
                        }
                    } catch (Exception e) {
                        System.debug('Error checking badge field ' + badgeMdt.mappingFieldApi + ': ' + e.getMessage());
                    }
                }            

            }
            catch (Exception e){
                response.error = e.getMessage() + ' at line ' + e.getLineNumber();
                System.debug('Error processing constituentSObject data: ' + response.error);
            }                    
        }
        
        return response;
    }

}