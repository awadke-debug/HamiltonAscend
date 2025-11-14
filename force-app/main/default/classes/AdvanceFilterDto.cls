public with sharing abstract class AdvanceFilterDto {
    @AuraEnabled public string key {get; set;}
    @AuraEnabled public string objectApiName {get; set;}
    @AuraEnabled public string label{get; set;}
    @AuraEnabled public string fieldApiName {get; set;}
    @AuraEnabled public string type {get; set;}
    @AuraEnabled public boolean isMultiRow {get; set;}
    @AuraEnabled public String dataType {get; set;}
    @AuraEnabled public Boolean improperlyConfigured {get; set;}
    @auraEnabled public String configErrorMessage {get; set;}
    @auraEnabled public String objectsLookupApiName {get; set;}

    public AdvanceFilterDto(String key, String objectApiName, String objectsLookupApiName, String label, String field, String type, Boolean isMultiRow) {
        this.key = key;
        this.objectApiName = objectApiName;
        this.objectsLookupApiName = objectsLookupApiName;
        this.label = label;
        this.fieldApiName = field;
        this.type = type;
        this.isMultiRow = isMultiRow;

        Schema.SObjectType objType = Schema.getGlobalDescribe().get(objectApiName);
        if (objType == null) {
            this.improperlyConfigured = true;
            this.configErrorMessage = 'Object ' + objectApiName + ' not found';
            return;
        }

        Schema.DescribeSObjectResult objDescribe = objType.getDescribe();
            
        Map<String, Schema.SObjectField> fieldMap = objDescribe.fields.getMap();

        if (fieldMap.containsKey(field)) {
            Schema.DisplayType dataType = fieldMap.get(field).getDescribe().getType();
            this.dataType = dataType.name();
        } else {
            this.improperlyConfigured = true;
            this.configErrorMessage = 'Field ' + field + ' does not exist on the ' + objectApiName;
            return;
        }

        if (!fieldMap.get(field).getDescribe().isFilterable()) {
            this.improperlyConfigured = true;
            this.configErrorMessage = 'Field ' + field + ' can\'t be used as a filter';
            return;
        }

    }
}