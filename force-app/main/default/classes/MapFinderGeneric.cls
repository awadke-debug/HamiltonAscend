public with sharing class MapFinderGeneric extends MapFinderAbstract {

    public MapFinderGeneric() {
        super();
    }

    public List<SObject> fetchContactsForExport(
            List<String> fields,
            AdvanceFilterParamWrapper filterWrapper,
            String sortBy,
            String sortDirection
    ) {
        Map<String, Object> bindVars = new Map<String, Object>();

        String q = buildQueryWithFilter(String.format(
                'SELECT {0} FROM {1} WHERE {2} AND ', 
                new List<Object>{ String.join(fields, ', '), mfi.Object__c, mfi.Base_Filter__c }
            ), 
            filterWrapper.advanceFilterParams, bindVars, filterWrapper.latitude, filterWrapper.longitude, filterWrapper.radius
        );

        if (filterWrapper.addressRelationIds != null && !filterWrapper.addressRelationIds.isEmpty()){
            q += String.format(' AND Id {0} :addressRelationIds', new List<Object>{ filterWrapper.isExportAll ? 'NOT IN': 'IN' });
        }

        if (!String.isBlank(sortBy)) {
            q += String.format(' ORDER BY {0} {1} LIMIT {2}', new List<Object>{ sortBy, String.isBlank(sortDirection) ? 'ASC' : sortDirection, ':pageSize' });
        }

        bindVars.put('addressRelationIds', filterWrapper.addressRelationIds);
        bindVars.put('pageSize', 50000);

        return Database.queryWithBinds(q, bindVars, AccessLevel.USER_MODE);
    }

    public void addContactsToCampaign(AdvanceFilterParamWrapper filterWrapper, Id campaignId) {

        List<String> fields = new List<String>{ mfi.Campaign_Member_Id_Field__c };
        List<SObject> contacts = fetchContactsForExport(fields, filterWrapper, null, null);

        Set<Id> contactIds = new Set<Id>();
        List<CampaignMember> campaignMembersToAdd = new List<CampaignMember>();

        for (SObject contact : contacts) {
            Id contactId = (Id) contact.get(mfi.Campaign_Member_Id_Field__c);
            addToCampaignMembersCollection(campaignId, contactId, contactIds, campaignMembersToAdd);
        }

        insertMembers(campaignMembersToAdd);
    }

    @TestVisible
    private void addToCampaignMembersCollection(Id campaignId, Id contactId, Set<Id> contactIds, List<CampaignMember> campaignMembersToAdd) {
        if (contactIds.contains(contactId) || contactId.getSobjectType().getDescribe().getName() != 'Contact') {
            return;
        }

        contactIds.add(contactId);

        CampaignMember cm = new CampaignMember(CampaignId = campaignId, ContactId = contactId);
        campaignMembersToAdd.add(cm);
    }

    @TestVisible
    private void insertMembers(List<CampaignMember> campaignMembersToAdd) {
        if (campaignMembersToAdd.isEmpty()) return;

        Database.SaveResult[] campaignMemberSaveResults = Database.insert(campaignMembersToAdd, false);
        for (Database.SaveResult sr : campaignMemberSaveResults) {
            if (!sr.isSuccess()) {
                for(Database.Error err : sr.getErrors()) {
                    System.debug('@@ campaign member insert error ' + err.getMessage());
                }
            }
        }
    }

    public override String augmentQueryFilter(Map<String, Object> bindVars) {
        return '';
    }

}