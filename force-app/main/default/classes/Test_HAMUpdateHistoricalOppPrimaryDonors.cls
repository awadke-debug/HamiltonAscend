@isTest(SeeAllData=false)
private class Test_HAMUpdateHistoricalOppPrimaryDonors {
    
    @testSetup
    static void setupTestData() {
	
        RecordType householdrectype = [SELECT Id, Name FROM RecordType WHERE SObjectType = 'Account' AND Name = 'Household'];
        RecordType Corporaterectype= [SELECT Id, Name FROM RecordType WHERE SObjectType = 'Account' AND Name = 'Corporations and Organizations' ];
		RecordType householdcontact = [SELECT Id, Name FROM RecordType WHERE SObjectType = 'Contact' AND Name = 'Constituent Details'];
        RecordType pledgeOpp = [SELECT Id, Name FROM RecordType WHERE SObjectType = 'Opportunity' AND Name = 'Pledge' ];
		RecordType giftOpp = [SELECT Id, Name FROM RecordType WHERE SObjectType = 'Opportunity' AND Name = 'Gift' ];

        List<Contact> lstContacts = new List<Contact>();
		List<Account> lstAccounts = new List<Account>();
		List<Opportunity> lstOpps = new List<Opportunity>();
		List<ucinn_ascendv2__Hard_and_Soft_Credit__c> lstCredits = new List<ucinn_ascendv2__Hard_and_Soft_Credit__c>();

        Contact primaryContact = new Contact(
            LastName = 'Primary',
            ucinn_ascendv2__Primary_Contact_Type__c = 'Trustee',
            ucinn_ascendv2__Contact_Type__c = 'Trustee',
			email = 'testtester@gmail.com',
			ucinn_ascendv2__Marital_Status__c = 'Married',
			HAM_Is_Active__c = TRUE,
			recordtypeId = householdcontact.Id
        );
        lstContacts.add(primaryContact);
		Contact primarySpouseContact = new Contact(
            LastName = 'Primary Spouse',
            ucinn_ascendv2__Primary_Contact_Type__c = 'Trustee',
            ucinn_ascendv2__Contact_Type__c = 'Trustee',
			email = '123testtester@gmail.com',
			ucinn_ascendv2__Marital_Status__c = 'Married',
			HAM_Is_Active__c = TRUE,
			recordtypeId = householdcontact.Id
        );
        lstContacts.add(primarySpouseContact);
		Contact affiliationContact = new Contact(
            LastName = 'Secondary Affiliation',
            ucinn_ascendv2__Primary_Contact_Type__c = 'Trustee',
            ucinn_ascendv2__Contact_Type__c = 'Trustee',
			email = 'test123tester@gmail.com',
			ucinn_ascendv2__Marital_Status__c = 'Single',
			recordtypeId = householdcontact.Id,
			HAM_Is_Active__c = TRUE
        );
        lstContacts.add(affiliationContact);
		Contact specialContact = new Contact(
            LastName = 'special',
            ucinn_ascendv2__Primary_Contact_Type__c = 'Trustee',
            ucinn_ascendv2__Contact_Type__c = 'Trustee',
			email = 'testtester1234@gmail.com',
			ucinn_ascendv2__Marital_Status__c = 'Married',
			HAM_Is_Active__c = TRUE,
			recordtypeId = householdcontact.Id
        );
        lstContacts.add(specialContact);
		
		insert lstContacts;
        for(Contact tempCont: lstContacts){
            if(tempCont.LASTNAME == 'Primary'){
                primaryContact = tempCont;
            }else if(tempCont.LASTNAME == 'Secondary Affiliation'){
                affiliationContact = tempCont;
            }else if(tempCont.LASTNAME == 'special'){
                specialContact = tempCont;
            }else{
				primarySpouseContact = tempCont;
			}
        }
		
		
		Account householdOrg = new Account(
            Name = 'Test household',
            ucinn_ascendv2__Primary_Contact__c = primaryContact.Id,
			RecordTypeId = householdrectype.Id,
			ucinn_ascendv2__Number_of_Household_Members__c = 2,
            Type = 'Organization'
        );
		lstAccounts.add(householdOrg);
		Account accCharity = new Account(
            Name = 'Test New York University',
			AccountNumber = '3045797',
			ucinn_ascendv2__Donor_ID__c = '00309761',
			RecordTypeId = Corporaterectype.Id,
            Type = 'Corporation'
        );
        lstAccounts.add(accCharity);
		Account accWithoutPrimary = new Account(Name = 'Test Account 2', recordtypeID = Corporaterectype.Id);
        lstAccounts.add(accWithoutPrimary);
		
		insert lstAccounts;

        for(Account tempAcc: lstAccounts){
            if(tempAcc.name == 'Test household'){
                householdOrg = tempAcc;
            }else if(tempAcc.NAME == 'Test New York University'){
                accCharity = tempAcc;
            }else if(tempAcc.NAME == 'Test Account 2'){
                accWithoutPrimary = tempAcc;
            }
        }
        

		ucinn_ascendv2__Affiliation__c aff = new ucinn_ascendv2__Affiliation__c(
            ucinn_ascendv2__Account__c = accCharity.Id,
            ucinn_ascendv2__Contact__c = affiliationContact.Id,
            HAM_Is_Primary_Donor__c = true,
			ucinn_ascendv2__Status__c = 'Current',
            ucinn_ascendv2__Constituent_Role__c= 'Employee',
			ucinn_ascendv2__Organization_Role__c = 'Employer',
			HAM_Primary_Employer__c = TRUE
        );
        insert aff;

        Opportunity pledgeOpp1 = new Opportunity(
            Name = 'Test Pledge',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            AccountId = accCharity.Id,
			RecordtypeId = pledgeOpp.Id,
			Type = 'Standard',
			Amount = 250,
			ucinn_ascendv2__Commitment_Type__c = 'Regular',
			ucinn_ascendv2__Credit_Date__c = Date.today(),
			ucinn_ascendv2__Entry_Date__c = Date.today(),
			HAM_Original_Pledge_Amount__c = 250,
			ucinn_ascendv2__Number_of_Unpaid_Installment__c = 2
        );
        lstOpps.add(pledgeOpp1);

        Opportunity giftOpp1 = new Opportunity(
            Name = 'Test Gift',
            StageName = 'Funded',
            CloseDate = Date.today().addDays(30),
            ucinn_ascendv2__Contact__c = primaryContact.Id,
			RecordtypeId = giftOpp.Id,
			Type = 'Outright',
			Amount = 200,
			ucinn_ascendv2__Tender_Type_for_Gifts__c = 'ACH (Automated Clearing House)',
			ucinn_ascendv2__Receipt_Number__c= 'RN-0585469',
			ucinn_ascendv2__Credit_Date__c = Date.today(),
			ucinn_ascendv2__Entry_Date__c = Date.today().addDays(20)
        );
        lstOpps.add(giftOpp1); 
		Opportunity giftOpp2Spouse = new Opportunity(
            Name = 'Test Gift Spouse',
            StageName = 'Funded',
            CloseDate = Date.today().addDays(30),
            ucinn_ascendv2__Contact__c = primarySpouseContact.Id,
			RecordtypeId = giftOpp.Id,
			Type = 'Outright',
			Amount = 200,
			ucinn_ascendv2__Tender_Type_for_Gifts__c = 'ACH (Automated Clearing House)',
			ucinn_ascendv2__Receipt_Number__c= 'RN-0585469',
			ucinn_ascendv2__Credit_Date__c = Date.today(),
			ucinn_ascendv2__Entry_Date__c = Date.today().addDays(20)
        );
        lstOpps.add(giftOpp2Spouse);

        Opportunity opp3 = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Funded',
            CloseDate = Date.today().addDays(30),
            RecordtypeId = giftOpp.Id,
			Type = 'Outright',
			Amount = 200,
			ucinn_ascendv2__Tender_Type_for_Gifts__c = 'ACH (Automated Clearing House)',
			ucinn_ascendv2__Receipt_Number__c= 'RN-0585469',
			ucinn_ascendv2__Credit_Date__c = Date.today(),
			ucinn_ascendv2__Entry_Date__c = Date.today().addDays(20),
            ucinn_ascendv2__Contact__c = specialContact.Id
        );
        lstOpps.add(opp3);
        Opportunity opp4 = new Opportunity(
            Name = 'Test Opportunity household',
            StageName = 'Funded',
            CloseDate = Date.today().addDays(30),
			RecordtypeId = giftOpp.Id,
			Type = 'Outright',
			Amount = 200,
			ucinn_ascendv2__Tender_Type_for_Gifts__c = 'ACH (Automated Clearing House)',
			ucinn_ascendv2__Receipt_Number__c= 'RN-0585478',
			ucinn_ascendv2__Credit_Date__c = Date.today(),
			ucinn_ascendv2__Entry_Date__c = Date.today().addDays(20),
            AccountId = householdOrg.Id
        );
        lstOpps.add(opp4);
		Insert lstOpps;
        for(Opportunity opptemp: lstOpps){
            system.debug('Opp'+opptemp);
        }
        
