public with sharing class OutputfieldDataTable extends Outputfield{
    public OutputfieldDataTable() {

    }
    public override void addValidFieldsToCollection(Map_Finder_Output_Fields__mdt fld, String lookupApiName) {
        String fieldName = fld.Field__c;
        String label = fld.Label__c;

        if (this.outputFields == null ) {
            this.outputFields = new List<DataTableProperty>();
        }

        DataTableProperty dtp = new DataTableProperty();
        dtp.label = label;
        dtp.fieldName = fieldName;

        if (lookupApiName != null) {
            dtp.lookupApiName = lookupApiName;
        }

        this.outputFields.add(dtp);
    }
}