public with sharing class OutputfieldSelectClause extends Outputfield{
    public OutputfieldSelectClause() {

    }

    public override void addValidFieldsToCollection(Map_Finder_Output_Fields__mdt fld, String lookupApiName) {
        String fieldName = fld.Field__c;

        if (this.outputFields == null ) {
            this.outputFields = new List<String>();
        }

        if (lookupApiName == null) {
            this.outputFields.add(fieldName);
            return;
        } 

        this.outputFields.add(lookupApiName + '.' + fieldName);
    }
}