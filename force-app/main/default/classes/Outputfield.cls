public with sharing abstract class Outputfield {
    public List<Object> outputFields;

    public abstract void addValidFieldsToCollection(Map_Finder_Output_Fields__mdt fld, String lookupApiName);

    public virtual void validateOutputfields(List<Map_Finder_Output_Fields__mdt> outFlds) {
        for (Map_Finder_Output_Fields__mdt outFld : outFlds) {
            Schema.SObjectType objType = Schema.getGlobalDescribe().get(outFld.Object__c);
            if (objType == null) continue;

            if (String.isNotBlank(outFld.Lookup_Field__c)) {
                
                Map<String, Schema.SObjectField> fieldMap = objType.getDescribe().fields.getMap();
                
                if (!fieldMap.containsKey(outFld.Lookup_Field__c)) continue;
                
                String relationshipName = '';
                String parentObjName;
                
                relationshipName = fieldMap.get(outFld.Lookup_Field__c).getDescribe().getRelationshipName();
                parentObjName = String.valueOf(fieldMap.get(outFld.Lookup_Field__c).getDescribe().getReferenceTo()[0]);
                
                Schema.SObjectType parentObjType = Schema.getGlobalDescribe().get(parentObjName);

                if (parentObjType.getDescribe().fields.getMap().get(outFld.Field__c) == null) {
                    System.debug('@@invalid field::' + outFld.Field__c);
                    continue;
                } 
                
                addValidFieldsToCollection(outFld, relationshipName);
                
            } else {
                if (objType.getDescribe().fields.getMap().get(outFld.Field__c) == null) {
                    System.debug('@@invalid field::' + outFld.Field__c);
                    continue;
                } 
                addValidFieldsToCollection(outFld, null);
            }  
        }
    }
}