public with sharing class AdvanceFilterFieldDto extends AdvanceFilterDto{
    public AdvanceFilterFieldDto(
        String key,
        String objectApiName,
        String objectsLookupApiName,
        String label,
        String field,
        String type,
        Boolean isMultiRow
    ) {
            super(key, objectApiName, objectsLookupApiName, label, field, type, isMultiRow);
    }
}