        for(Opportunity tempOpp: lstOpps){
            if(tempOpp.name == 'Test Pledge'){
                pledgeOpp1 = tempOpp;
            }else if(tempOpp.NAME == 'Test Gift'){
                giftOpp1 = tempOpp;
            }else if(tempOpp.NAME == 'Test Opportunity'){
                opp3 = tempOpp;
            }else if(tempOpp.NAME == 'Test Gift Spouse'){
				giftOpp2Spouse = tempOpp;
			}else{
                opp4 = tempOpp;
            }
        }

        List<ucinn_ascendv2__Designation_Detail__c> lstDesignationDetails = new List<ucinn_ascendv2__Designation_Detail__c>();
		ucinn_ascendv2__Designation_Detail__c oppPledgeDesignation = new ucinn_ascendv2__Designation_Detail__c();
		oppPledgeDesignation.ucinn_ascendv2__Opportunity__c = pledgeOpp1.Id;
		ucinn_ascendv2__Designation_Detail__c oppGiftDesignation = new ucinn_ascendv2__Designation_Detail__c();
		oppGiftDesignation.ucinn_ascendv2__Opportunity__c = giftOpp1.Id;
		lstDesignationDetails.add(oppPledgeDesignation);
		lstDesignationDetails.add(oppGiftDesignation);
		insert lstDesignationDetails;
		for(ucinn_ascendv2__Designation_Detail__c tempDesignation: lstDesignationDetails){
			if(tempDesignation.ucinn_ascendv2__Opportunity__c == pledgeOpp1.Id){
				oppPledgeDesignation = tempDesignation;
			}else{
				oppGiftDesignation = tempDesignation;
			}
		}

