public with sharing class MapFinderContext {
    public static final Map<String, MapFinderInterface> MAP_FINDER_MAP;

    static {
        MAP_FINDER_MAP = new Map<String, MapFinderInterface>();
        for (Map_Finder_Instance__mdt  mapFinderInstance : [SELECT Id, DeveloperName, Finder_Class__c FROM Map_Finder_Instance__mdt]) {
            if (String.isBlank(mapFinderInstance.Finder_Class__c)) {
                continue;
            }

            MAP_FINDER_MAP.put(mapFinderInstance.DeveloperName, 
                (MapFinderInterface) Type.forName(mapFinderInstance.Finder_Class__c).newInstance()
            );
        }
    }

    private MapFinderInterface mapFinder;

    public MapFinderContext(String mapFinderName) {
        this.mapFinder = MAP_FINDER_MAP.get(mapFinderName);
        this.mapFinder.setMapInstance(mapFinderName);
    }

    public List<SObject> fetchContactsByFilters(
            AdvanceFilterParamWrapper filterWrapper,
            Integer offset,
            Integer pageSize,
            String sortBy,
            String sortDirection
    ) { 
        setFilterAugmentation(filterWrapper.filterAugmentation);
        return this.mapFinder.fetchContactsByFilters(
            filterWrapper.advanceFilterParams, 
            filterWrapper.latitude, 
            filterWrapper.longitude, 
            filterWrapper.radius,
            offset,
            pageSize,
            sortBy,
            sortDirection
        );
    }

    public Integer countContactsByFilters(AdvanceFilterParamWrapper filterWrapper) {
        setFilterAugmentation(filterWrapper.filterAugmentation);
        return this.mapFinder.countContactsByFilters(
            filterWrapper.advanceFilterParams, 
            filterWrapper.latitude, 
            filterWrapper.longitude, 
            filterWrapper.radius
        );
    }

    private void setFilterAugmentation(String filterAugmentation) {
        if (String.isNotBlank(filterAugmentation)) {
            this.mapFinder.setFilterAugmentation((Map<String, String>) JSON.deserializeStrict(filterAugmentation, Map<String, String>.class));
        }
    }
}