public with sharing class MapFinderService {

    public static List<SObject> fetchContactsByFilters(
            String mapInstance,
            List<AdvanceFilterParam> advanceFilterParams, 
            Decimal latitude, 
            Decimal longitude, 
            Integer radius,
            Integer offset,
            Integer pageSize,
            String sortBy,
            String sortDirection) 
    {
        Map<String, Object> bindVars = new Map<String, Object>();
        String q = buildQueryWithFilter(mapInstance, buildBaseQuery(mapInstance), advanceFilterParams, bindVars, latitude, longitude, radius);

        q += String.format(' ORDER BY {0} {1} LIMIT {2} OFFSET {3}', new List<Object>{ sortBy, sortDirection, ':pageSize', ':offset' });

        bindVars.put('pageSize', pageSize);
        bindVars.put('offset', offset);

        return Database.queryWithBinds(q, bindVars, AccessLevel.USER_MODE);
    }

    public static Integer countContactsByFilters(
            String mapInstance,
            List<AdvanceFilterParam> advanceFilterParams, 
            Decimal latitude, 
            Decimal longitude, 
            Integer radius) 
    {
        Map_Finder_Instance__mdt mfi = Map_Finder_Instance__mdt.getInstance(mapInstance);

        Map<String, Object> bindVars = new Map<String, Object>();
        String q = buildQueryWithFilter(mapInstance,
                String.format(
                    'SELECT COUNT() FROM {0} WHERE {1} AND ', 
                    new List<Object>{mfi.Object__c, mfi.Base_Filter__c}
                ), 
                advanceFilterParams, bindVars, latitude, longitude, radius);

        return Database.countQueryWithBinds(q, bindVars, AccessLevel.USER_MODE);
    }

    public static List<SObject> fetchContactsForExport(
            String mapInstance,
            List<String> fields,
            AdvanceFilterParamWrapper filterWrapper,
            String sortBy,
            String sortDirection
    ) {
        Map_Finder_Instance__mdt mfi = Map_Finder_Instance__mdt.getInstance(mapInstance);

        Map<String, Object> bindVars = new Map<String, Object>();

        String q = buildQueryWithFilter(mapInstance,
            String.format(
                'SELECT {0} FROM {1} WHERE {2} AND ', 
                new List<Object>{ String.join(fields, ', '), mfi.Object__c, mfi.Base_Filter__c }
            ), 
            filterWrapper.advanceFilterParams, bindVars, filterWrapper.latitude, filterWrapper.longitude, filterWrapper.radius
        );

        if (filterWrapper.addressRelationIds != null && !filterWrapper.addressRelationIds.isEmpty()){
            q += String.format(' AND Id {0} :addressRelationIds', new List<Object>{ filterWrapper.isExportAll ? 'NOT IN': 'IN' });
        }

        if (!String.isBlank(sortBy)) {
            q += String.format(' ORDER BY {0} {1} LIMIT {2}', new List<Object>{ sortBy, String.isBlank(sortDirection) ? 'ASC' : sortDirection, ':pageSize' });
        }

        bindVars.put('addressRelationIds', filterWrapper.addressRelationIds);
        bindVars.put('pageSize', 50000);

        return Database.queryWithBinds(q, bindVars, AccessLevel.USER_MODE);
    }

    public static void addContactsToCampaign(String mapInstance, AdvanceFilterParamWrapper filterWrapper, Id campaignId) {
        Map_Finder_Instance__mdt mfi = Map_Finder_Instance__mdt.getInstance(mapInstance);

        List<String> fields = new List<String>{ mfi.Campaign_Member_Id_Field__c };
        List<SObject> contacts = fetchContactsForExport(mapInstance, fields, filterWrapper, null, null);

        Set<Id> contactIds = new Set<Id>();
        List<CampaignMember> campaignMembersToAdd = new List<CampaignMember>();

        for (SObject contact : contacts) {
            try {

                Id contactId = (Id) contact.get(mfi.Campaign_Member_Id_Field__c);
                if (contactIds.contains(contactId) || contactId.getSobjectType().getDescribe().getName() != 'Contact') {
                    continue;
                }
    
                contactIds.add(contactId);
                CampaignMember cm = new CampaignMember(CampaignId = campaignId);
                
                campaignMembersToAdd.add(cm);
            } catch (StringException e) {
                System.debug(e.getMessage());
            } catch (Exception e) {
                System.debug(e.getMessage());
            }
        }

        if (!campaignMembersToAdd.isEmpty()) {
            Database.SaveResult[] campaignMemberSaveResults = Database.insert(campaignMembersToAdd, false);
            for (Database.SaveResult sr : campaignMemberSaveResults) {
                if (!sr.isSuccess()) {
                    for(Database.Error err : sr.getErrors()) {
                        System.debug('@@ campaign member insert error ' + err.getMessage());
                    }
                }
            }
        }
    }

    private static String buildQueryWithFilter(String mapInstance, String q, List<AdvanceFilterParam> advanceFilterParams, Map<String, Object> bindVars, Decimal latitude, Decimal longitude, Integer radius) {
        Map_Finder_Instance__mdt mfi = Map_Finder_Instance__mdt.getInstance(mapInstance);
        
        List<String> filters = new List<String>();
        for (Integer i = 0; i < advanceFilterParams.size(); i++) {
            AdvanceFilterParam advanceFilterParam = advanceFilterParams[i];
            filters.add(advanceFilterParam.getFilterItem(i, bindVars));
        }

        q += String.join(filters, ' AND ');

        if (radius != null && latitude != null && longitude != null) {
            q += advanceFilterParams.size() > 0 ? ' AND ' :'';
            q += String.format('DISTANCE({0}, GEOLOCATION({1}, {2}), \'mi\') < {3}', 
                new List<Object>{mfi.Geolocation_Field__c, latitude, longitude, radius});
        }

        return q;
    }

    private static String buildBaseQuery(String mapInstance) {
        Map_Finder_Instance__mdt mfi = Map_Finder_Instance__mdt.getInstance(mapInstance);

        List<String> filters = new List<String>();
        Map_Finder_Output_Fields__mdt [] outFlds = [
            SELECT Id, Label__c, Object__c,  Field__c, Lookup_Field__c, Is_Marker_Property__c, Address_Property__c 
            FROM Map_Finder_Output_Fields__mdt 
            WHERE Map_Finder_Instance__r.DeveloperName = :mapInstance];

        OutputfieldSelectClause fieldSelectClause = new OutputfieldSelectClause();
        fieldSelectClause.validateOutputfields(outFlds);
        filters.addAll((List<String>)fieldSelectClause.outputFields);

        return String.format('SELECT {0} FROM {1} WHERE {2} AND ', new List<Object>{ String.join(filters, ', '), mfi.Object__c, mfi.Base_Filter__c });
    }

}