public with sharing class AdvanceFilterParamWrapper {
    @AuraEnabled
        public List<AdvanceFilterParam> advanceFilterParams { get; set; }
        @AuraEnabled
        public Decimal latitude { get; set; }
        @AuraEnabled
        public Decimal longitude { get; set; }
        @AuraEnabled
        public Integer radius { get; set; }
        @AuraEnabled
        public List<String> addressRelationIds { get; set; }
        @AuraEnabled
        public Boolean isExportAll { get; set; }
}