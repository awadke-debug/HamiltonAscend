/*
Developer : OT
Date : 12/06/2023
Description : Salesforce apex handler class to calculate the number of consecutive years a Constituent has made 
payments to the Institution based on credit date on the hard and soft credit object. This handler
class has been called in the Apex Trigger ConsecutiveGivingTrigger on Hard and Soft credit object.
*/
public class ConsecutiveGivingCalculator 
{
    
    public static void calculateConsecutiveGiving(List<Id> sessionIds) 
    {
        System.debug('calculateConsecutiveGiving method started');
        System.debug('SESSIONIDS:::'+sessionIds);
        Set<Id> contactIds = new Set<Id>();
        System.debug('contactIds = ' + contactIds);
        // Query related payments and contacts for the updated sessions
        List<ucinn_ascendv2__Payment__c> payments = 
            [
                SELECT ucinn_ascendv2__Contact__c
                FROM ucinn_ascendv2__Payment__c
                WHERE ucinn_ascendv2__Session__c IN :sessionIds
            ];
        System.debug('payments = ' + payments);
        for (ucinn_ascendv2__Payment__c payment : payments) 
        {
            System.debug('payment = ' + payment);
            if (payment.ucinn_ascendv2__Contact__c != null) 
            {
                contactIds.add(payment.ucinn_ascendv2__Contact__c);
                System.debug('contactIds = ' + contactIds);
            }
        }
        System.debug('CONTACTIDS:::'+contactIds);
        // Calculate consecutive giving and update on contacts
        updateConsecutiveGivingOnContacts(contactIds);
    }
    
    public static void updateConsecutiveGivingOnContacts(Set<Id> contactIds) 
    {
        Map<Id, Integer> contactConsecutiveGivingMap = new Map<Id, Integer>();
        Map<Id, Integer> latestFiscalYearMap = new Map<Id, Integer>();
        
        for (Id contactId : contactIds) 
        {
            System.debug('contactId = ' + contactId);
            contactConsecutiveGivingMap.put(contactId, 0);
            System.debug('contactConsecutiveGivingMap = ' + contactConsecutiveGivingMap);
            latestFiscalYearMap.put(contactId, 0);
            System.debug('latestFiscalYearMap = ' + latestFiscalYearMap);
        }
        System.debug('CONTACT CONSECUTIVE GIVING MAP:::'+contactConsecutiveGivingMap);
        System.debug('LATEST FISCAL YEAR MAP:::'+latestFiscalYearMap);
        
        List<ucinn_ascendv2__Hard_and_Soft_Credit__c> payments = 
            [
                SELECT ucinn_ascendv2__Contact__c, ucinn_ascendv2__Credit_Date_Formula__c
                FROM ucinn_ascendv2__Hard_and_Soft_Credit__c
                WHERE ucinn_ascendv2__Contact__c IN :contactIds
                AND ucinn_ascendv2__Source__c = 'Payment'
                ORDER BY ucinn_ascendv2__Contact__c, ucinn_ascendv2__Credit_Date_Formula__c
            ];
        System.debug('payments = ' + payments);
        for (ucinn_ascendv2__Hard_and_Soft_Credit__c payment : payments) 
        {
            System.debug('payment = ' + payment);
            if (contactConsecutiveGivingMap.containsKey(payment.ucinn_ascendv2__Contact__c)) 
            {
                Integer consecutiveYears = contactConsecutiveGivingMap.get(payment.ucinn_ascendv2__Contact__c);
                System.debug('consecutiveYears = ' + consecutiveYears);
                if (isConsecutiveYear(payment.ucinn_ascendv2__Credit_Date_Formula__c, latestFiscalYearMap.get(payment.ucinn_ascendv2__Contact__c))) 
                {
                    System.debug('Consecutive years incremented');
                    consecutiveYears++;
                } 
                else 
                {
                    System.debug('Consecutive years = 1');
                    consecutiveYears = 1; // Reset consecutive count
                }
                
                contactConsecutiveGivingMap.put(payment.ucinn_ascendv2__Contact__c, consecutiveYears);
                System.debug('contactConsecutiveGivingMap = ' + contactConsecutiveGivingMap);
                latestFiscalYearMap.put(payment.ucinn_ascendv2__Contact__c, getFiscalYear(payment.ucinn_ascendv2__Credit_Date_Formula__c));
                System.debug('latestFiscalYearMap = ' + latestFiscalYearMap);
            }
        }
        System.debug('CONTACT CONSECUTIVE GIVING MAP AFTER:::'+contactConsecutiveGivingMap);
        System.debug('LATEST FISCAL YEAR MAP AFTER:::'+latestFiscalYearMap);
        
        // Update consecutive giving on contacts
        List<Contact> contactsToUpdate = new List<Contact>();
        for (Id contactId : contactConsecutiveGivingMap.keySet()) 
        {
            contactsToUpdate.add(new Contact(Id = contactId, HAM_Consecutive_Years_of_Giving__c = contactConsecutiveGivingMap.get(contactId)));
        }
        System.debug('CONTACTS TO UPDATE:::'+contactsToUpdate);
        if (!contactsToUpdate.isEmpty()) 
        {
            update contactsToUpdate;
        }
    }
    
    private static Boolean isConsecutiveYear(Date creditDate, Integer latestFiscalYear) 
    {
        Integer creditFiscalYear = getFiscalYear(creditDate);
        System.debug('creditFiscalYear = ' + creditFiscalYear);
        return creditFiscalYear == latestFiscalYear + 1 || latestFiscalYear == 0;
    }
    
    private static Integer getFiscalYear(Date dates) 
    {
        System.debug('dates:::'+dates);
        Integer fiscalYear;
        Date fiscalYearStart = Date.newInstance(dates.year(), 7, 1);
        System.debug('fiscalYearStart:::'+fiscalYearStart);
        if (dates < fiscalYearStart) 
        {
            fiscalYear = dates.year() - 1;
        } 
        else 
        {
            fiscalYear = dates.year();
        }
        System.debug('fiscalYear:::'+fiscalYear);
        return fiscalYear;
    }
}