public interface MapFinderInterface {
    List<SObject> fetchContactsByFilters(
            List<AdvanceFilterParam> advanceFilterParams, 
            Decimal latitude, 
            Decimal longitude, 
            Integer radius,
            Integer offset,
            Integer pageSize,
            String sortBy,
            String sortDirection
    );
    Integer countContactsByFilters(List<AdvanceFilterParam> advanceFilterParams, 
            Decimal latitude, 
            Decimal longitude, 
            Integer radius
    );

    void setFilterAugmentation(Map<String, Object> filterAugmentation);
    void setMapInstance(String mapInstance);

}