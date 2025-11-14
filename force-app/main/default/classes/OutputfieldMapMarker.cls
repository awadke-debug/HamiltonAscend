public with sharing class OutputfieldMapMarker extends Outputfield {
    public OutputfieldMapMarker() {

    }

    public override void addValidFieldsToCollection(Map_Finder_Output_Fields__mdt fld, String lookupApiName) {
        String fieldName = fld.Field__c;
        String label = fld.Label__c;

        if (this.outputFields == null ) {
            this.outputFields = new List<MapMarkerProperty>();
        }

        MapMarkerProperty dtp = new MapMarkerProperty();
        dtp.label = label;
        dtp.fieldName = fieldName;

        if (lookupApiName != null) {
            dtp.lookupApiName = lookupApiName;
        }

        if (fld.Is_Marker_Property__c) {
            dtp.locationProperty = fld.Address_Property__c;
        }

        this.outputFields.add(dtp);
    }
}