public with sharing class AdvanceFilterPicklistDto extends AdvanceFilterDto {
        @AuraEnabled public string recordTypeId {get; set;}
        @auraEnabled public boolean isOptionsFromObject {get; set;}
        @AuraEnabled public List<AdvanceFilterPicklistOptionsDto> options {get; set;}

        public AdvanceFilterPicklistDto(String key, String objectApiName, String objectsLookupApiName, String label, String field, String type, Boolean isMultiRow, Boolean isOptionsFromObject, String recordTypeId, List<Map_Finder_Adv_Filter_Options__mdt> optionsMdts) {

            super(key, objectApiName, objectsLookupApiName, label, field, type, isMultiRow);
            this.isOptionsFromObject = isOptionsFromObject;
            this.recordTypeId = recordTypeId;

            this.options = new List<AdvanceFilterPicklistOptionsDto>();
            if (isOptionsFromObject) {

                if (this.dataType != 'PICKLIST' && this.dataType != 'MULTIPICKLIST') {
                    this.configErrorMessage = fieldApiName + ' is not a Picklist or Multipicklist field on ' + objectApiName + '. Picklist options cannot be retrieved.';
                    this.improperlyConfigured = true;
                } else {

                    List<Schema.PicklistEntry> pickVals = getPicklistValues();
                    for (Schema.PicklistEntry pickVal : pickVals) {
                        if (pickVal.isActive()) {
                            options.add(new AdvanceFilterPicklistOptionsDto(pickVal.getLabel(), pickVal.getValue(), false, 0));
                        }
                    }
                }

            } else {

                for (Map_Finder_Adv_Filter_Options__mdt optionsMdt : optionsMdts) {
                    if (optionsMdt.Is_Range__c && !Pattern.matches('(\\d*-\\d+|\\d+-\\d*)', optionsMdt.Value__c) && this.configErrorMessage == null) {
                        this.configErrorMessage = '"' + optionsMdt.Value__c + '" is not a valid format for a Map Finder Range Field.';
                        this.improperlyConfigured = true;
                    }
                    options.add(new AdvanceFilterPicklistOptionsDto(optionsMdt.Label__c, optionsMdt.Value__c, optionsMdt.Is_Range__c, optionsMdt.Order__c == null ? 0 : Integer.valueOf(optionsMdt.Order__c)));
                }
                options.sort();
            }

        }

        public List<Schema.PicklistEntry> getPicklistValues() {
            Schema.SObjectType objType = Schema.getGlobalDescribe().get(objectApiName);
            Schema.DescribeSObjectResult objDescribe = objType.getDescribe();
            
            Map<String, Schema.SObjectField> fieldMap = objDescribe.fields.getMap();

            return fieldMap.get(fieldApiName).getDescribe().getPicklistValues();
        }
}