/**
* @File Name : HAM_AlumniProfileOverviewController_Test.cls
* @Description : This class is used to test HAM_AlumniProfileOverviewController class.
* @Author : Cube84 - Sachin
* @Last Modified By : Sachin
* @Last Modified On : August 28, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | August 28, 2025 |  Sachin | Initial Version
**/
@isTest
public class HAM_AlumniProfileOverviewController_Test {
    @testSetup
    static void setup() {       
        // Create Account test data
        Account acc = new Account(Name = 'Test Account', Industry = 'Finance');
        insert acc;

        // Create Contact test data
        Contact con = new Contact(
            FirstName = 'Test FN',
            LastName = 'Test LN',
            Email = 'test@example.com',
            //HAM_Name_w_Suffix__c = 'Test Name',
            HAM_LiveAlumni_LinkedIn_URL__c = 'https://linkedin.com/test',
            HAM_Profile_Picture_URL__c = 'https://profilepic.com/test.jpg',
            Constituent_Employer__c = acc.Id,
            Job_Title__c = 'Financial Analyst',
            HAM_Current_Chapters__c = 'Cincinnati Chapter; New York Chapter',
            ucinn_ascendv2__Preferred_Class_Year__c = '1979'
        );
        insert con;

        // Create a Post Code record
        List<ucinn_ascendv2__Post_Code__c> pcodes = new List<ucinn_ascendv2__Post_Code__c>();
        pcodes.add(
            new ucinn_ascendv2__Post_Code__c(
                Name = 'Economics',
                ucinn_ascendv2__Degree_Description__c = 'Economics',
                ucinn_ascendv2__Is_Active__c = true
            )
        );
        pcodes.add(
            new ucinn_ascendv2__Post_Code__c(
                Name = 'Mathematics',
                ucinn_ascendv2__Degree_Description__c = 'Mathematics',
                ucinn_ascendv2__Is_Active__c = true
            )
        );
        insert pcodes;
		// create minor code
		List<ucinn_ascendv2__Minor_Code__c> mincodes = new List<ucinn_ascendv2__Minor_Code__c>();
		mincodes.add(
            new ucinn_ascendv2__Minor_Code__c(
                Name = 'Safety Control',
                ucinn_ascendv2__Description__c = 'Safety Control'
            )
        );
		insert mincodes;

        // Get the Record Type ID for 'School_Degree_Information'
        Id schoolDegreeRecordTypeId = Schema.SObjectType.ucinn_ascendv2__Degree_Information__c.getRecordTypeInfosByDeveloperName().get('School_Degree_Information').getRecordTypeId();
        // Get the Record Type ID for 'Non_School_Degree_Information'
        Id nonSchoolDegreeRecordTypeId = Schema.SObjectType.ucinn_ascendv2__Degree_Information__c.getRecordTypeInfosByDeveloperName().get('Non_School_Degree_Information').getRecordTypeId();

        // create degree records
        List<ucinn_ascendv2__Degree_Information__c> degreesToInsert = new List<ucinn_ascendv2__Degree_Information__c>();
        degreesToInsert.add(
            new ucinn_ascendv2__Degree_Information__c(    
                ucinn_ascendv2__Contact__c = con.Id,
                ucinn_ascendv2__Post_Code__c = pcodes[0].Id,
                RecordTypeId = schoolDegreeRecordTypeId
            )
        );
        degreesToInsert.add(
            new ucinn_ascendv2__Degree_Information__c(    
                ucinn_ascendv2__Contact__c = con.Id,
                ucinn_ascendv2__Minor_Code__c = mincodes[0].Id,
                RecordTypeId = schoolDegreeRecordTypeId
            )
        );
        degreesToInsert.add(
            new ucinn_ascendv2__Degree_Information__c(    
                ucinn_ascendv2__Contact__c = con.Id,
                ucinn_ascendv2__Post_Code__c = pcodes[1].Id,
                RecordTypeId = nonSchoolDegreeRecordTypeId
            )
        );
        insert degreesToInsert;  

        // create Involvements Value records
        List<ucinn_ascendv2__Involvement_Value__c> involvementValue = new List<ucinn_ascendv2__Involvement_Value__c>();
        involvementValue.add(
            new ucinn_ascendv2__Involvement_Value__c (
                Name = 'Mens Basketball',
                HAM_Category__c = 'Student NCAA Athletics',
                ucinn_ascendv2__Type__c = 'Student Involvement',
                ucinn_ascendv2__Involvement_Description__c = 'Mens Basketball'
            )
        );
        involvementValue.add(
            new ucinn_ascendv2__Involvement_Value__c (
                Name = 'Mens Housing',
                HAM_Category__c = 'Student Housing',
                ucinn_ascendv2__Type__c = 'Student Housing',
                ucinn_ascendv2__Involvement_Description__c = 'Mens Housing'
            )
        );
        involvementValue.add(
            new ucinn_ascendv2__Involvement_Value__c (
                Name = 'Mens private society',
                HAM_Category__c = 'Student Clubs',
                ucinn_ascendv2__Type__c = 'Student Involvement',
                ucinn_ascendv2__Involvement_Description__c = 'Mens private society'
            )
        );
        insert involvementValue;        

        // Get the Record Type ID for 'Student_Involvement'
        Id Student_InvolvementRecordTypeId = Schema.SObjectType.ucinn_ascendv2__Involvement__c.getRecordTypeInfosByDeveloperName().get('Student_Involvement').getRecordTypeId();
        // Get the Record Type ID for 'Student_Housing'
		Id Student_HousingRecordTypeId = Schema.SObjectType.ucinn_ascendv2__Involvement__c.getRecordTypeInfosByDeveloperName().get('Student_Housing').getRecordTypeId();

        // create Involvements records
        List<ucinn_ascendv2__Involvement__c> involvements = new List<ucinn_ascendv2__Involvement__c>();
        involvements.add(
            new ucinn_ascendv2__Involvement__c(
                ucinn_ascendv2__Contact__c = con.Id,
                ucinn_ascendv2__Involvement_Code__c = involvementValue[0].Id,
                RecordTypeId = Student_InvolvementRecordTypeId
            )
        );
        involvements.add(new ucinn_ascendv2__Involvement__c(
                ucinn_ascendv2__Contact__c = con.Id,
                ucinn_ascendv2__Involvement_Code__c = involvementValue[1].Id,
                RecordTypeId = Student_HousingRecordTypeId
            )
        );
        involvements.add(new ucinn_ascendv2__Involvement__c(
                ucinn_ascendv2__Contact__c = con.Id,
                ucinn_ascendv2__Involvement_Code__c = involvementValue[2].Id,
                RecordTypeId = Student_InvolvementRecordTypeId
            )
        );        
        insert involvements;
    }

