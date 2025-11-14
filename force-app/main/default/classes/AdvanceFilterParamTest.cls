@IsTest
public with sharing class AdvanceFilterParamTest {
    @IsTest
    static void testGetFilter_multipick(){
        // String multiPickStr = '{"attributes":{"type":"Map_Finder_Advance_Filter__mdt","url":"/services/data/v64.0/sobjects/Map_Finder_Advance_Filter__mdt/m1JVG000005bEtx2AE"},"Id":"m1JVG000005bEtx2AE","Object__c":"Contact","Object_s_Lookup_API_Name__c":"ucinn_ascendv2__Contact__r","Label__c":"Country of Citizenship","Multi_Row__c":true,"Field__c":"Country_of_Citizenship__c","Is_Options_from_Object__c":true,"Type__c":"multi-select"}';
        // Map_Finder_Advance_Filter__mdt filter = (Map_Finder_Advance_Filter__mdt) JSON.deserialize(multiPickStr, Map_Finder_Advance_Filter__mdt.class);
        // AdvanceFilterPicklistDto advFilterPicklistDto = new AdvanceFilterPicklistDto(filter.Id, filter.Object__c, filter.Object_s_Lookup_API_Name__c, filter.Label__c, filter.Field__c, filter.Type__c, filter.Multi_Row__c, filter.Is_Options_from_Object__c, filter.Record_Type_Id__c, filter.Map_Finder_Adv_Filter_Options__r);
        String paramStr = '{"fieldName":"Country_of_Citizenship__c","operator":"includes","fieldValue":"AFG;ALB","fieldType":"MULTIPICKLIST","lookupFieldApiName":"ucinn_ascendv2__Contact__r"}';
        AdvanceFilterParam param = (AdvanceFilterParam) JSON.deserialize(paramStr, AdvanceFilterParam.class);
        Map<String,Object> bindVars = new Map<String,Object>();
        String result = param.getFilterItem(0, bindVars);
        System.Assert.areEqual('ucinn_ascendv2__Contact__r.Country_of_Citizenship__c includes (\'AFG\',\'ALB\')', result);
    }

    @IsTest
    static void testGetFilter_range() {
        String paramStr = '{"fieldName":"HAM_Consecutive_Years_of_Giving__c","operator":"=","fieldValue":"25-29","fieldType":"DOUBLE","isRange":true,"lookupFieldApiName":"ucinn_ascendv2__Contact__r"}';
        AdvanceFilterParam param = (AdvanceFilterParam) JSON.deserialize(paramStr, AdvanceFilterParam.class);
        Map<String,Object> bindVars = new Map<String,Object>();
        String result = param.getFilterItem(0, bindVars);

        paramStr = '{"fieldName":"HAM_Consecutive_Years_of_Giving__c","operator":"=","fieldValue":"-30","fieldType":"DOUBLE","isRange":true,"lookupFieldApiName":"ucinn_ascendv2__Contact__r"}';
        param = (AdvanceFilterParam) JSON.deserialize(paramStr, AdvanceFilterParam.class);
        bindVars = new Map<String,Object>();
        result = param.getFilterItem(0, bindVars);
    }

    @IsTest
    static void testBuildBindVars(){
        Map<String,Object> bindVars = new Map<String,Object>();
        AdvanceFilterParam.buildBindVars('true', Schema.DisplayType.valueOf('BOOLEAN'), bindVars, 0);
        System.assertEquals(Boolean.valueOf('true'), (Boolean) bindVars.get('arg0'));

        AdvanceFilterParam.buildBindVars('10/14/2011, 11:46 AM', Schema.DisplayType.valueOf('DATETIME'), bindVars, 0);
        System.assertEquals(DateTime.parse('10/14/2011, 11:46 AM'), (DateTime) bindVars.get('arg0'));

        AdvanceFilterParam.buildBindVars('12/27/2023', Schema.DisplayType.valueOf('DATE'), bindVars, 0);
        System.assertEquals(Date.parse('12/27/2023'), (Date) bindVars.get('arg0'));

        AdvanceFilterParam.buildBindVars('30', Schema.DisplayType.valueOf('INTEGER'), bindVars, 0);
        System.assertEquals(Integer.valueOf('30'), (Integer) bindVars.get('arg0'));

        AdvanceFilterParam.buildBindVars('30', Schema.DisplayType.valueOf('DOUBLE'), bindVars, 0);
        System.assertEquals(Double.valueOf('30'), (Double) bindVars.get('arg0'));

         AdvanceFilterParam.buildBindVars('30.50', Schema.DisplayType.valueOf('CURRENCY'), bindVars, 0);
        System.assertEquals(Decimal.valueOf('30.50'), (Decimal) bindVars.get('arg0'));

    }
}