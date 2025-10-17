/**
 * Auto Generated and Deployed by the Declarative Lookup Rollup Summaries Tool package (dlrs)
 **/
trigger dlrs_ucinn_ascendv2_Hard_and_Sa0tTrigger on ucinn_ascendv2__Hard_and_Soft_Credit__c
    (before delete, before insert, before update, after delete, after insert, after undelete, after update)
{
    dlrs.RollupService.triggerHandler(ucinn_ascendv2__Hard_and_Soft_Credit__c.SObjectType);
}