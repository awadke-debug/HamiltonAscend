public with sharing class HAMJediActivityController {
    @AuraEnabled(cacheable=true)
    public static ActivityWrapper getactivityDetails(String contactId) {
        ActivityWrapper objWrapper = new ActivityWrapper();
        objWrapper.upcomingMeeting = new List<Event>();
        objWrapper.pastMeeting = new List<Event>();
        objWrapper.rejectedMeeting = new List<Event>();
        objWrapper.dueTask = new List<Task>();
        objWrapper.upcomingMeeting = getUpcomingMeetings(contactId);
        objWrapper.pastMeeting = getPastMeetings(contactId);
        objWrapper.rejectedMeeting = getRejectedMeetings(contactId);
        objWrapper.dueTask = getOpenDueTask(contactId);
        return objWrapper;
    }

    public static List<Event> getUpcomingMeetings(String contactId){
        List<Event> eventsList = new List<Event>();
        eventsList = [SELECT Id, Subject,StartDateTime, OwnerId, Owner.Name, WhoId, who.Name, Location, Type, HAM_Meeting_Status__c,HAM_Meeting_cancellation_Reason__c,HAM_In_Person__c,HAM_Contact_Report__c,HAM_Campus_Stakeholders__c FROM Event WHERE  WhoId =: contactId AND HAM_Meeting_Status__c NOT IN ('Completed', 'Cancelled','Attempted unavailable','Attempted unresponsive')];
        return eventsList;
    }
    public static List<Event> getPastMeetings(String contactId){
        List<Event> eventsList = new List<Event>();
        eventsList = [SELECT Id, Subject,StartDateTime, OwnerId, Owner.Name, WhoId, who.Name, Location, Type, HAM_Meeting_Status__c,HAM_Meeting_cancellation_Reason__c,HAM_In_Person__c,HAM_Contact_Report__c,HAM_Contact_Report__r.name, HAM_Campus_Stakeholders__c FROM Event WHERE  WhoId =: contactId AND HAM_Meeting_Status__c = 'Completed'];
        return eventsList;
    }
    public static List<Event> getRejectedMeetings(String contactId){
        List<Event> eventsList = new List<Event>();
        eventsList = [SELECT Id, Subject,StartDateTime, OwnerId, Owner.Name, WhoId, who.Name, Location, Type, HAM_Meeting_Status__c,HAM_Meeting_cancellation_Reason__c,HAM_In_Person__c,HAM_Contact_Report__c,HAM_Campus_Stakeholders__c FROM Event WHERE  WhoId =: contactId AND HAM_Meeting_Status__c IN ('Cancelled','Attempted unavailable','Attempted unresponsive')];
        return eventsList;
    }
    public static List<Task> getOpenDueTask(String contactId){
        List<Task> taskList = new List<Task>();
        taskList = [SELECT Id,ActivityDate,Subject,Status,WhoId, Who.name, WhatId, What.Name 
         FROM Task WHERE  (WhoId =: contactId OR HAM_Contact_Report__r.ucinn_ascendv2__Contact__c =: contactId ) AND Status = 'Open' ORDER BY ActivityDate ASC];
        return taskList;
    }


    public class ActivityWrapper{
        @AuraEnabled
        public List<Event> upcomingMeeting;
        @AuraEnabled
        public List<Event> pastMeeting;
        @AuraEnabled
        public List<Event> rejectedMeeting;
        @AuraEnabled
        public List<Task> dueTask;
    }
}