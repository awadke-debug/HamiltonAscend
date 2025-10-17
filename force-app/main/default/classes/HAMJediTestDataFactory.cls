//#HAMJediActivityControllerTest
@IsTest
public class HAMJediTestDataFactory {
    
    // Constants for better maintainability
    private static final String DEFAULT_CANCELLATION_REASON = 'Other';
    private static final String DEFAULT_TASK_STATUS = 'Open';
    private static final Integer DEFAULT_MEETING_DURATION_HOURS = 1;
    
    // ---- Generic helpers ----
    /**
     * Safely retrieves a valid picklist value, preferring the specified value if active
     * @param objectApi The API name of the SObject
     * @param fieldApi The API name of the picklist field
     * @param preferred The preferred picklist value if it exists and is active
     * @param fallback The fallback value if preferred is not available
     * @return A valid picklist value or the fallback
     */
    private static String pickValue(String objectApi, String fieldApi, String preferred, String fallback) {
        try {
            Schema.SObjectType sObj = Schema.getGlobalDescribe().get(objectApi);
            if (sObj == null) return fallback;
            
            Schema.SObjectField field = sObj.getDescribe().fields.getMap().get(fieldApi);
            if (field == null) return fallback;
            
            Schema.DescribeFieldResult f = field.getDescribe();

            // If preferred exists & active, return it
            if (preferred != null) {
                for (Schema.PicklistEntry e : f.getPicklistValues()) {
                    if (e.isActive() && e.getValue() == preferred) {
                        return preferred;
                    }
                }
            }
            
            // Else return first active
            for (Schema.PicklistEntry e : f.getPicklistValues()) {
                if (e.isActive()) {
                    return e.getValue();
                }
            }
        } catch (Exception e) {
            // Log exception in debug logs for troubleshooting
            System.debug(LoggingLevel.WARN, 'Error getting picklist value: ' + e.getMessage());
        }
        return fallback;
    }

    // ---- Core records ----
    /**
     * Creates a test Account with a unique name
     * @return The inserted Account record
     */
    public static Account makeAccount() {
        return makeAccount('Test Acct ' + System.now().getTime());
    }
    
    /**
     * Creates a test Account with a specific name
     * @param accountName The name for the account
     * @return The inserted Account record
     */
    public static Account makeAccount(String accountName) {
        Account a = new Account(Name = accountName);
        insert a;
        return a;
    }

    /**
     * Creates a test Contact associated with an Account
     * @param accountId The ID of the parent Account
     * @return The inserted Contact record
     */
    public static Contact makeContact(Id accountId) {
        return makeContact('Test ' + System.now().getTime(), accountId);
    }
    
    /**
     * Creates a test Contact with specific name and Account
     * @param lastName The last name for the contact
     * @param accountId The ID of the parent Account
     * @return The inserted Contact record
     */
    public static Contact makeContact(String lastName, Id accountId) {
        Contact c = new Contact(
            LastName = lastName, 
            AccountId = accountId
        );
        insert c;
        return c;
    }

    // ---- Event builders ----
    /**
     * Creates a completed Event
     * @param whoId The ID of the related Contact or Lead
     * @param start The start datetime of the event
     * @return The inserted Event record
     */
    public static Event makeCompletedEvent(Id whoId, Datetime start) {
        return makeCompletedEvent(whoId, start, 'Completed Meeting');
    }
    
    /**
     * Creates a completed Event with custom subject
     * @param whoId The ID of the related Contact or Lead
     * @param start The start datetime of the event
     * @param subject The subject of the event
     * @return The inserted Event record
     */
    public static Event makeCompletedEvent(Id whoId, Datetime start, String subject) {
        Event e = new Event(
            Subject = subject,
            StartDateTime = start,
            EndDateTime = start.addHours(DEFAULT_MEETING_DURATION_HOURS),
            WhoId = whoId,
            HAM_Meeting_Status__c = 'Completed'
        );
        insert e;
        return e;
    }

