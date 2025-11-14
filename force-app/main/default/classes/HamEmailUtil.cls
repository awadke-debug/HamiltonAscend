public with sharing class HamEmailUtil {
    public static List<String> trimCommaDelimitedEmails(String rawEmail) {
        List<String> trimmedEmails = new List<String>();
        for(String email: rawEmail.split(',')){
            trimmedEmails.add(email.trim());
        }

        return trimmedEmails;
    }

    public static void removeEmailConstituents(List<String> emails) {
        List<Contact> contacts = [SELECT Id, Email FROM Contact WHERE Email IN :emails];
        for (Contact c : contacts) {
            emails.remove(emails.indexOf(c.Email));
        }
    }

    public static void filterEmails(List<String> emails) {
        List<String> tempEmails = emails.clone();

        HAM_Email_Filter_Setting__c emailSetting = HAM_Email_Filter_Setting__c.getInstance();
        for(String emailItem : tempEmails) {
            if (!emailItem.endsWith(emailSetting.HAM_Email_Domain__c) && emailSetting.Restrict_to_Hamilton_Email__c) {
                emails.remove(emails.indexOf(emailItem));
            }
        }
    }

    public static Messaging.EmailFileAttachment preparePdfEmailAttachment(String name, Blob content) {
        Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
        attachment.setFileName(name);
        attachment.setBody(content);
        attachment.setContentType('application/pdf'); 
        return attachment;
    }
}