public with sharing class HamJEDIInvolvementController {

    /**
     * Get Involvement records for a specific contact and record type
     * @param contactId The ID of the Contact
     * @param recordTypeId The Record Type ID to filter by
     * @return List of Involvement records matching criteria
     */
    @AuraEnabled(cacheable=true)
    public static List<ucinn_ascendv2__Involvement__c> getInvolvements(String contactId, String recordTypeId) {
        List<ucinn_ascendv2__Involvement__c> involvements = new List<ucinn_ascendv2__Involvement__c>();

        involvements = [
            SELECT Id,
                Name,
                ucinn_ascendv2__Involvement_Code_Description_Formula__c,
                HAM_Category__c,
                ucinn_ascendv2__Start_Date__c,
                ucinn_ascendv2__End_Date__c,
                ucinn_ascendv2__Role__c,
                ucinn_ascendv2__Contact__c,
                ucinn_ascendv2__Status__c,
                RecordTypeId
            FROM ucinn_ascendv2__Involvement__c
            WHERE ucinn_ascendv2__Contact__c = :contactId
                AND RecordTypeId = :recordTypeId
            ORDER BY ucinn_ascendv2__Status__c ASC,
                     ucinn_ascendv2__Start_Date__c ASC
        ];

        return involvements;
    }
}