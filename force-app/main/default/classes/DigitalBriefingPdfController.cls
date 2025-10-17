public with sharing class DigitalBriefingPdfController {
    private String contactId;
    private List<ucinn_ascendv2__Briefing__c> briefings = new ucinn_ascendv2__Briefing__c[5];
    private String giftOfficer;
    private String meetingSchedule;
    private Contact constituent;
    private String profilePicUrl;
    private String phoneNumber;
    private ucinn_ascendv2__Briefing__c recentGivingBriefing;
    private List<EndowedFund> endowedFunds = new List<EndowedFund>();

    List<String> briefingTypesOrder = new List<String>{
        'Context for Today\'s Meeting',
        'Background',
        'Connections to Other Alumni',
        'Context for Capacity',
        'Alumni Service'
    };

    public DigitalBriefingPdfController() {
        Map<String, String> params = ApexPages.currentPage().getParameters();
        this.contactId = params.get('contactId');

        this.constituent = [
            SELECT Id, PhotoUrl, Name, ucinn_ascendv2__Preferred_Class_Year__c, Email, MobilePhone, ucinn_ascendv2__Wealth_Rating__c, ucinn_ascendv2__Lifetime_Fundraising__c, HAM_Lifetime_Paid__c, 
                HAM_Lifetime_Bequest_Intention__c, ucinn_ascendv2__PRM__c, ucinn_ascendv2__Amount_of_Most_Recent_Gift__c, HAM_Lifetime_Committed__c, iWave_PROscores__iWave_Est_Capacity__c,
                HAM_PreferredEmail__c, HAM_Phone_and_Type__c,ucinn_ascendv2__Expanded_Name_Formula__c, HAM_Institutional_Suffix__c, AccountId, HAM_Profile_Picture_URL__c 
            FROM Contact WHERE Id = :contactId];
        
        if (this.constituent?.AccountId != null) {
            for (ucinn_ascendv2__Briefing__c brief : [SELECT Id, HAM_Briefing_Details__c, HAM_Briefing_Type__c FROM ucinn_ascendv2__Briefing__c WHERE ucinn_ascendv2__Account__c = :this.constituent.AccountId]) {
                if (String.isBlank(brief.HAM_Briefing_Details__c)) {
                    continue;
                }
                if (brief.HAM_Briefing_Type__c == 'Recent Giving') {
                    this.recentGivingBriefing = brief;
                } else {
                    brief.HAM_Briefing_Details__c = getBriefingHeader(brief.HAM_Briefing_Type__c) + sanitizeLineBreaks(brief.HAM_Briefing_Details__c);
                    this.briefings.add(briefingTypesOrder.indexOf(brief.HAM_Briefing_Type__c), brief);
                }
            }
        }
        this.loadMeetingInfo();
        this.loadEndowedFunds();
    }

    @TestVisible
    private static String sanitizeLineBreaks(String briefDetail) {
        if (String.isBlank(briefDetail)) {
            return '';
        }

        String htmlstr = briefDetail;
        String lineBreakUnit = '<p><br></p>';
        Integer maxLineBreakRepitition = 0;

        do {
            maxLineBreakRepitition++;
        } while (htmlstr.contains(lineBreakUnit.repeat(maxLineBreakRepitition)));

        System.debug('# of repetition ' + (maxLineBreakRepitition-1));

        for (integer i = maxLineBreakRepitition-1; i > 0; i-- ) {
            if (i-1 == 0) {
                htmlstr = htmlstr.replaceAll(lineBreakUnit.repeat(i), '');
            } else {
                htmlstr = htmlstr.replaceAll(lineBreakUnit.repeat(i), '<br>'.repeat(i-1));
            }
        }

        return htmlstr;
    }

    @TestVisible
    private static String getBriefingHeader(String briefingType) {
        switch on briefingType {
            when 'Alumni Service' {
                return '<p><strong>Alumni Service:</strong></p>';
            }
            when 'Connections to Other Alumni' {
                return '<p><strong>Connections to Other Alumni:</strong></p>';
            }
            when 'Context for Capacity' {
                return '<p><strong>Context for Capacity:</strong></p>';
            }
            when else {
                return '';
            }
        }
    }

    private void loadMeetingInfo() {
        String whoId = this.contactId;

        List<Event> meetings = [
            SELECT Owner.Name, Location, StartDateTime 
            FROM Event 
            WHERE WhoId = :whoId
                AND HAM_Meeting_Status__c IN ('Scheduled', 'Rescheduled', 'Planned')
                AND StartDateTime > YESTERDAY ORDER BY StartDateTime
        ];

        for (Event meeting : meetings) {
            this.giftOfficer = meeting.Owner.Name;
            this.meetingSchedule = String.format('{0} - {1}', 
                new List<Object>{
                    meeting.StartDateTime.format('EEEE dd/MM/yyyy h:mm a'),
                    meeting.Location
                });

            break;
        }
    }

    private void loadEndowedFunds() {
        List<ucinn_ascendv2__Designation_Stewardship__c> stewardships = [
            SELECT ucinn_ascendv2__Designation__c, ucinn_ascendv2__Designation__r.ucinn_ascendv2__Fund_Name__c, ucinn_ascendv2__Designation__r.ucinn_ascendv2__Endowment_Book_Value__c, ucinn_ascendv2__Designation__r.ucinn_ascendv2__Endowment_Market_Value__c 
            FROM ucinn_ascendv2__Designation_Stewardship__c 
            WHERE ucinn_ascendv2__Contact_Stewardee__c = :contactId AND HAM_Reporting_Type__c != 'None'];

        Map<String, EndowedFund> designationMap = new Map<String, EndowedFund>();

        for (ucinn_ascendv2__Designation_Stewardship__c stewardship : stewardships) {
            if (!designationMap.containsKey(stewardship.ucinn_ascendv2__Designation__c)) {
                designationMap.put(stewardship.ucinn_ascendv2__Designation__c, new EndowedFund(stewardship.ucinn_ascendv2__Designation__r.ucinn_ascendv2__Fund_Name__c, 
                stewardship.ucinn_ascendv2__Designation__r.ucinn_ascendv2__Endowment_Book_Value__c, 
                stewardship.ucinn_ascendv2__Designation__r.ucinn_ascendv2__Endowment_Market_Value__c));
            }
        }

        String thisYear = String.valueOf(getThisYear());
        String prevYear = String.valueOf(getThisYear() - 1);
        AggregateResult[] agrs =  [
            SELECT COUNT(Id), ucinn_ascendv2__Designation__c, ucinn_ascendv2__Contact__c 
            FROM ucinn_ascendv2__Designation_Beneficiary__c 
            WHERE ucinn_ascendv2__Designation__c IN :designationMap.keySet()
                AND (ucinn_ascendv2__Fiscal_Year__c = :thisYear OR ucinn_ascendv2__Fiscal_Year__c = :prevYear)
            GROUP BY ucinn_ascendv2__Designation__c, ucinn_ascendv2__Contact__c];



        List<EndowedFund> endowedFunds = new List<EndowedFund>();
        for (AggregateResult ag : agrs) {
               
            if (designationMap.containsKey((String) ag.get('ucinn_ascendv2__Designation__c'))) {

                EndowedFund fund = designationMap.get((String) ag.get('ucinn_ascendv2__Designation__c'));
                fund.recipientsCount++;
            }
        }

        this.endowedFunds = designationMap.values();
    }

    private static String createContentDocument(String contactId, String fileName, Blob content) {
        ContentVersion cv = new ContentVersion();
        cv.ContentLocation = 'S';
        cv.VersionData = content;
        cv.Title = fileName;
        cv.PathOnClient = fileName;
        cv.IsMajorVersion = true;
        insert cv;

        Id contentDocId = [
            SELECT ContentDocumentId 
            FROM ContentVersion 
            WHERE Id = :cv.Id].ContentDocumentId;

        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.ContentDocumentId = contentDocId;
        cdl.LinkedEntityId = contactId;
        cdl.ShareType = 'V'; // Viewer permission
        insert cdl;

        return contentDocId;
    }


    @AuraEnabled(cacheable=true)
    public static string getBaseUrl(){
        return URL.getOrgDomainUrl().toExternalForm();
    }

    @AuraEnabled(cacheable=true)
    public static List<ucinn_ascendv2__Briefing__c> getContactsBriefing(String contactId){
        String accId = [SELECT Id, AccountId FROM Contact WHERE Id = :contactId LIMIT 1].AccountId;

        List<ucinn_ascendv2__Briefing__c> briefings = [
            SELECT Id, HAM_Briefing_Type__c, ucinn_ascendv2__Contact__c, HAM_Briefing_Details__c 
            FROM ucinn_ascendv2__Briefing__c 
            WHERE ucinn_ascendv2__Account__c = :accId];
        return briefings;
    }

    @AuraEnabled
    public static string saveBriefing(String briefingId, String detail){
        ucinn_ascendv2__Briefing__c briefing = new ucinn_ascendv2__Briefing__c();
        briefing.Id = briefingId;
        briefing.HAM_Briefing_Details__c = detail;
        update briefing;
        // TODO: generate file and attached to Constituent
        return briefing.Id;
    }

    @AuraEnabled(cacheable=true)
    public static Digi_Brief_Email_Recipient__c getPDFEmailRecipient(){
        return Digi_Brief_Email_Recipient__c.getOrgDefaults();
    }

    @AuraEnabled
    public static string sendPDF(String contactId, String emailAddress){
        try {
            Contact constituent = [SELECT Id, Name FROM Contact WHERE Id = :contactId LIMIT 1];
            String fileName = 'Presidential Briefing {0} {1}-{2}-{3}.pdf';
            fileName = String.format(fileName, new List<Object>{constituent.Name, rPadDateElem(Date.today().month()), rPadDateElem(Date.today().day()), Date.today().year()});

            PageReference pdf = Page.digitalBriefingPdf;
            pdf.getParameters().put('contactId', contactId);
            pdf.setRedirect(true);

            EmailTemplate et = [SELECT Id, Subject, Body FROM EmailTemplate WHERE DeveloperName = 'Digital_Brief_Email_Template'];

            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setTemplateId(et.Id);
            // mail.setSubject(et.Subject);
            mail.setFileAttachments(new Messaging.EmailFileAttachment[] { prepareEmailAttachment(fileName, Test.isRunningTest() ? Blob.valueOf('test') : pdf.getContent()) });
            // we are not using merge field, otherwise, remove setPlainTextBody
            // mail.setPlainTextBody(et.Body);
            mail.setTargetObjectId(contactId);
            mail.setSaveAsActivity(false);

            Digi_Brief_Email_Recipient__c dbRecipient = Digi_Brief_Email_Recipient__c.getOrgDefaults();
            List<String> trimmedEmails = new List<String>();
            if(dbRecipient?.Email__c != null && emailAddress == null){
                trimEmails(dbRecipient.Email__c, trimmedEmails);
            } else{
                trimEmails(emailAddress, trimmedEmails);
            }
            mail.setToAddresses(trimmedEmails);

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
                }
            }

            createContentDocument(contactId, fileName, Test.isRunningTest() ? Blob.valueOf('test') : pdf.getContent());
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        

        return 'success';
    }

    private static String rPadDateElem(Integer ele) {
        return String.valueOf(ele).length() == 1 ? String.valueOf(ele).leftPad(2, '0') : String.valueOf(ele);
    }

    private static void trimEmails(String rawEmail, List<String> trimmedEmails) {
        for(String email: rawEmail.split(',')){
            trimmedEmails.add(email.trim());
        }
    }

    private static Messaging.EmailFileAttachment prepareEmailAttachment(String name, Blob content) {
        Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
        attachment.setFileName(name);
        attachment.setBody(content);
        attachment.setContentType('application/pdf'); 
        return attachment;
    }

    public List<ucinn_ascendv2__Briefing__c> getBriefings() {
        return this.briefings;
    }

    public String getGiftOfficer() {
        return this.giftOfficer;
    }

    public String getMeetingSchedule() {
        return this.meetingSchedule;
    }

    public Contact getConstituent() {
        return this.constituent;
    }

    public String getProfilePicUrl() {
        return this.profilePicUrl;
    }

    public List<EndowedFund> getEndowedFunds() {
        return this.endowedFunds;
    }

    public String getPhoneNumber() {
        return this.phoneNumber;
    }

    public ucinn_ascendv2__Briefing__c getRecentGivingBriefing() {
        if (this.recentGivingBriefing?.HAM_Briefing_Details__c !=null) {
            this.recentGivingBriefing.HAM_Briefing_Details__c = this.recentGivingBriefing.HAM_Briefing_Details__c.stripHtmlTags();
        }
        return this.recentGivingBriefing;
    }

    public Integer getThisYear() {
        return Date.today().year();
    }

    public String getEndowedFundYearHeader() {
        return getThisYear()-1 + '-' + getThisYear() + ' Recipients';
    }

    public class EndowedFund {
        
        public String fundName {get; set;}
        public Decimal bookValue {get; set;}
        public Decimal marketValue {get;set;}
        public Integer recipientsCount {get; set;}

        public EndowedFund( 
            String fundName,
            Decimal bookValue,
            Decimal marketValue) {
            this.fundName = fundName;
            this.bookValue = bookValue;
            this.marketValue = marketValue;
            this.recipientsCount = 0;
        }
    }

}