        ucinn_ascendv2__Hard_and_Soft_Credit__c charityCredit = new ucinn_ascendv2__Hard_and_Soft_Credit__c(
            ucinn_ascendv2__Contact__c = primaryContact.Id,
            ucinn_ascendv2__Opportunity__c = pledgeOpp1.Id,
            ucinn_ascendv2__Credit_Type__c = 'Soft',
			ucinn_ascendv2__Source__c = 'Pledge',
            ucinn_ascendv2__Designation_Detail__c = oppPledgeDesignation.Id
        );
        lstCredits.add(charityCredit);
		ucinn_ascendv2__Hard_and_Soft_Credit__c charityCredit2 = new ucinn_ascendv2__Hard_and_Soft_Credit__c(
            ucinn_ascendv2__Account__c = accCharity.Id,
            ucinn_ascendv2__Opportunity__c = pledgeOpp1.Id,
            ucinn_ascendv2__Credit_Type__c = 'Hard',
			ucinn_ascendv2__Source__c = 'Pledge',
            ucinn_ascendv2__Designation_Detail__c = oppPledgeDesignation.Id
        );
        lstCredits.add(charityCredit2);
        ucinn_ascendv2__Hard_and_Soft_Credit__c charityAffiCredit3 = new ucinn_ascendv2__Hard_and_Soft_Credit__c(
            ucinn_ascendv2__Contact__c = affiliationContact.Id,
            ucinn_ascendv2__Opportunity__c = pledgeOpp1.Id,
            ucinn_ascendv2__Credit_Type__c = 'Hard',
			ucinn_ascendv2__Source__c = 'Pledge',
            ucinn_ascendv2__Designation_Detail__c = oppPledgeDesignation.Id
        );
        lstCredits.add(charityAffiCredit3);
		
		
		ucinn_ascendv2__Hard_and_Soft_Credit__c giftCredit = new ucinn_ascendv2__Hard_and_Soft_Credit__c(
            ucinn_ascendv2__Contact__c = affiliationContact.Id,
            ucinn_ascendv2__Opportunity__c = giftOpp1.Id,
            ucinn_ascendv2__Credit_Type__c = 'Soft',
			ucinn_ascendv2__Source__c = 'Gift',
            ucinn_ascendv2__Designation_Detail__c = oppGiftDesignation.Id
        );
        lstCredits.add(giftCredit);
		ucinn_ascendv2__Hard_and_Soft_Credit__c giftSpouseCredit = new ucinn_ascendv2__Hard_and_Soft_Credit__c(
            ucinn_ascendv2__Contact__c = primarySpouseContact.Id,
            ucinn_ascendv2__Opportunity__c = giftOpp2Spouse.Id,
            ucinn_ascendv2__Credit_Type__c = 'Soft',
			ucinn_ascendv2__Source__c = 'Gift',
            ucinn_ascendv2__Designation_Detail__c = oppGiftDesignation.Id
        );
        lstCredits.add(giftSpouseCredit);
		insert lstCredits;

