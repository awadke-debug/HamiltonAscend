public with sharing class HAMDigitalTripController {
    @AuraEnabled(cacheable=true)
    public static TripWarpper getTripDetail(String tripId) {
        TripWarpper objWrapper = new TripWarpper();
        HAM_Trip_Details__c objMyTrip = new HAM_Trip_Details__c();
        List<Event> myTransports = new List<Event>();
        List<Event> myAccomodation = new List<Event>();
        List<Event> myMeetings = new List<Event>();
        if(String.isNotBlank(tripId)){
            objMyTrip = [Select Id, Name, HAM_Title__c, HAM_Start_Date_Time__c, HAM_End_Date_Time__c, HAM_Trip_Status__c FROM HAM_Trip_Details__c WHERE Id =: tripId LIMIT 1];
        }else{
            myTransports.add(new Event());
            myAccomodation.add(new Event());
            myMeetings.add(new Event());
        }
        objWrapper.myTrip = objMyTrip;
        objWrapper.transport = myTransports;
        objWrapper.accomodation = myAccomodation;
        objWrapper.meetings = myMeetings;
        
        return objWrapper;
    }

    public class TripWarpper{
        @AuraEnabled
        public HAM_Trip_Details__c myTrip;
        @AuraEnabled
        public List<Event> transport;
        @AuraEnabled
        public List<Event> accomodation;
        @AuraEnabled
        public List<Event> meetings;
       
    }
}