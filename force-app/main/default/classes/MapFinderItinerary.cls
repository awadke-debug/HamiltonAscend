public with sharing class MapFinderItinerary extends MapFinderAbstract {
    public MapFinderItinerary() {
        super();
    }

    public override String augmentQueryFilter(Map<String, Object> bindVars) {
        String q = 'ucinn_ascendv2__Contact__c IN (SELECT ucinn_ascendv2__Contact__c FROM ucinn_ascendv2__Involvement__c {0})';

        if (this.filterAugmentation.values().size() > 0) {
            List<String> involvementFilters = new List<String>();
            for (Integer idx = 0; idx < this.filterAugmentation.values().size(); idx++) {
                involvementFilters.add('ucinn_ascendv2__Involvement_Code__c = :filterAug' + idx);
                bindVars.put('filterAug' + idx, this.filterAugmentation.values()[idx]);
            }

            q = String.format(q, new List<String>{'WHERE ' + String.join(involvementFilters, ' AND ')});
        } else {
            return '';
        }

        return q;
    }
}