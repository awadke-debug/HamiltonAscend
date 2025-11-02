public with sharing class MapFinderController {
    @AuraEnabled(cacheable=true)
    public static List<Object> getConstituentAdvanceFilters(String mapInstance){
        List<Object> advanceFilters = new List<Object>();
        List<Map_Finder_Advance_Filter__mdt> filters = [SELECT Id, Object__c, Object_s_Lookup_API_Name__c, Label__c, Multi_Row__c, Field__c, Is_Options_from_Object__c, Record_Type_Id__c, Type__c 
                , (SELECT Id, Label__c, Value__c, Is_Range__c, Order__c FROM Map_Finder_Adv_Filter_Options__r)
            FROM Map_Finder_Advance_Filter__mdt WHERE Map_Finder_Instance__r.DeveloperName = :mapInstance AND Is_Active__c = true];
        
        if (Test.isRunningTest()) {
            filters = (List<Map_Finder_Advance_Filter__mdt>) JSON.deserialize('[{"attributes":{"type":"Map_Finder_Advance_Filter__mdt","url":"/services/data/v64.0/sobjects/Map_Finder_Advance_Filter__mdt/m1JVG000005fQ0T2AU"},"Id":"m1JVG000005fQ0T2AU","Object__c":"ucinn_ascendv2__Address_Relation__c","Label__c":"ADDRESS TYPE","Multi_Row__c":false,"Field__c":"ucinn_ascendv2__Type__c","Is_Options_from_Object__c":true,"Type__c":"combobox"},{"attributes":{"type":"Map_Finder_Advance_Filter__mdt","url":"/services/data/v64.0/sobjects/Map_Finder_Advance_Filter__mdt/m1JVG000005cdOr2AI"},"Id":"m1JVG000005cdOr2AI","Object__c":"Contact","Object_s_Lookup_API_Name__c":"ucinn_ascendv2__Contact__r","Label__c":"CONS YRS GIVING","Multi_Row__c":true,"Field__c":"HAM_Consecutive_Years_of_Giving__c","Is_Options_from_Object__c":false,"Type__c":"combobox","Map_Finder_Adv_Filter_Options__r":{"totalSize":3,"done":true,"records":[{"attributes":{"type":"Map_Finder_Adv_Filter_Options__mdt","url":"/services/data/v64.0/sobjects/Map_Finder_Adv_Filter_Options__mdt/m1KVG00000MBXVR2A5"},"Map_Finder_Advance_Filter__c":"m1JVG000005cdOr2AI","Id":"m1KVG00000MBXVR2A5","Label__c":"Less than 30","Value__c":"-30","Is_Range__c":true},{"attributes":{"type":"Map_Finder_Adv_Filter_Options__mdt","url":"/services/data/v64.0/sobjects/Map_Finder_Adv_Filter_Options__mdt/m1KVG00000MBVGj2AP"},"Map_Finder_Advance_Filter__c":"m1JVG000005cdOr2AI","Id":"m1KVG00000MBVGj2AP","Label__c":"More than 30","Value__c":"30-","Is_Range__c":true},{"attributes":{"type":"Map_Finder_Adv_Filter_Options__mdt","url":"/services/data/v64.0/sobjects/Map_Finder_Adv_Filter_Options__mdt/m1KVG00000MBVIL2A5"},"Map_Finder_Advance_Filter__c":"m1JVG000005cdOr2AI","Id":"m1KVG00000MBVIL2A5","Label__c":"25-29","Value__c":"25-29","Is_Range__c":true}]}},{"attributes":{"type":"Map_Finder_Advance_Filter__mdt","url":"/services/data/v64.0/sobjects/Map_Finder_Advance_Filter__mdt/m1JVG000005dpXd2AI"},"Id":"m1JVG000005dpXd2AI","Object__c":"Contact","Object_s_Lookup_API_Name__c":"ucinn_ascendv2__Contact__r","Label__c":"Chapter","Multi_Row__c":false,"Field__c":"HAM_Chapter__c","Is_Options_from_Object__c":false,"Type__c":"record-picker"},{"attributes":{"type":"Map_Finder_Advance_Filter__mdt","url":"/services/data/v64.0/sobjects/Map_Finder_Advance_Filter__mdt/m1JVG000005bEtx2AE"},"Id":"m1JVG000005bEtx2AE","Object__c":"Contact","Object_s_Lookup_API_Name__c":"ucinn_ascendv2__Contact__r","Label__c":"Country of Citizenship","Multi_Row__c":true,"Field__c":"Country_of_Citizenship__c","Is_Options_from_Object__c":true,"Type__c":"multi-select"},{"attributes":{"type":"Map_Finder_Advance_Filter__mdt","url":"/services/data/v64.0/sobjects/Map_Finder_Advance_Filter__mdt/m1JVG000005b5972AA"},"Id":"m1JVG000005b5972AA","Object__c":"Contact","Object_s_Lookup_API_Name__c":"ucinn_ascendv2__Contact__r","Label__c":"MG Rating","Multi_Row__c":true,"Field__c":"HAM_Rating_Number__c","Is_Options_from_Object__c":false,"Type__c":"number"},{"attributes":{"type":"Map_Finder_Advance_Filter__mdt","url":"/services/data/v64.0/sobjects/Map_Finder_Advance_Filter__mdt/m1JVG000005Z6in2AC"},"Id":"m1JVG000005Z6in2AC","Object__c":"Contact","Object_s_Lookup_API_Name__c":"ucinn_ascendv2__Contact__r","Label__c":"Preferred Class","Multi_Row__c":false,"Field__c":"ucinn_ascendv2__Preferred_Class_Year__c","Is_Options_from_Object__c":false,"Type__c":"combobox","Map_Finder_Adv_Filter_Options__r":{"totalSize":2,"done":true,"records":[{"attributes":{"type":"Map_Finder_Adv_Filter_Options__mdt","url":"/services/data/v64.0/sobjects/Map_Finder_Adv_Filter_Options__mdt/m1KVG00000MB3Qv2AL"},"Map_Finder_Advance_Filter__c":"m1JVG000005Z6in2AC","Id":"m1KVG00000MB3Qv2AL","Label__c":"1969","Value__c":"1969","Is_Range__c":false},{"attributes":{"type":"Map_Finder_Adv_Filter_Options__mdt","url":"/services/data/v64.0/sobjects/Map_Finder_Adv_Filter_Options__mdt/m1KVG00000MAd532AD"},"Map_Finder_Advance_Filter__c":"m1JVG000005Z6in2AC","Id":"m1KVG00000MAd532AD","Label__c":"2007","Value__c":"2007","Is_Range__c":false}]}}]', List<Map_Finder_Advance_Filter__mdt>.class);
        }
        
        for (Map_Finder_Advance_Filter__mdt filter : filters) {
            if (filter.Type__c == 'combobox' || filter.Type__c == 'multi-select') {
                AdvanceFilterPicklistDto advFilterPicklistDto = new AdvanceFilterPicklistDto(filter.Id, filter.Object__c, filter.Object_s_Lookup_API_Name__c, filter.Label__c, filter.Field__c, filter.Type__c, filter.Multi_Row__c, filter.Is_Options_from_Object__c, filter.Record_Type_Id__c, filter.Map_Finder_Adv_Filter_Options__r);

                advanceFilters.add(advFilterPicklistDto);
            } else if (filter.Type__c == 'record-picker') {
                advanceFilters.add(new AdvanceFilterRecordPickerDto(filter.Id, filter.Object__c, filter.Object_s_Lookup_API_Name__c, filter.Label__c, filter.Field__c, filter.Type__c, filter.Multi_Row__c));
            } else {
                advanceFilters.add(new AdvanceFilterFieldDto(filter.Id, filter.Object__c, filter.Object_s_Lookup_API_Name__c, filter.Label__c, filter.Field__c, filter.Type__c, filter.Multi_Row__c));
            }
            
        }

        return advanceFilters;
    }

    @AuraEnabled(cacheable=true)
    public static ConstituentsWrapper getConstituentsByFilters(
        String mapInstance,
        AdvanceFilterParamWrapper filterWrapper, 
        Integer offset,
        Integer pageSize,
        String sortBy,
        String sortDirection)
    {
        MapFinderContext ctx = new MapFinderContext(mapInstance);
        List<SObject> results = ctx.fetchContactsByFilters(filterWrapper, offset, pageSize, sortBy, sortDirection);

        ConstituentsWrapper result = new ConstituentsWrapper();
        result.constituents = results;
        result.totalSize = ctx.countContactsByFilters(filterWrapper);
        return result;
    }

    @AuraEnabled(cacheable=true)
    public static List<DataTableProperty> getDataTableProperties(String mapInstance) {
        List<DataTableProperty> properties = new List<DataTableProperty>();
        List<Map_Finder_Output_Fields__mdt> outFlds = [SELECT Id, Label__c, Object__c,  Field__c, Lookup_Field__c, Is_Marker_Property__c, Address_Property__c, Is_Datatable_Property__c, Order__c 
                        FROM Map_Finder_Output_Fields__mdt
                        WHERE Is_Datatable_Property__c = TRUE
                        AND Map_Finder_Instance__r.DeveloperName = :mapInstance ORDER BY Order__c];

        if (Test.isRunningTest()) {
            outFlds = (List<Map_Finder_Output_Fields__mdt>) JSON.deserialize('[{"attributes":{"type":"Map_Finder_Output_Fields__mdt","url":"/services/data/v64.0/sobjects/Map_Finder_Output_Fields__mdt/m1LVG0000038kTl2AI"},"Id":"m1LVG0000038kTl2AI","Label__c":"Name","Object__c":"ucinn_ascendv2__Address_Relation__c","Field__c":"ucinn_ascendv2__Expanded_Name_Formula__c","Lookup_Field__c":"ucinn_ascendv2__Contact__c","Is_Marker_Property__c":false,"Is_Datatable_Property__c":true,"Order__c":1},{"attributes":{"type":"Map_Finder_Output_Fields__mdt","url":"/services/data/v64.0/sobjects/Map_Finder_Output_Fields__mdt/m1LVG0000038kVN2AY"},"Id":"m1LVG0000038kVN2AY","Label__c":"Class Year","Object__c":"ucinn_ascendv2__Address_Relation__c","Field__c":"ucinn_ascendv2__Preferred_Class_Year_Integer_Formula__c","Lookup_Field__c":"ucinn_ascendv2__Contact__c","Is_Marker_Property__c":false,"Is_Datatable_Property__c":true,"Order__c":2},{"attributes":{"type":"Map_Finder_Output_Fields__mdt","url":"/services/data/v64.0/sobjects/Map_Finder_Output_Fields__mdt/m1LVG0000038kWz2AI"},"Id":"m1LVG0000038kWz2AI","Label__c":"Rating","Object__c":"ucinn_ascendv2__Address_Relation__c","Field__c":"HAM_Rating_Number__c","Lookup_Field__c":"ucinn_ascendv2__Contact__c","Is_Marker_Property__c":false,"Is_Datatable_Property__c":true,"Order__c":3}]', List<Map_Finder_Output_Fields__mdt>.class);
        }

        OutputfieldDataTable fieldSelectClause = new OutputfieldDataTable();
        fieldSelectClause.validateOutputfields(outFlds);
        properties.addAll((List<DataTableProperty>)fieldSelectClause.outputFields);
        return properties;
    }

    @AuraEnabled(cacheable=true)
    public static List<MapMarkerProperty> getMarkerProperties(String mapInstance) {
        List<MapMarkerProperty> properties = new List<MapMarkerProperty>();
        List<Map_Finder_Output_Fields__mdt> outFlds = [SELECT Id, Label__c, Object__c,  Field__c, Lookup_Field__c, Is_Marker_Property__c, Address_Property__c, Is_Datatable_Property__c 
                        FROM Map_Finder_Output_Fields__mdt
                        WHERE Is_Marker_Property__c = TRUE
                        AND Map_Finder_Instance__r.DeveloperName = :mapInstance];
        
        if (Test.isRunningTest()) {
            outFlds = (List<Map_Finder_Output_Fields__mdt>) JSON.deserialize('[{"attributes":{"type":"Map_Finder_Output_Fields__mdt","url":"/services/data/v64.0/sobjects/Map_Finder_Output_Fields__mdt/m1LVG0000038ktZ2AQ"},"Id":"m1LVG0000038ktZ2AQ","Label__c":"City","Object__c":"ucinn_ascendv2__Address_Relation__c","Field__c":"ucinn_ascendv2__City__c","Lookup_Field__c":"ucinn_ascendv2__Address__c","Is_Marker_Property__c":true,"Address_Property__c":"City","Is_Datatable_Property__c":false},{"attributes":{"type":"Map_Finder_Output_Fields__mdt","url":"/services/data/v64.0/sobjects/Map_Finder_Output_Fields__mdt/m1LVG0000038kwn2AA"},"Id":"m1LVG0000038kwn2AA","Label__c":"Country","Object__c":"ucinn_ascendv2__Address_Relation__c","Field__c":"ucinn_ascendv2__Country__c","Lookup_Field__c":"ucinn_ascendv2__Address__c","Is_Marker_Property__c":true,"Address_Property__c":"Country","Is_Datatable_Property__c":false},{"attributes":{"type":"Map_Finder_Output_Fields__mdt","url":"/services/data/v64.0/sobjects/Map_Finder_Output_Fields__mdt/m1LVG0000038koj2AA"},"Id":"m1LVG0000038koj2AA","Label__c":"Location Latitude","Object__c":"ucinn_ascendv2__Address_Relation__c","Field__c":"ucinn_ascendv2__Location__Latitude__s","Lookup_Field__c":"ucinn_ascendv2__Address__c","Is_Marker_Property__c":true,"Address_Property__c":"Latitude","Is_Datatable_Property__c":false},{"attributes":{"type":"Map_Finder_Output_Fields__mdt","url":"/services/data/v64.0/sobjects/Map_Finder_Output_Fields__mdt/m1LVG0000038krx2AA"},"Id":"m1LVG0000038krx2AA","Label__c":"Location Longitude","Object__c":"ucinn_ascendv2__Address_Relation__c","Field__c":"ucinn_ascendv2__Location__Longitude__s","Lookup_Field__c":"ucinn_ascendv2__Address__c","Is_Marker_Property__c":true,"Address_Property__c":"Longitude","Is_Datatable_Property__c":false},{"attributes":{"type":"Map_Finder_Output_Fields__mdt","url":"/services/data/v64.0/sobjects/Map_Finder_Output_Fields__mdt/m1LVG0000038kyP2AQ"},"Id":"m1LVG0000038kyP2AQ","Label__c":"PostalCode","Object__c":"ucinn_ascendv2__Address_Relation__c","Field__c":"ucinn_ascendv2__Postal_Code__c","Lookup_Field__c":"ucinn_ascendv2__Address__c","Is_Marker_Property__c":true,"Address_Property__c":"PostalCode","Is_Datatable_Property__c":false},{"attributes":{"type":"Map_Finder_Output_Fields__mdt","url":"/services/data/v64.0/sobjects/Map_Finder_Output_Fields__mdt/m1LVG0000038kvB2AQ"},"Id":"m1LVG0000038kvB2AQ","Label__c":"State","Object__c":"ucinn_ascendv2__Address_Relation__c","Field__c":"ucinn_ascendv2__State__c","Lookup_Field__c":"ucinn_ascendv2__Address__c","Is_Marker_Property__c":true,"Address_Property__c":"State","Is_Datatable_Property__c":false},{"attributes":{"type":"Map_Finder_Output_Fields__mdt","url":"/services/data/v64.0/sobjects/Map_Finder_Output_Fields__mdt/m1LVG0000038iS02AI"},"Id":"m1LVG0000038iS02AI","Label__c":"Street","Object__c":"ucinn_ascendv2__Address_Relation__c","Field__c":"ucinn_ascendv2__Address_Line_1__c","Lookup_Field__c":"ucinn_ascendv2__Address__c","Is_Marker_Property__c":true,"Address_Property__c":"Street","Is_Datatable_Property__c":false}]', List<Map_Finder_Output_Fields__mdt>.class);
        }

        OutputfieldMapMarker fieldSelectClause = new OutputfieldMapMarker();
        fieldSelectClause.validateOutputfields(outFlds);
        properties.addAll((List<MapMarkerProperty>)fieldSelectClause.outputFields);
        return properties;
    }

    @AuraEnabled(cacheable=true)
    public static List<DataTableProperty> getMarkerDescriptionProperties(String mapInstance){
        List<DataTableProperty> properties = new List<DataTableProperty>();
        List<Map_Finder_Output_Fields__mdt> outFlds = [SELECT Id, Label__c, Object__c,  Field__c, Lookup_Field__c, Is_Marker_Property__c, Is_Marker_Description__c, Address_Property__c, Is_Datatable_Property__c 
                        FROM Map_Finder_Output_Fields__mdt
                        WHERE Is_Marker_Description__c = TRUE
                        AND Map_Finder_Instance__r.DeveloperName = :mapInstance];

        OutputfieldMapMarker fieldSelectClause = new OutputfieldMapMarker();
        fieldSelectClause.validateOutputfields(outFlds);
        try {
            properties.addAll((List<DataTableProperty>)fieldSelectClause.outputFields);
        } catch (NullPointerException npe) {
            System.debug('Empty marker description fields');
        }
        return properties;
    }

    @AuraEnabled(cacheable=true)
    public static GeolocationWrapper getAddressCoordinates(String addressParam){
        GeocodingCallout call = new GeocodingCallout();
        GeocodeResponse geoResp = call.getCoordinates(addressParam);
        GeocodeResponse.location loc = geoResp.results[0].geometry.location;
        
        GeolocationWrapper result = new GeolocationWrapper();
        result.Latitude = loc.latStr;
        result.Longitude = loc.lngStr;
        for (GeocodeResponse.address_components address_component: geoResp.results[0].address_components) {
            if (address_component.types.contains('locality')) {
                result.City = address_component.long_name;
            }
            
            if (address_component.types.contains('country')) {
                result.Country = address_component.short_name;
            }
            
            if (address_component.types.contains('postal_code')) {
                result.PostalCode = address_component.long_name;
            }
            
            if (address_component.types.contains('administrative_area_level_1')) {
                result.State = address_component.short_name;
            }
            
            if (address_component.types.contains('street_number')) {
                result.Street = address_component.long_name;
            }
        }
        return result;
    }

    @AuraEnabled(cacheable=true)
    public static List<DataTableProperty> getAllProperties(String mapInstance) {
        Map_Finder_Instance__mdt mfi = Map_Finder_Instance__mdt.getInstance(mapInstance);
        
        List<String> lookupFields = new List<String>();
        if (mfi.Parent_Objects__c != null) {
            lookupFields = new List<String>(mfi.Parent_Objects__c.split(','));
        }
        
        List<DataTableProperty> props = new List<DataTableProperty>();
        extractObjectFields(mfi.Object__c, null, props);

        Map<String, Schema.SObjectField> mainFieldMap = Schema.getGlobalDescribe().get(mfi.Object__c).getDescribe().fields.getMap();
        for (String lookupField: lookupFields) {
            String relationshipName = mainFieldMap.get(lookupField).getDescribe().getRelationshipName();
            String parentObjName = String.valueOf(mainFieldMap.get(lookupField).getDescribe().getReferenceTo()[0]);
            extractObjectFields(parentObjName, relationshipName, props);
        }

        props.sort();
        return props;
    }

    @AuraEnabled(cacheable=true)
    public static List<SObject> getContactsForExport(
        String mapInstance,
        List<String> fields,
        AdvanceFilterParamWrapper filterWrapper,
        String sortBy,
        String sortDirection
    ){

        return MapFinderService.fetchContactsForExport(mapInstance, fields, filterWrapper, sortBy, sortDirection);
    }

    @AuraEnabled
    public static void saveFilters(String mapInstance, List<AdvanceFilterParam> params) {
        try {
            
            List<Map_Finder_User_s_Filter__c> filtersToUpsert = new List<Map_Finder_User_s_Filter__c>();
    
            for(AdvanceFilterParam param : params) {
                Map_Finder_User_s_Filter__c filter = new Map_Finder_User_s_Filter__c();
                filter.Field_Label__c = param.fieldLabel;
                filter.Filter_Key__c = param.key;
                filter.Operator__c = param.operator;
                filter.Value__c = param.fieldValue;
                filter.Is_Range__c = param.isRange == null ? false : param.isRange;
                filter.External_Id__c = param.key + param.owner;
                filter.Map_Instance__c = mapInstance;
    
                filtersToUpsert.add(filter);
            }
    
            upsert filtersToUpsert External_Id__c;

        } catch (Exception e) {
            System.debug('@@Error saving filters::' + e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }

    }

    @AuraEnabled(cacheable=false)
    public static Map_Finder_User_s_Filter__c loadSavedFilterByExternalId(String mapInstance, String externalId) {
        try {
            return [
                SELECT 
                    Id, External_Id__c, Filter_Key__c, OwnerId, Operator__c, Value__c, Is_Range__c 
                FROM Map_Finder_User_s_Filter__c
                WHERE External_Id__c = :externalId
                    AND Map_Instance__c = :mapInstance
                LIMIT 1
            ];
        } catch (QueryException e) {
            System.debug('User filter with externalId: ' + externalId + ' not found');
            return null;
        }
    }

    @AuraEnabled
    public static List<String> invalidSavedFilters(String mapInstance){
        List<String> errorList = new List<String>();

        Map<String, Map_Finder_Advance_Filter__mdt> filterCmdtMap = new Map<String, Map_Finder_Advance_Filter__mdt>([
            SELECT Id, Label__c 
            FROM Map_Finder_Advance_Filter__mdt 
            WHERE Map_Finder_Instance__r.DeveloperName = :mapInstance
                AND Is_Active__c = true]);

        Set<String> filterKeys = new Set<String>();
        filterKeys.addAll(filterCmdtMap.keySet());
        filterKeys.add('address');
        filterKeys.add('radius');

        List<Map_Finder_User_s_Filter__c> filters = [
            SELECT Id, Filter_Key__c, Field_Label__c 
            FROM Map_Finder_User_s_Filter__c 
            WHERE OwnerId = :UserInfo.getUserId() 
                AND Map_Instance__c = :mapInstance
                AND Filter_Key__c NOT IN :filterKeys];

        if(filters.size() > 0){
            for (Map_Finder_User_s_Filter__c filter : filters) {
                errorList.add(filter.Field_Label__c);
            }
        }

        return errorList;

    }

    @AuraEnabled
    public static void deleteSavedFilters(String mapInstance){
        try {
            delete [SELECT Id FROM Map_Finder_User_s_Filter__c WHERE OwnerId = :UserInfo.getUserId() AND Map_Instance__c = :mapInstance];
        } catch (Exception e) {
            System.debug('@@Error deleting filters::' + e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static Boolean isMarketingUser(){
        try {
            User u = [SELECT Id, UserPermissionsMarketingUser FROM User WHERE Id = :UserInfo.getUserId()];
            return u.UserPermissionsMarketingUser;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static Boolean isCampaignMemberFieldValid(String mapInstance){
        try {
            Map_Finder_Instance__mdt mfi = Map_Finder_Instance__mdt.getInstance(mapInstance);
            
            if (String.isBlank(mfi.Campaign_Member_Id_Field__c)) {
                return false;
            }

            Schema.SObjectField memberIdField = Schema.getGlobalDescribe().get(mfi.Object__c).getDescribe().fields.getMap().get(mfi.Campaign_Member_Id_Field__c);
            if (memberIdField.getDescribe().getType() == Schema.DisplayType.Reference
                && memberIdField.getDescribe().getReferenceTo().contains(Contact.SObjectType)) {
                    return true;
            }
            return false;
        } catch (Exception e) {
            System.debug(e.getMessage());
            return false;
        }
    }

    @AuraEnabled
    public static void addCampaignMembers(String mapInstance, AdvanceFilterParamWrapper filterWrapper, Id campaignId){
        try {
            MapFinderService.addContactsToCampaign(mapInstance, filterWrapper, campaignId);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static Boolean isValidContactField(String contactId){
        if (String.isBlank(contactId)) {
            return false;
        }

        Id recordId = contactId;
        Schema.SObjectType objectType = recordId.getSobjectType();
        String objectName = objectType.getDescribe().getName();
        if (objectName == 'Contact') {
            return true;
        } else {
            return false;
        }
    }

    private static void extractObjectFields(String objectName, String relationshipName, List<DataTableProperty> props) {
        Map<String, Schema.SObjectField> fieldMap = Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap();
        
       for (Schema.SObjectField fld : fieldMap.values()) {
           Schema.DescribeFieldResult descFldRes = fld.getDescribe();

           if (descFldRes.isAccessible() && descFldRes.getRelationshipName() == null) {

                DataTableProperty prop = new DataTableProperty();
                prop.label = descFldRes.getLabel();
                prop.fieldName = descFldRes.getName();
                prop.lookupApiName = relationshipName;
                props.add(prop);
           }
       }
    }

    public class GeolocationWrapper {
        @AuraEnabled
        public String City {get; set;}
        @AuraEnabled
        public String Country {get; set;}
        @AuraEnabled
        public String PostalCode {get; set;}
        @AuraEnabled
        public String State {get; set;}
        @AuraEnabled
        public String Street {get; set;}
        @AuraEnabled
        public String Latitude {get;   set;}
        @AuraEnabled
        public String Longitude {get; set;}
    }

    public class ConstituentsWrapper {
        @AuraEnabled
        public List<SObject> constituents { get; set; }
        @AuraEnabled
        public Integer totalSize { get; set; }
    }

}