public class CampaignPriorityAutopopulation implements Schedulable {
    public void execute(SchedulableContext SC){
        List<String> designationIds = new List<String>();
        Map<String, Date> designationDetailDateMap = new Map<String, Date>();
        Map<String, ucinn_ascendv2__Designation_Detail__c> designationDetailMap = new Map<String, ucinn_ascendv2__Designation_Detail__c>();
        Map<String, List<HAM_Designation_Priority__c>> designationPriorityMap = new Map<String, List<HAM_Designation_Priority__c>>();
        Map<String, Id> designationCampaignPriorityMap = new Map<String, Id>();
        Map<ucinn_ascendv2__Designation_Detail__c, Id> ddCpMap = new Map<ucinn_ascendv2__Designation_Detail__c, Id>();
        Date pledgeGiftDate;
        List<HAM_Designation_Priority__c> dpList = new List<HAM_Designation_Priority__c>();
        Set<Id> finalDpIds = new Set<Id>();
        List<HAM_Designation_Priority__c> finalDpList = new List<HAM_Designation_Priority__c>();
        Date priorityStartDate;
        Date priorityEndDate;
        
       	Datetime yesterday = Datetime.now().addDays(-1);
        Datetime startDatetime = Datetime.newInstanceGmt(yesterday.year(), yesterday.month(), yesterday.day(), 0, 0, 0);
        Datetime endDatetime = Datetime.newInstanceGmt(yesterday.year(), yesterday.month(), yesterday.day(), 23, 59, 59);
        
        // Query Designation Details created yesterday
        List<ucinn_ascendv2__Designation_Detail__c> designationDetails = [SELECT Id, Name, ucinn_ascendv2__Pledge_Date_Formula__c, ucinn_ascendv2__Designation__c
                                                          FROM ucinn_ascendv2__Designation_Detail__c
                                                          WHERE CreatedDate >= :startDatetime
                                                          AND CreatedDate <= :endDatetime];
        
        // Create Designation Ids set and Map with Designation Ids and Pledge Gift Date
        
        Integer count = 1;
        for(ucinn_ascendv2__Designation_Detail__c dd: designationDetails){
            String ddId = dd.ucinn_ascendv2__Designation__c;
            if(designationDetailDateMap.containsKey(dd.ucinn_ascendv2__Designation__c) && designationDetailMap.containsKey(dd.ucinn_ascendv2__Designation__c)){
                ddId = ddId + '_' + count;
                designationDetailDateMap.put(ddId, dd.ucinn_ascendv2__Pledge_Date_Formula__c);
                designationDetailMap.put(ddId, dd);
                count++;
            }
            else{
                designationDetailDateMap.put(ddId, dd.ucinn_ascendv2__Pledge_Date_Formula__c);
                designationDetailMap.put(ddId, dd);
            }
            designationIds.add(ddId);
        }
        Integer size = designationDetailMap.size();
        System.debug('designationDetailMap SIZE:::'+size);
        System.debug('DESIGNATION IDS:::'+designationIds);
        System.debug('DESIGNATION DETAIL DATE MAP:::'+designationDetailDateMap);
        System.debug('DESIGNATION DETAIL MAP:::'+designationDetailMap);
        // Query Designation Priority
        List<HAM_Designation_Priority__c> designationPriorities = [SELECT Id, Name, HAM_Priority_End_Date__c,HAM_Priority_Start_Date__c, HAM_Designation__c
                                                          FROM HAM_Designation_Priority__c
                                                          WHERE HAM_Designation__c In :designationIds];
        System.debug('DESIGNATION PRIORITY:::'+designationPriorities);
        
        // Query Designation Priority Map with Designation Id and List of Priority records
        for(HAM_Designation_Priority__c dp :designationPriorities){
            if(!designationPriorityMap.containsKey(dp.HAM_Designation__c)){
                designationPriorityMap.put(dp.HAM_Designation__c, new List<HAM_Designation_Priority__c>{dp});
            }
            else{
                designationPriorityMap.get(dp.HAM_Designation__c).add(dp);
            }
        }
        for(String d:designationIds){
            String leftPart,rightPart;
            if(d.contains('_')){
                List<String> parts = d.split('_');
    			leftPart = parts[0];
                if(designationPriorityMap.containsKey(leftPart)){
                    designationPriorityMap.put(d, designationPriorityMap.get(leftPart));
                }
            }
        }
        size = designationPriorityMap.size();
        System.debug('DESIGNATION PRIORITY MAP:::'+designationPriorityMap);
        System.debug('SIZE:::'+size);
        
        // Logic for checking if pledge gift date lies between priority start and end date
        for(String d:designationIds){
            
            if(designationDetailDateMap.containsKey(d)){
                pledgeGiftDate = designationDetailDateMap.get(d);
            }
            if(designationPriorityMap.containsKey(d)){
               dpList = designationPriorityMap.get(d);
                System.debug('D:::'+d);
                System.debug('DPLIST:::'+dpList);
            }
            for(HAM_Designation_Priority__c dp:dpList){
                priorityStartDate = dp.HAM_Priority_Start_Date__c;
                System.debug(priorityStartDate);
                priorityEndDate = dp.HAM_Priority_End_Date__c;
                System.debug(priorityEndDate);
                if (pledgeGiftDate >= priorityStartDate && pledgeGiftDate <= priorityEndDate){
                    System.debug('Inside if block');
                    finalDpIds.add(dp.Id);
				}
            }
        }
        System.debug('FINAL DP IDS:::'+finalDpIds);
        finalDpList = [Select Id, HAM_Designation__c, HAM_Campaign_Priority__c from HAM_Designation_Priority__c where Id In: finalDpIds];
        System.debug('FINAL DP LIST:::'+finalDpList);
        for(HAM_Designation_Priority__c dp: finalDpList){
            designationCampaignPriorityMap.put(dp.HAM_Designation__c, dp.HAM_Campaign_Priority__c);
        }
        size = designationCampaignPriorityMap.size();
        System.debug('designationCampaignPriorityMap SIZE before:::'+size);
        for(String d:designationIds){
            String leftPart,rightPart;
            if(d.contains('_')){
                List<String> parts = d.split('_');
    			leftPart = parts[0];
                if(designationCampaignPriorityMap.containsKey(leftPart)){
                    designationCampaignPriorityMap.put(d, designationCampaignPriorityMap.get(leftPart));
                }
            }
        }
        size = designationCampaignPriorityMap.size();
        System.debug('designationCampaignPriorityMap SIZE after:::'+size);
        System.debug('designationCampaignPriorityMap:::'+designationCampaignPriorityMap);
        
        
        //Create new map on the basis of same designation id
        for (String desgnId : designationDetailMap.keySet()) {
    		if (designationCampaignPriorityMap.containsKey(desgnId)) {
        		ddCpMap.put(designationDetailMap.get(desgnId), designationCampaignPriorityMap.get(desgnId));
    		}
		}
        size = ddCpMap.size();
        System.debug('ddCpMap SIZE:::'+size);
        System.debug('DDCP MAP:::'+ddCpMap);
        
        //Update designation detail with campaign priority id
        for(ucinn_ascendv2__Designation_Detail__c dd:ddCpMap.keySet()){
            Id cpId = ddCpMap.get(dd);
            dd.HAM_Campaign_Priority__c = cpId;
        }
        System.debug('DDCP MAP:::'+ddCpMap);
        update new List<ucinn_ascendv2__Designation_Detail__c>(ddCpMap.keySet());
    }
}