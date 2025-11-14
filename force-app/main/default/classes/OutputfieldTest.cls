@IsTest
public with sharing class OutputfieldTest {
    @IsTest
    static void testInvalidRelationshipField(){
        Map_Finder_Output_Fields__mdt outFlds = (Map_Finder_Output_Fields__mdt) JSON.deserialize('{"attributes":{"type":"Map_Finder_Output_Fields__mdt","url":"/services/data/v64.0/sobjects/Map_Finder_Output_Fields__mdt/m1LVG0000038kTl2AI"},"Id":"m1LVG0000038kTl2AI","Label__c":"Name","Object__c":"ucinn_ascendv2__Address_Relation__c","Field__c":"ucinn_ascendv2__Expanded_Name_Formula__c","Lookup_Field__c":"ucinn_ascendv2__Contacts__c","Is_Marker_Property__c":false,"Is_Datatable_Property__c":true,"Order__c":1}', Map_Finder_Output_Fields__mdt.class);
        OutputfieldDataTable fieldSelectClause = new OutputfieldDataTable();
        fieldSelectClause.validateOutputfields(new List<Map_Finder_Output_Fields__mdt>{outFlds});
        System.assert(fieldSelectClause.outputFields == null);
    }

    @IsTest
    static void testInvalidField(){
        Map_Finder_Output_Fields__mdt outFlds = (Map_Finder_Output_Fields__mdt) JSON.deserialize('{"attributes":{"type":"Map_Finder_Output_Fields__mdt","url":"/services/data/v64.0/sobjects/Map_Finder_Output_Fields__mdt/m1LVG0000038kTl2AI"},"Id":"m1LVG0000038kTl2AI","Label__c":"Name","Object__c":"ucinn_ascendv2__Address_Relation__c","Field__c":"ucinn_ascendv2__Expanded_Name_Formulas__c","Lookup_Field__c":"ucinn_ascendv2__Contact__c","Is_Marker_Property__c":false,"Is_Datatable_Property__c":true,"Order__c":1}', Map_Finder_Output_Fields__mdt.class);
        OutputfieldDataTable fieldSelectClause = new OutputfieldDataTable();
        fieldSelectClause.validateOutputfields(new List<Map_Finder_Output_Fields__mdt>{outFlds});
        System.assert(fieldSelectClause.outputFields == null);
    }

    @IsTest
    static void testInvalidNonParentField(){
        Map_Finder_Output_Fields__mdt outFlds = (Map_Finder_Output_Fields__mdt) JSON.deserialize('{"attributes":{"type":"Map_Finder_Output_Fields__mdt","url":"/services/data/v64.0/sobjects/Map_Finder_Output_Fields__mdt/m1LVG0000038kTl2AI"},"Id":"m1LVG0000038kTl2AI","Label__c":"Name","Object__c":"ucinn_ascendv2__Address_Relation__c","Field__c":"ucinn_ascendv2__Expanded_Name_Formulas__c","Is_Marker_Property__c":false,"Is_Datatable_Property__c":true,"Order__c":1}', Map_Finder_Output_Fields__mdt.class);
        OutputfieldDataTable fieldSelectClause = new OutputfieldDataTable();
        fieldSelectClause.validateOutputfields(new List<Map_Finder_Output_Fields__mdt>{outFlds});
        System.assert(fieldSelectClause.outputFields == null);
        
    }
}