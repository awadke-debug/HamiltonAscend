public with sharing class MapFinderItinerary extends MapFinderAbstract implements MapFinderInterface{
    public MapFinderItinerary() {
        super();
    }

    public override String augmentQueryFilter(Map<String, Object> bindVars) {
        String q = ' AND ucinn_ascendv2__Contact__c IN (SELECT ucinn_ascendv2__Contact__c FROM ucinn_ascendv2__Involvement__c {0})';

        List<String> filters = new List<String>();
        if (this.filterAugmentation.containsKey('sportsAssociation')) {
            filters.add('HAM_Category__c = :sportsAssociation');
            bindVars.put('sportsAssociation', this.filterAugmentation.get('sportsAssociation'));
        }

        if (this.filterAugmentation.containsKey('studentOrganization')) {
            filters.add('HAM_Category__c = :studentOrganization');
            bindVars.put('studentOrganization', this.filterAugmentation.get('studentOrganization'));
        }

        String filterStr = String.join(filters, ' OR ');
        q = String.format(q, new List<String>{'WHERE ' + filterStr});

        return q;
    }
}