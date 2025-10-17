trigger ConsecutiveGivingTrigger on ucinn_ascendv2__Session__c (after update) 
{
    // Collect updated session IDs where ucinn_ascendv2__Session_Totals_Approved__c has changed
    List<Id> updatedSessionIds = new List<Id>();
    for (ucinn_ascendv2__Session__c newSession : Trigger.new) 
    {
        ucinn_ascendv2__Session__c oldSession = Trigger.oldMap.get(newSession.Id);
        if (newSession.ucinn_ascendv2__Session_Totals_Approved__c != oldSession.ucinn_ascendv2__Session_Totals_Approved__c) 
        {
            updatedSessionIds.add(newSession.Id);
        }
    }

    // Call the ConsecutiveGivingCalculator class to perform the calculations
    if (!updatedSessionIds.isEmpty()) 
    {
        ConsecutiveGivingCalculatorOrganization.calculateConsecutiveGiving(updatedSessionIds);
    }
}