    /**
     * Creates a cancelled Event
     * @param whoId The ID of the related Contact or Lead
     * @param start The start datetime of the event
     * @return The inserted Event record
     */
    public static Event makeCancelledEvent(Id whoId, Datetime start) {
        return makeCancelledEvent(whoId, start, null);
    }
    
    /**
     * Creates a cancelled Event with specific cancellation reason
     * @param whoId The ID of the related Contact or Lead
     * @param start The start datetime of the event
     * @param cancellationReason The reason for cancellation (null to use default)
     * @return The inserted Event record
     */
    public static Event makeCancelledEvent(Id whoId, Datetime start, String cancellationReason) {
        String reason = cancellationReason != null ? 
            cancellationReason : 
            pickValue('Event', 'HAM_Meeting_cancellation_Reason__c', DEFAULT_CANCELLATION_REASON, DEFAULT_CANCELLATION_REASON);
            
        Event e = new Event(
            Subject = 'Cancelled Meeting',
            StartDateTime = start,
            EndDateTime = start.addHours(DEFAULT_MEETING_DURATION_HOURS),
            WhoId = whoId,
            HAM_Meeting_Status__c = 'Cancelled',
            HAM_Meeting_cancellation_Reason__c = reason
        );
        insert e;
        return e;
    }

    /**
     * Creates a planned/upcoming Event (status intentionally null)
     * @param whoId The ID of the related Contact or Lead
     * @param start The start datetime of the event
     * @return The inserted Event record
     */
    public static Event makePlannedEvent(Id whoId, Datetime start) {
        return makePlannedEvent(whoId, start, 'Planned Meeting');
    }
    
    /**
     * Creates a planned/upcoming Event with custom subject
     * @param whoId The ID of the related Contact or Lead
     * @param start The start datetime of the event
     * @param subject The subject of the event
     * @return The inserted Event record
     */
    public static Event makePlannedEvent(Id whoId, Datetime start, String subject) {
        Event e = new Event(
            Subject = subject,
            StartDateTime = start,
            EndDateTime = start.addHours(DEFAULT_MEETING_DURATION_HOURS),
            WhoId = whoId
            // HAM_Meeting_Status__c intentionally left null for "upcoming" bucket
        );
        insert e;
        return e;
    }

    // ---- Task builders ----
    /**
     * Creates an open Task
     * @param whoId The ID of the related Contact or Lead
     * @param dueDate The due date for the task
     * @return The inserted Task record
     */
    public static Task makeOpenTask(Id whoId, Date dueDate) {
        return makeOpenTask(whoId, dueDate, 'Follow up');
    }
    
    /**
     * Creates an open Task with custom subject
     * @param whoId The ID of the related Contact or Lead
     * @param dueDate The due date for the task
     * @param subject The subject of the task
     * @return The inserted Task record
     */
    public static Task makeOpenTask(Id whoId, Date dueDate, String subject) {
        String openStatus = pickValue('Task', 'Status', DEFAULT_TASK_STATUS, DEFAULT_TASK_STATUS);
        Task t = new Task(
            Subject = subject,
            ActivityDate = dueDate,
            WhoId = whoId,
            Status = openStatus
        );
        insert t;
        return t;
    }
    
    /**
     * Creates a completed Task
     * @param whoId The ID of the related Contact or Lead
     * @param dueDate The due date for the task
     * @return The inserted Task record
     */
    public static Task makeCompletedTask(Id whoId, Date dueDate) {
        String completedStatus = pickValue('Task', 'Status', 'Completed', 'Completed');
        Task t = new Task(
            Subject = 'Completed task',
            ActivityDate = dueDate,
            WhoId = whoId,
            Status = completedStatus
        );
        insert t;
        return t;
    }