		List<Contact> lstUpdateContacts = new list<Contact> ();
		
        primaryContact.AccountId = householdOrg.Id;
		primarySpouseContact.accountId = householdOrg.Id;
		lstUpdateContacts.add(primaryContact);
		lstUpdateContacts.add(primarySpouseContact);
		Update lstUpdateContacts;

        Account tempSpecialAcc = new Account();
        String primaryContactId = specialContact.ID;
        String querystr = 'SELECT ID, Name, ucinn_ascendv2__Primary_Contact__c FROM Account WHERE ucinn_ascendv2__Primary_Contact__c = \''+specialContact.ID+'\' Limit 1';
        tempSpecialAcc = Database.Query(querystr);
        tempSpecialAcc.ucinn_ascendv2__Primary_Contact__c = null;
        Update tempSpecialAcc;
    }

    @isTest
    static void testBatchExecution() {
        Test.startTest();
        HAMUpdateHistoricalOppPrimaryDonors batch = new HAMUpdateHistoricalOppPrimaryDonors();
        Database.executeBatch(batch);
        Test.stopTest();

        
    }

    @isTest
    static void testFetchMethods() {
        HAMUpdateHistoricalOppPrimaryDonors cls = new HAMUpdateHistoricalOppPrimaryDonors();
        Set<Id> accIds = new Set<Id>{ [SELECT Id FROM Account LIMIT 1].Id };
        Map<Id, Id> resultMap = cls.fetchRelatedPrimaryAffiliations(accIds);
        System.assert(resultMap != null);

        Set<Id> contactIds = new Set<Id>{ [SELECT Id FROM Contact LIMIT 1].Id };
        Map<Id, Contact> contactMap = cls.fetchConstitiuentDetails(contactIds);
        System.assert(contactMap != null);
    }

    @isTest
    static void testCountUpload() {
        HAMPopulatePrimaryDonorAndHardCredits batch = new HAMPopulatePrimaryDonorAndHardCredits();
        Test.startTest();
            Database.executeBatch(batch);
        Test.stopTest();
        
    }

}