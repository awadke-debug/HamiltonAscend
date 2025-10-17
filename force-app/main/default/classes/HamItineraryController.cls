public with sharing class HamItineraryController {

    public Map<String, List<EventDetail>> outputMap= new Map<String, List<EventDetail>>();
    List<ContactReport> contactReports = new List<ContactReport>();
    String tripDetailId;
    String tripName;

    public HamItineraryController() {
        List<EventDetail> eventDetails = new List<EventDetail>();
        Map<String, String> params = ApexPages.currentPage().getParameters();
        this.tripDetailId = params.get('tripDetailId');

        try {
            HAM_Trip_Details__c tripDetail = [SELECT Id, 
                                                    HAM_Title__c, 
                                                    HAM_Start_Date_Time__c , 
                                                    HAM_End_Date_Time__c 
                                                FROM HAM_Trip_Details__c 
                                                WHERE Id = :tripDetailId 
                                                    LIMIT 1];
                                        
            this.tripName = tripDetail.HAM_Title__c;
        } catch (Exception e) {
            System.debug('ERROR:::' + e.getMessage());
        }

        Map<Id, String> meetingMap = new Map<Id, String>();
        for (Event evt : [
                SELECT Id, 
                    Subject, 
                    Description, 
                    StartDateTime, 
                    HAM_Start_Date_Time__c, 
                    HAM_Source_Airport__c, 
                    HAM_Destination_Airport__c,
                    HAM_Mode__c,
                    HAM_Stay_Name__c,
                    HAM_Address__c,
                    Who.Name,
                    WhoId,
                    RecordType.DeveloperName 
                FROM Event 
                WHERE WhatId = :tripDetailId 
                AND RecordType.DeveloperName IN ('HAM_Meeting', 'HAM_Transportation', 'HAM_Accommodation') 
                    ORDER BY StartDateTime ]) {
            EventDetail edt = buildEventDetail(evt, meetingMap);
            eventDetails.add(edt);
            
        }

        buildOutputMap(eventDetails);

        Map<Id,ucinn_ascendv2__Contact_Report__c> reportMap = new Map<Id,ucinn_ascendv2__Contact_Report__c>();
        for (ucinn_ascendv2__Contact_Report__c contactReport : [
                SELECT ucinn_ascendv2__Contact__c, 
                    ucinn_ascendv2__Contact__r.ucinn_ascendv2__Expanded_Name_Formula__c, 
                    ucinn_ascendv2__Description__c, ucinn_ascendv2__Contact_Report_Body__c 
                FROM ucinn_ascendv2__Contact_Report__c 
                WHERE Trip_Details__c = :tripDetailId]) {
            reportMap.put(contactReport.ucinn_ascendv2__Contact__c, contactReport);
        }

        for (String constituentId : meetingMap.keySet()) {
            if (reportMap.containsKey(constituentId)) {
                this.contactReports.add(new ContactReport(reportMap.get(constituentId).ucinn_ascendv2__Contact__r.ucinn_ascendv2__Expanded_Name_Formula__c, reportMap.get(constituentId).ucinn_ascendv2__Contact_Report_Body__c));
            } else {
                this.contactReports.add(new ContactReport(meetingMap.get(constituentId), '<p>--No report--</p>'));
            }
        }

    }

    private void buildOutputMap(List<EventDetail> eventDetails) {
        for (EventDetail ed : eventDetails) {
            if (this.outputMap.containsKey(ed.eventDate)) {
                this.outputMap.get(ed.eventDate).add(ed);
            } else {
                this.outputMap.put(ed.eventDate, new EventDetail[]{ed});
            }
        }
    }

    private EventDetail buildEventDetail(Event evt, Map<Id, String> meetingMap) {
        EventDetail edt = new EventDetail(evt.Subject, evt.StartDateTime.format('MMMM d'), evt.StartDateTime.format('h:mm a'), evt.Description);
        populateEventDetailDescription(edt, evt, meetingMap);
        return edt;
    }

    private void populateEventDetailDescription(EventDetail edt, Event evt, Map<Id, String> meetingMap) {
        if (evt.RecordType.DeveloperName == 'HAM_Meeting') {
            edt.description = String.format('<td">{0}</td><td style="padding-left: 30px;">{1} <strong>{2}</strong></td>', 
                new List<Object>{
                    edt.eventTime, 
                    'Meeting with', 
                    evt.Who.Name
                });
            meetingMap.put(evt.WhoId, evt.Who.Name);

        } else if (evt.RecordType.DeveloperName == 'HAM_Transportation') {
            edt.description = String.format('<td>{0}</td>' + '<td style="padding-left: 30px;">' 
                    + (String.isBlank(evt.HAM_Source_Airport__c) ? '{1}{2} to {3}' :'{1} {2} to {3}')+'</td>', 
                new List<Object>{
                    edt.eventTime, 
                    String.isBlank(evt.HAM_Source_Airport__c) ? '' : evt.HAM_Source_Airport__c, 
                    evt.HAM_Mode__c, 
                    evt.HAM_Destination_Airport__c
                });

        } else if (evt.RecordType.DeveloperName == 'HAM_Accommodation') {
            edt.description = String.format('<td colspan="2" style="padding-top: 20px;">Overnight {0}</td>', new List<Object>{evt.HAM_Stay_Name__c});
        }
    }

    @AuraEnabled(cacheable=true)
    public static string getBaseUrl(){
        return URL.getOrgDomainUrl().toExternalForm();
    }

    @AuraEnabled(cacheable=true)
    public static List<Event> getStays(String tripDetailId){
        if (String.isBlank(tripDetailId)) {
            return new List<Event>();
        }

        List<Event> stays = [SELECT Id, Subject, 
                    Description, 
                    StartDateTime, 
                    HAM_Start_Date_Time__c, 
                    HAM_Source_Airport__c, 
                    HAM_Destination_Airport__c,
                    HAM_Mode__c,
                    HAM_Stay_Name__c,
                    HAM_Address__c,
                    Who.Name, 
                    RecordType.DeveloperName  
                FROM Event 
                WHERE WhatId = :tripDetailId
                AND RecordType.DeveloperName = 'HAM_Accommodation'];
        
        return stays;
    }

    @AuraEnabled(cacheable=true)
    public static List<Event> getEvents(String tripDetailId){
        if (String.isBlank(tripDetailId)) {
            return new List<Event>();
        }

        List<Event> events = [SELECT 
                    Id, 
                    Subject, 
                    Description, 
                    WhatId,
                    StartDateTime, 
                    EndDateTime,
                    Who.Name, 
                    RecordType.DeveloperName,
                    HAM_Meeting_Title__c,
                    HAM_Meeting_Status__c,
                    HAM_Start_Date_Time__c, 
                    HAM_Source_Airport__c, 
                    HAM_Destination_Airport__c,
                    HAM_Flight_Train_Number__c,
                    HAM_Mode__c,
                    HAM_Stay_Name__c,
                    HAM_Address__c  
                FROM Event 
                WHERE (WhatId = :tripDetailId OR HAM_Trip_Details__c = :tripDetailId)
                AND RecordType.DeveloperName IN ('HAM_Accommodation' , 'HAM_Meeting', 'HAM_Transportation')
                    ORDER BY StartDateTime];
        
        return events;
    }

    @AuraEnabled
    public static Event saveEvent(EventDetail eventDetail){
        Event event = new Event();
        event.Id = eventDetail.id;
        event.StartDateTime = eventDetail.startDateTime;
        event.EndDateTime = eventDetail.endDateTime;
        event.WhatId = eventDetail.tripDetailId;
        event.HAM_Trip_Details__c = eventDetail.tripDetailId;
        event.RecordTypeId = Schema.SObjectType.Event.getRecordTypeInfosByDeveloperName().get(eventDetail.type).getRecordTypeId();

        if (eventDetail.type == 'HAM_Accommodation') {
            event.HAM_Stay_Name__c = eventDetail.stayDetailsName;
            event.HAM_Address__c = eventDetail.address;
        }

        if (eventDetail.type == 'HAM_Meeting') {
            event.HAM_Meeting_Title__c = eventDetail.meetingTitle;
            event.Subject = 'Meeting';
            event.HAM_Meeting_Status__c = eventDetail.meetingStatus;
            event.WhoId = eventDetail.contactId;
            event.HAM_Address__c = eventDetail.address;
        }

        if (eventDetail.type == 'HAM_Transportation') {
            event.HAM_Mode__c = eventDetail.mode;
            event.HAM_Flight_Train_Number__c = eventDetail.flightOrTrainNumber;
            event.HAM_Source_Airport__c = eventDetail.sourceAirport;
            event.HAM_Destination_Airport__c = eventDetail.destinationAirport;
        }

        System.debug(JSON.serializePretty(eventDetail));

        upsert event;

        return event;
    }

    @AuraEnabled
    public static void deleteEvent(String eventId){
        try {
            Database.delete(Id.valueOf(eventId));
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static string sendDigitalTrip(String tripDetailId, String subject, String body){
        String result = '';

        try {
            HAM_Trip_Details__c tripDetail = [SELECT Id, Name, HAM_Title__c FROM HAM_Trip_Details__c WHERE Id = :tripDetailId LIMIT 1];
        
            String fileName = 'Itinerary {0} {1}-{2}-{3}.pdf';
            fileName = String.format(fileName, new List<Object>{tripDetail.HAM_Title__c, rPadDateElem(Date.today().month()), rPadDateElem(Date.today().day()), Date.today().year()});

            PageReference pageRef = Page.hamItineraryPdf;
            pageRef.getParameters().put('tripDetailId', tripDetailId);
            pageRef.setRedirect(true);

            EmailTemplate et = [SELECT Id, Subject, Body FROM EmailTemplate WHERE DeveloperName = 'Digital_Trip_Itinerary'];
            HAM_Itinerary_Email_Setting__c emailSetting = HAM_Itinerary_Email_Setting__c.getInstance();

            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setTemplateId(et.Id);
            // mail.setTreatTargetObjectAsRecipient(false);
            // mail.setTargetObjectId(tripDetailId);
            mail.setSubject(String.isBlank(subject.trim()) ? et.Subject : subject);
            mail.setSaveAsActivity(false);
            // mail.setToAddresses(new List<String>{emailSetting.Recipient__c});
            mail.setToAddresses(filterEmails(emailSetting.Recipient__c));
            mail.setFileAttachments(new Messaging.EmailFileAttachment[] { 
                HamEmailUtil.preparePdfEmailAttachment(
                    fileName, Test.isRunningTest() ? Blob.valueOf('test') : pageRef.getContent()) 
            });

            if (!String.isBlank(body.trim())) {
                mail.setPlainTextBody(body);
            }

            if (mail.getToAddresses() != null && !mail.toaddresses.isEmpty()) {
                List<OrgWideEmailAddress> owa = [
                    SELECT Id 
                    FROM OrgWideEmailAddress 
                    WHERE Address = 'hamily@hamilton.edu'];
                if (owa.size() > 0) {
                    mail.setOrgWideEmailAddressId(owa[0].Id);
                }
                if (!Test.isRunningTest()) {
                    Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
                    result = 'sent';
                }
            } else {
                result = 'No emails to send to.';
            }
        } catch (QueryException qEx) {
            System.debug('ERROR:::' + qEx.getMessage());
            result = 'No trip detail found.';
        } catch (Exception ex) {
            System.debug('ERROR:::' + ex.getMessage());
            result = 'Error sending email.';
        }

        return result;
    }

    @AuraEnabled(cacheable=true)
    public static List<String > searchAddress(String searchString){
        List<String> results = new List<String>();
        GeocodingCallout call = new GeocodingCallout();
        GeocodeResponse geoResp = call.getCoordinates(searchString);
        if (geoResp != null) {
            for (GeocodeResponse.results result : geoResp.results) {
                results.add(result.formatted_address);
            }
        }
        return results;
    }

    private static List<String> filterEmails(String commaDelimitedEmails) {
        List<String> emails = HamEmailUtil.trimCommaDelimitedEmails(commaDelimitedEmails);
        HamEmailUtil.removeEmailConstituents(emails);
        HamEmailUtil.filterEmails(emails);

        return emails;
    }

    private static String rPadDateElem(Integer ele) {
        return String.valueOf(ele).length() == 1 ? String.valueOf(ele).leftPad(2, '0') : String.valueOf(ele);
    }

    public String getTripName() {
        return this.tripName;
    }

    public Map<String, List<EventDetail>> getOutputMap() {
        return this.outputMap;
    }

    public List<ContactReport> getContactReports() {
        return this.contactReports;
    }

    public class EventDetail {
        @AuraEnabled public String id {get; set;}
        public String name {get; set;}
        public String eventDate {get; set;}
        public String eventTime {get; set;}
        public String description {get; set;}
        @AuraEnabled public String type {get; set;}
        @AuraEnabled public String stayDetailsName {get; set;}
        @AuraEnabled public String address {get; set;}
        @AuraEnabled public String sourceAirport {get; set;}
        @AuraEnabled public String destinationAirport {get; set;}
        @AuraEnabled public String mode {get; set;}
        @AuraEnabled public Datetime startDateTime {get; set;}
        @AuraEnabled public Datetime endDateTime {get; set;}
        @AuraEnabled public String flightOrTrainNumber {get; set;}
        @AuraEnabled public String tripDetailId {get; set;}
        @AuraEnabled public String meetingTitle {get; set;}
        @AuraEnabled public String meetingStatus {get; set;}
        @AuraEnabled public String contactId {get; set;}

        public EventDetail() {}

        public EventDetail(String name, String eventDate, String eventTime, String description) {
            this.name = name;
            this.eventDate = eventDate;
            this.eventTime = eventTime;
            this.description = description;
        }

        public EventDetail(String name, String eventDate, String eventTime, String description, String type) {
            this.name = name;
            this.eventDate = eventDate;
            this.eventTime = eventTime;
            this.description = description;
            this.type = type;
        }
    }

    public class ContactReport {
        public String name {get; set;}
        public String result {get; set;}

        public ContactReport(String name, String result) {
            this.name = name;
            this.result = result;
        }
    }
}