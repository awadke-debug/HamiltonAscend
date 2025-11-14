@IsTest
public with sharing class AdvanceFilterDtoTest {
    @IsTest
    static void testInvalidObject(){

        AdvanceFilterFieldDto dto = new AdvanceFilterFieldDto('m1JVG000005fQ0T2AU', 'Invalid_Object__c', null,'fldLabel', 'filedApi', 'type', false);
        System.Assert.areEqual(dto.improperlyConfigured, true);
    }

    @IsTest
    static void testInvalidField(){
        
        AdvanceFilterFieldDto dto = new AdvanceFilterFieldDto('m1JVG000005fQ0T2AU', 'Contact', null,'Personal ID Number', 'Invalid_Field__c', 'text', false);
        System.Assert.areEqual(dto.improperlyConfigured, true);
        
    }

    @IsTest
    static void testNonFilterableField(){
        AdvanceFilterFieldDto dto = new AdvanceFilterFieldDto('m1JVG000005fQ0T2AU', 'Contact', null,'Personal ID Number', 'bt_stripe__Personal_ID_Number_Encrypted__c', 'text', false);
        System.Assert.areEqual(dto.improperlyConfigured, true);
    }
}