    /*
    * @description: Test method to test getAlumniOverview method and subsequent private method getCustomFieldValue.
    */
	@isTest
    static void getAlumniOverviewTestMethod() {
        Test.startTest();
		Contact con = [Select Id,Name,Email from Contact Where Email = 'test@example.com'];
		List<HAM_AlumniProfileOverviewController.AlumniProfileOverviewCard> alumniOverviewRec = HAM_AlumniProfileOverviewController.getAlumniOverview(con.Id);
        List<HAM_AlumniProfileOverviewController.AlumniProfileOverviewCard> emptyList = HAM_AlumniProfileOverviewController.getAlumniOverview(null);
        Test.stopTest();

        System.assert(alumniOverviewRec.size()>0, 'List should have values');
        System.assert(emptyList.isEmpty(), 'Empty List should be returned');

        HAM_AlumniProfileOverviewController.AlumniProfileOverviewCard card = alumniOverviewRec[0];
        
        Map<String, Object> fieldValues = new Map<String, Object>();

        for (HAM_AlumniProfileOverviewController.FieldWrapper field : card.fields) {
            fieldValues.put(field.label, field.value);
        }

        // Assertions for each custom field
        System.assertEquals('Economics', fieldValues.get('Undergraduate Degree:'), 'Undergraduate Degree value should be Economics.');

        System.assertEquals('Safety Control', fieldValues.get('Undergraduate Minor:'), 'Undergraduate Minor value should be Safety Control.');

        System.assertEquals('Mens Basketball', fieldValues.get('Undergraduate Athletics:'), 'Undergraduate Athletics value should be Mens Basketball.');

        System.assertEquals('Mens Housing', fieldValues.get('Residence Halls:'), 'Residence Halls value should be Mens Housing.');
        
        System.assertEquals('Mens private society', fieldValues.get('Student Organizations:'), 'Student Organizations value should be Mens private society.');
    }
}