public with sharing abstract class MapFinderAbstract implements MapFinderInterface{
    protected Map<String, Object> filterAugmentation;
    private String mapInstance;
    protected Map_Finder_Instance__mdt mfi;

    public String buildBaseQuery() {
        List<String> filters = new List<String>();
        Map_Finder_Output_Fields__mdt [] outFlds = [
            SELECT Id, Label__c, Object__c,  Field__c, Lookup_Field__c, Is_Marker_Property__c, Address_Property__c 
            FROM Map_Finder_Output_Fields__mdt 
            WHERE Map_Finder_Instance__r.DeveloperName = :mapInstance];

        OutputfieldSelectClause fieldSelectClause = new OutputfieldSelectClause();
        fieldSelectClause.validateOutputfields(outFlds);
        filters.addAll((List<String>)fieldSelectClause.outputFields);

        return String.format('SELECT {0} FROM {1} WHERE {2}', new List<Object>{ String.join(filters, ', '), mfi.Object__c, String.isNotBlank(mfi.Base_Filter__c) ? mfi.Base_Filter__c + ' AND ' : '' });
    }
    
    public String buildQueryWithFilter(String q, List<AdvanceFilterParam> advanceFilterParams, Map<String, Object> bindVars, Decimal latitude, Decimal longitude, Integer radius) {
        List<String> filters = new List<String>();
        for (Integer i = 0; i < advanceFilterParams.size(); i++) {
            AdvanceFilterParam advanceFilterParam = advanceFilterParams[i];
            filters.add(advanceFilterParam.getFilterItem(i, bindVars));
        }

        q += String.join(filters, ' AND ');

        Boolean hasGeolocationFilter = false;
        if (radius != null && latitude != null && longitude != null) {
            q += filters.size() > 0 ? ' AND ' :'';
            q += String.format('DISTANCE({0}, GEOLOCATION({1}, {2}), \'mi\') < {3}', 
                new List<Object>{mfi.Geolocation_Field__c, latitude, longitude, radius});

            hasGeolocationFilter = true;
        }

        if (this.filterAugmentation == null) return q;

        q += (filters.size() > 0 || hasGeolocationFilter) ? ' AND ' + augmentQueryFilter(bindVars) : augmentQueryFilter(bindVars);

        return q;
    }

    public List<SObject> fetchContactsByFilters(
            List<AdvanceFilterParam> advanceFilterParams, 
            Decimal latitude, 
            Decimal longitude, 
            Integer radius,
            Integer offset,
            Integer pageSize,
            String sortBy,
            String sortDirection
    ) {
        Map<String, Object> bindVars = new Map<String, Object>();
        String q = buildQueryWithFilter(buildBaseQuery(), advanceFilterParams, bindVars, latitude, longitude, radius);

        q += String.format(' ORDER BY {0} {1} LIMIT {2} OFFSET {3}', new List<Object>{ sortBy, sortDirection, ':pageSize', ':offset' });

        bindVars.put('pageSize', pageSize);
        bindVars.put('offset', offset);

        System.debug(q);
        return Database.queryWithBinds(q, bindVars, AccessLevel.USER_MODE);
    }

    public Integer countContactsByFilters(
            List<AdvanceFilterParam> advanceFilterParams, 
            Decimal latitude, 
            Decimal longitude, 
            Integer radius) 
    {
        Map<String, Object> bindVars = new Map<String, Object>();
        String q = buildQueryWithFilter(
            String.format('SELECT COUNT() FROM {0} WHERE {1} AND ', new List<Object>{ mfi.Object__c, mfi.Base_Filter__c }), 
            advanceFilterParams, bindVars, latitude, longitude, radius
        );

        return Database.countQueryWithBinds(q, bindVars, AccessLevel.USER_MODE);
    }

    public void setMapInstance(String mapInstance) {
        this.mapInstance = mapInstance;
        mfi = Map_Finder_Instance__mdt.getInstance(mapInstance);
    }

    public void setFilterAugmentation(Map<String, Object> filterAugmentation) {
        this.filterAugmentation = filterAugmentation;
    }

    public abstract String augmentQueryFilter(Map<String, Object> bindVars);
}