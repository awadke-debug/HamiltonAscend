public with sharing class AdvanceFilterRecordPickerDto extends AdvanceFilterDto {
    @AuraEnabled public String lookupObjectApiName {get; set;}

    public AdvanceFilterRecordPickerDto(
        String key,
        String objectApiName,
        String objectsLookupApiName,
        String label,
        String field,
        String type,
        Boolean isMultiRow
    ) {
            super(key, objectApiName, objectsLookupApiName, label, field, type, isMultiRow);

            Schema.DescribeFieldResult f = Schema.getGlobalDescribe()
                .get(objectApiName)
                .getDescribe()
                .fields
                .getMap()
                .get(field)
                .getDescribe();

            for(Schema.SObjectType reference : f.getReferenceTo()) {
                this.lookupObjectApiName = reference.getDescribe().getName();
                break;
            }
    }
}