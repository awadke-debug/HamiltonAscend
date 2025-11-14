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

//     List<SObject> fetchContactsForExport(
//             String mapInstance,
//             List<String> fields,
//             AdvanceFilterParamWrapper filterWrapper,
//             String sortBy,
//             String sortDirection
//     );

    void setFilterAugmentation(Map<String, Object> filterAugmentation);
    void setMapInstance(String mapInstance);

    String augmentQueryFilter(Map<String, Object> bindVars);

}