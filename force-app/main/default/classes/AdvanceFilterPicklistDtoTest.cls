@IsTest
public with sharing class AdvanceFilterPicklistDtoTest {
    @IsTest
    static void testOptionsFromObject(){
        String multiPickStr = '{"attributes":{"type":"Map_Finder_Advance_Filter__mdt","url":"/services/data/v64.0/sobjects/Map_Finder_Advance_Filter__mdt/m1JVG000005bEtx2AE"},"Id":"m1JVG000005bEtx2AE","Object__c":"Contact","Object_s_Lookup_API_Name__c":"ucinn_ascendv2__Contact__r","Label__c":"Country of Citizenship","Multi_Row__c":true,"Field__c":"Country_of_Citizenship__c","Is_Options_from_Object__c":true,"Type__c":"multi-select"}';
        Map_Finder_Advance_Filter__mdt filter = (Map_Finder_Advance_Filter__mdt) JSON.deserialize(multiPickStr, Map_Finder_Advance_Filter__mdt.class);
        AdvanceFilterPicklistDto advFilterPicklistDto = new AdvanceFilterPicklistDto(filter.Id, filter.Object__c, filter.Object_s_Lookup_API_Name__c, filter.Label__c, filter.Field__c, filter.Type__c, filter.Multi_Row__c, filter.Is_Options_from_Object__c, filter.Record_Type_Id__c, filter.Map_Finder_Adv_Filter_Options__r);

        System.assert(advFilterPicklistDto.options.size() > 0);
    }

    @IsTest
    static void testOptionsFromMdts(){
        String multiPickStr = '{"attributes":{"type":"Map_Finder_Advance_Filter__mdt","url":"/services/data/v64.0/sobjects/Map_Finder_Advance_Filter__mdt/m1JVG000005Z6in2AC"},"Id":"m1JVG000005Z6in2AC","Object__c":"Contact","Object_s_Lookup_API_Name__c":"ucinn_ascendv2__Contact__r","Label__c":"Preferred Class","Multi_Row__c":false,"Field__c":"ucinn_ascendv2__Preferred_Class_Year__c","Is_Options_from_Object__c":false,"Type__c":"combobox","Map_Finder_Adv_Filter_Options__r":{"totalSize":2,"done":true,"records":[{"attributes":{"type":"Map_Finder_Adv_Filter_Options__mdt","url":"/services/data/v64.0/sobjects/Map_Finder_Adv_Filter_Options__mdt/m1KVG00000MB3Qv2AL"},"Map_Finder_Advance_Filter__c":"m1JVG000005Z6in2AC","Id":"m1KVG00000MB3Qv2AL","Label__c":"1969","Value__c":"1969","Is_Range__c":false},{"attributes":{"type":"Map_Finder_Adv_Filter_Options__mdt","url":"/services/data/v64.0/sobjects/Map_Finder_Adv_Filter_Options__mdt/m1KVG00000MAd532AD"},"Map_Finder_Advance_Filter__c":"m1JVG000005Z6in2AC","Id":"m1KVG00000MAd532AD","Label__c":"2007","Value__c":"2007","Is_Range__c":false}]}}';
        Map_Finder_Advance_Filter__mdt filter = (Map_Finder_Advance_Filter__mdt) JSON.deserialize(multiPickStr, Map_Finder_Advance_Filter__mdt.class);
        AdvanceFilterPicklistDto advFilterPicklistDto = new AdvanceFilterPicklistDto(filter.Id, filter.Object__c, filter.Object_s_Lookup_API_Name__c, filter.Label__c, filter.Field__c, filter.Type__c, filter.Multi_Row__c, filter.Is_Options_from_Object__c, filter.Record_Type_Id__c, filter.Map_Finder_Adv_Filter_Options__r);

        System.assert(advFilterPicklistDto.options.size() > 0);
    }

    @IsTest
    static void testRangeOptions(){
        String multiPickStr = '{"attributes":{"type":"Map_Finder_Advance_Filter__mdt","url":"/services/data/v64.0/sobjects/Map_Finder_Advance_Filter__mdt/m1JVG000005cdOr2AI"},"Id":"m1JVG000005cdOr2AI","Object__c":"Contact","Object_s_Lookup_API_Name__c":"ucinn_ascendv2__Contact__r","Label__c":"CONS YRS GIVING","Multi_Row__c":true,"Field__c":"HAM_Consecutive_Years_of_Giving__c","Is_Options_from_Object__c":false,"Type__c":"combobox","Map_Finder_Adv_Filter_Options__r":{"totalSize":3,"done":true,"records":[{"attributes":{"type":"Map_Finder_Adv_Filter_Options__mdt","url":"/services/data/v64.0/sobjects/Map_Finder_Adv_Filter_Options__mdt/m1KVG00000MBXVR2A5"},"Map_Finder_Advance_Filter__c":"m1JVG000005cdOr2AI","Id":"m1KVG00000MBXVR2A5","Label__c":"Less than 30","Value__c":"30","Is_Range__c":true},{"attributes":{"type":"Map_Finder_Adv_Filter_Options__mdt","url":"/services/data/v64.0/sobjects/Map_Finder_Adv_Filter_Options__mdt/m1KVG00000MBVGj2AP"},"Map_Finder_Advance_Filter__c":"m1JVG000005cdOr2AI","Id":"m1KVG00000MBVGj2AP","Label__c":"More than 30","Value__c":"30-","Is_Range__c":true},{"attributes":{"type":"Map_Finder_Adv_Filter_Options__mdt","url":"/services/data/v64.0/sobjects/Map_Finder_Adv_Filter_Options__mdt/m1KVG00000MBVIL2A5"},"Map_Finder_Advance_Filter__c":"m1JVG000005cdOr2AI","Id":"m1KVG00000MBVIL2A5","Label__c":"25-29","Value__c":"25-29","Is_Range__c":true}]}}';
        
        Map_Finder_Advance_Filter__mdt filter = (Map_Finder_Advance_Filter__mdt) JSON.deserialize(multiPickStr, Map_Finder_Advance_Filter__mdt.class);
        AdvanceFilterPicklistDto advFilterPicklistDto = new AdvanceFilterPicklistDto(filter.Id, filter.Object__c, filter.Object_s_Lookup_API_Name__c, filter.Label__c, filter.Field__c, filter.Type__c, filter.Multi_Row__c, filter.Is_Options_from_Object__c, filter.Record_Type_Id__c, filter.Map_Finder_Adv_Filter_Options__r);

        System.assert(advFilterPicklistDto.options.size() > 0);
        System.assertEquals(advFilterPicklistDto.improperlyConfigured, true); //one option doesn't statisfy the condition pattern (\\d*-\\d+|\\d+-\\d*)
    }
}