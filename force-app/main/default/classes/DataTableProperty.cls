public virtual with sharing class DataTableProperty implements Comparable {
    @AuraEnabled
    public String label { get; set; }
    @AuraEnabled
    public String fieldName { get; set;}
    @AuraEnabled
    public String lookupApiName { get; set;}
    @AuraEnabled
    public String fullFieldName 
    { 
        get {
            return String.isBlank(this.lookupApiName) ? this.fieldName : this.lookupApiName + '.' + this.fieldName;
        } 
        set;
    }

    public Integer compareTo(Object compareTo) {
        DataTableProperty other = (DataTableProperty)compareTo;
        return this.fullFieldName.compareTo(other.fullFieldName);

    }
}