    // ---- Bulk creation methods ----
    /**
     * Creates multiple test Accounts
     * @param count The number of accounts to create
     * @return List of inserted Account records
     */
    public static List<Account> makeAccounts(Integer count) {
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < count; i++) {
            accounts.add(new Account(Name = 'Test Acct ' + i + '_' + System.now().getTime()));
        }
        insert accounts;
        return accounts;
    }
    
    /**
     * Creates multiple test Contacts for a single Account
     * @param accountId The ID of the parent Account
     * @param count The number of contacts to create
     * @return List of inserted Contact records
     */
    public static List<Contact> makeContacts(Id accountId, Integer count) {
        List<Contact> contacts = new List<Contact>();
        for (Integer i = 0; i < count; i++) {
            contacts.add(new Contact(
                LastName = 'Test ' + i + '_' + System.now().getTime(),
                AccountId = accountId
            ));
        }
        insert contacts;
        return contacts;
    }

    // ---- Dataset seeding methods ----
    /**
     * Seeds a basic set of activities for a contact
     * @param contactId The ID of the contact to create activities for
     */
    public static void seedBasicActivityDataset(Id contactId) {
        makeCompletedEvent(contactId, System.now().addDays(-2));
        makeCancelledEvent(contactId, System.now().addDays(1));
        makePlannedEvent(contactId, System.now().addDays(3));
        makeOpenTask(contactId, Date.today().addDays(1));
    }
    
    /**
     * Creates a complete test dataset with Account, Contact, and Activities
     * @return Map containing 'account', 'contact', 'events', and 'tasks' keys
     */
    public static Map<String, Object> createFullTestDataset() {
        Account acc = makeAccount();
        Contact con = makeContact(acc.Id);
        
        List<Event> events = new List<Event>{
            makeCompletedEvent(con.Id, System.now().addDays(-2)),
            makeCancelledEvent(con.Id, System.now().addDays(1)),
            makePlannedEvent(con.Id, System.now().addDays(3))
        };
        
        List<Task> tasks = new List<Task>{
            makeOpenTask(con.Id, Date.today().addDays(1)),
            makeCompletedTask(con.Id, Date.today().addDays(-1))
        };
        
        return new Map<String, Object>{
            'account' => acc,
            'contact' => con,
            'events' => events,
            'tasks' => tasks
        };
    }

    //#HAMJediEventControllerTest
    // ---- Conference360 Event builders ----
    /**
     * Creates a test Event record
     * @param eventName The name of the event
     * @return The inserted Event record
     */
    public static conference360__Event__c makeEvent(String eventName) {
        conference360__Event__c event = new conference360__Event__c(
            Name = eventName
            // Only setting Name field, other fields may be formula/auto-populated
        );
        insert event;
        return event;
    }

    // ---- Conference360 Attendee builders ----
    /**
     * Creates a test Attendee record with default values
     * @param contactId The ID of the related Contact
     * @return The inserted Attendee record
     */
    public static conference360__Attendee__c makeAttendee(Id contactId) {
        conference360__Event__c event = makeEvent('Test Event ' + System.now().getTime());
        return makeAttendee(contactId, event.Id, 'Registered', 'Attended');
    }
    
    /**
     * Creates a test Attendee record with custom values
     * @param contactId The ID of the related Contact
     * @param eventId The ID of the related Event
     * @param registrationStatus The registration status
     * @param attendanceStatus The attendance status
     * @return The inserted Attendee record
     */
    public static conference360__Attendee__c makeAttendee(Id contactId, Id eventId, String registrationStatus, String attendanceStatus) {
        conference360__Attendee__c attendee = new conference360__Attendee__c(
            conference360__Contact__c = contactId,
            conference360__Event__c = eventId,
            conference360__Registration_Status__c = registrationStatus,
            conference360__Attendance_Status__c = attendanceStatus
        );
        insert attendee;
        return attendee;
    }
    
    /**
     * Creates multiple test Attendee records for a contact
     * @param contactId The ID of the related Contact
     * @param count The number of attendee records to create
     * @return List of inserted Attendee records
     */
    public static List<conference360__Attendee__c> makeAttendees(Id contactId, Integer count) {
        List<conference360__Attendee__c> attendees = new List<conference360__Attendee__c>();
        
        for (Integer i = 0; i < count; i++) {
            conference360__Event__c event = makeEvent('Test Event ' + i);
            attendees.add(new conference360__Attendee__c(
                conference360__Contact__c = contactId,
                conference360__Event__c = event.Id,
                conference360__Registration_Status__c = 'Registered',
                conference360__Attendance_Status__c = 'Attended'
            ));
        }
        insert attendees;
        return attendees;
    }

    // ---- ExactTarget Email Send Definition builder ----
    /**
     * Creates a test Email Send Definition record
     * @return The inserted Email Send Definition record
     */
    public static et4ae5__SendDefinition__c makeEmailSendDefinition() {
        et4ae5__SendDefinition__c sendDef = new et4ae5__SendDefinition__c();
        insert sendDef;
        return sendDef;
    }

    // ---- ExactTarget Email Result builders ----
    /**
     * Creates a test Individual Email Result record with default values
     * @param contactId The ID of the related Contact
     * @return The inserted Email Result record
     */
    public static et4ae5__IndividualEmailResult__c makeEmailResult(Id contactId) {
        et4ae5__SendDefinition__c sendDef = makeEmailSendDefinition();
        return makeEmailResult(contactId, sendDef.Id, 'Test Sender', 'test@example.com', 'Test Subject');
    }
    
    /**
     * Creates a test Individual Email Result record with custom values
     * @param contactId The ID of the related Contact
     * @param sendDefinitionId The ID of the Email Send Definition
     * @param fromName The sender name
     * @param fromAddress The sender email address
     * @param subject The email subject
     * @return The inserted Email Result record
     */
    public static et4ae5__IndividualEmailResult__c makeEmailResult(Id contactId, Id sendDefinitionId, String fromName, String fromAddress, String subject) {
        et4ae5__IndividualEmailResult__c emailResult = new et4ae5__IndividualEmailResult__c(
            Name = 'Test Email Result ' + System.now().getTime(),
            et4ae5__Contact__c = contactId,
            et4ae5__SendDefinition__c = sendDefinitionId,
            et4ae5__FromName__c = fromName,
            et4ae5__FromAddress__c = fromAddress,
            et4ae5__SubjectLine__c = subject,
            et4ae5__HardBounce__c = false,
            et4ae5__SoftBounce__c = false,
            et4ae5__Opened__c = true,
            et4ae5__DateOpened__c = System.now().addHours(-1),
            et4ae5__NumberOfTotalClicks__c = 5,
            et4ae5__NumberOfUniqueClicks__c = 3
        );
        insert emailResult;
        return emailResult;
    }
    
    /**
     * Creates multiple test Email Result records for a contact
     * @param contactId The ID of the related Contact
     * @param count The number of email result records to create
     * @return List of inserted Email Result records
     */
    public static List<et4ae5__IndividualEmailResult__c> makeEmailResults(Id contactId, Integer count) {
        List<et4ae5__IndividualEmailResult__c> emailResults = new List<et4ae5__IndividualEmailResult__c>();
        
        for (Integer i = 0; i < count; i++) {
            et4ae5__SendDefinition__c sendDef = makeEmailSendDefinition();
            emailResults.add(new et4ae5__IndividualEmailResult__c(
                Name = 'Test Email Result ' + i + '_' + System.now().getTime(),
                et4ae5__Contact__c = contactId,
                et4ae5__SendDefinition__c = sendDef.Id,
                et4ae5__FromName__c = 'Sender ' + i,
                et4ae5__FromAddress__c = 'sender' + i + '@example.com',
                et4ae5__SubjectLine__c = 'Email Subject ' + i,
                et4ae5__HardBounce__c = false,
                et4ae5__SoftBounce__c = false,
                et4ae5__Opened__c = true,
                et4ae5__DateOpened__c = System.now().addHours(-i),
                et4ae5__NumberOfTotalClicks__c = 5,
                et4ae5__NumberOfUniqueClicks__c = 3
            ));
        }
        insert emailResults;
        return emailResults;
    }

    // ---- Dataset seeding methods for Event Controller ----
    /**
     * Creates a complete dataset for testing HAMJediEventController
     * @return Map containing 'account', 'contact', 'attendees', and 'emails' keys
     */
    public static Map<String, Object> createEventControllerTestDataset() {
        Account acc = makeAccount();
        Contact con = makeContact(acc.Id);
        
        List<conference360__Attendee__c> attendees = makeAttendees(con.Id, 3);
        List<et4ae5__IndividualEmailResult__c> emails = makeEmailResults(con.Id, 2);
        
        return new Map<String, Object>{
            'account' => acc,
            'contact' => con,
            'attendees' => attendees,
            'emails' => emails
        };
    }

    //#HAMJediSearchControllerTest
   // ---- Contact builders with donor ID for search testing ----
    /**
     * Creates a test Contact with donor ID for search functionality
     * @param lastName The last name for the contact
     * @param accountId The ID of the parent Account
     * @param donorId The donor ID for the contact
     * @return The inserted Contact record
     */
    public static Contact makeContactWithDonorId(String lastName, Id accountId, String donorId) {
        Contact c = new Contact(
            LastName = lastName,
            AccountId = accountId,
            ucinn_ascendv2__Donor_ID__c = donorId,
            Email = lastName.toLowerCase() + '@test.com',
            Phone = '5551234567'
        );
        insert c;
        return c;
    }

    /**
     * Creates a test Contact with auto-generated donor ID
     * @param lastName The last name for the contact
     * @param accountId The ID of the parent Account
     * @return The inserted Contact record
     */
    public static Contact makeContactWithDonorId(String lastName, Id accountId) {
        return makeContactWithDonorId(lastName, accountId, 'D' + String.valueOf(System.now().getTime()).right(8));
    }

    /**
     * Creates multiple test Contacts with donor IDs
     * @param accountId The ID of the parent Account
     * @param count The number of contacts to create
     * @return List of inserted Contact records
     */
    public static List<Contact> makeContactsWithDonorIds(Id accountId, Integer count) {
        List<Contact> contacts = new List<Contact>();
        for (Integer i = 0; i < count; i++) {
            String lastName = 'TestContact' + i;
            contacts.add(new Contact(
                LastName = lastName,
                AccountId = accountId,
                ucinn_ascendv2__Donor_ID__c = 'D' + String.valueOf(System.now().getTime() + i).right(8),
                Email = lastName.toLowerCase() + '@test.com',
                Phone = '555123456' + i
            ));
        }
        insert contacts;
        return contacts;
    }

    //#HAMProspectOverviewApexControllerTest
    // ---- ucinn_ascendv2 objects for prospect testing ----
    /**
     * Creates a test Designation record
     * @return The inserted Designation record
     */
    public static ucinn_ascendv2__Designation__c makeDesignation() {
        ucinn_ascendv2__Designation__c designation = new ucinn_ascendv2__Designation__c(
            ucinn_ascendv2__Designation_Name__c = 'Test Fund ' + System.now().getTime(),
            ucinn_ascendv2__Fund_Name__c = 'Test Fund'
        );
        insert designation;
        return designation;
    }

    /**
     * Creates a test Designation Stewardship record
     * @param contactId The ID of the related Contact
     * @param designationId The ID of the related Designation
     * @return The inserted Designation Stewardship record
     */
    public static ucinn_ascendv2__Designation_Stewardship__c makeDesignationStewardship(Id contactId, Id designationId) {
        ucinn_ascendv2__Designation_Stewardship__c stewardship = new ucinn_ascendv2__Designation_Stewardship__c(
            ucinn_ascendv2__Contact_Stewardee__c = contactId,
            ucinn_ascendv2__Designation__c = designationId,
            ucinn_ascendv2__Status__c = 'Current',
            HAM_Reporting_Type__c = 'Active'
        );
        insert stewardship;
        return stewardship;
    }

    /**
     * Creates a test Service Indicator record
     * @param contactId The ID of the related Contact
     * @return The inserted Service Indicator record
     */
    public static ucinn_ascendv2__Service_Indicator__c makeServiceIndicator(Id contactId) {
        ucinn_ascendv2__Service_Indicator__c indicator = new ucinn_ascendv2__Service_Indicator__c(
            ucinn_ascendv2__Contact__c = contactId
        );
        insert indicator;
        return indicator;
    }

    /**
     * Creates a test Degree Information record
     * @param contactId The ID of the related Contact
     * @return The inserted Degree Information record
     */
    public static ucinn_ascendv2__Degree_Information__c makeDegreeInformation(Id contactId) {
        ucinn_ascendv2__Degree_Information__c degree = new ucinn_ascendv2__Degree_Information__c(
            ucinn_ascendv2__Contact__c = contactId,
            ucinn_ascendv2__Conferred_Degree_Year__c = '2020'
        );
        insert degree;
        return degree;
    }

    /**
     * Creates a test Involvement record
     * @param contactId The ID of the related Contact
     * @return The inserted Involvement record
     */
    public static ucinn_ascendv2__Involvement__c makeInvolvement(Id contactId) {
        ucinn_ascendv2__Involvement__c involvement = new ucinn_ascendv2__Involvement__c(
            ucinn_ascendv2__Contact__c = contactId
        );
        insert involvement;
        return involvement;
    }

    /**
     * Creates a test Designation Beneficiary record (for awards)
     * @param contactId The ID of the related Contact
     * @return The inserted Designation Beneficiary record
     */
    public static ucinn_ascendv2__Designation_Beneficiary__c makeDesignationBeneficiary(Id contactId) {
        ucinn_ascendv2__Designation__c designation = makeDesignation();
        
        ucinn_ascendv2__Designation_Beneficiary__c beneficiary = new ucinn_ascendv2__Designation_Beneficiary__c(
            ucinn_ascendv2__Contact__c = contactId,
            ucinn_ascendv2__Designation__c = designation.Id,
            ucinn_ascendv2__Type__c = 'Award',
            ucinn_ascendv2__Fiscal_Year__c = String.valueOf(Date.today().year())
        );
        insert beneficiary;
        return beneficiary;
    }

    //#HAMJediContactReportControllerTest
    /**
     * Creates a test Contact Report record
     * @param contactId The ID of the related Contact
     * @return The inserted Contact Report record
     */
    public static ucinn_ascendv2__Contact_Report__c makeContactReport(Id contactId) {
        ucinn_ascendv2__Contact_Report__c contactReport = new ucinn_ascendv2__Contact_Report__c(
            ucinn_ascendv2__Contact__c = contactId,
            ucinn_ascendv2__Contact_Method__c = 'In Person',
            ucinn_ascendv2__Substantive_Contact__c = 'Yes',
            ucinn_ascendv2__Description__c = 'Test contact report',
            ucinn_ascendv2__Contact_Report_Body__c = 'This is a test contact report body',
            ucinn_ascendv2__Date__c = Date.today()
        );
        insert contactReport;
        return contactReport;
    }

    /**
     * Creates multiple test Contact Report records
     * @param contactId The ID of the related Contact
     * @param count The number of contact reports to create
     * @return List of inserted Contact Report records
     */
    public static List<ucinn_ascendv2__Contact_Report__c> makeContactReports(Id contactId, Integer count) {
        List<ucinn_ascendv2__Contact_Report__c> reports = new List<ucinn_ascendv2__Contact_Report__c>();
        for (Integer i = 0; i < count; i++) {
            String substantiveValue = Math.mod(i, 2) == 0 ? 'Yes' : 'No';
            reports.add(new ucinn_ascendv2__Contact_Report__c(
                ucinn_ascendv2__Contact__c = contactId,
                ucinn_ascendv2__Contact_Method__c = 'Email',
                ucinn_ascendv2__Substantive_Contact__c = substantiveValue,
                ucinn_ascendv2__Description__c = 'Test report ' + i,
                ucinn_ascendv2__Contact_Report_Body__c = 'Test body ' + i,
                ucinn_ascendv2__Date__c = Date.today().addDays(-i)
            ));
        }
        insert reports;
        return reports;
    }
}