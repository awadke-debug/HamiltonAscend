// Controller class to manage file operations for Contacts' Account files in the HAM Jedi system
public with sharing class HAMJediParentFilesController {
    
    // Fetch all files attached to the Account linked to the given Contact, sorted by creation date descending
    @AuraEnabled
    public static List<HAMJediParentFilesWrapper> getAccountFiles(String contactId) {
        // Query the Contact record to get its associated Account ID
        Contact contact = [SELECT Id, AccountId FROM Contact WHERE Id = :contactId LIMIT 1];
        
        // Return empty list if Contact does not have an associated Account
        if (contact.AccountId == null) {
            return new List<HAMJediParentFilesWrapper>();
        }
        
        // Query all ContentDocumentLinks attached to the Account, retrieving file metadata sorted by newest first
        List<ContentDocumentLink> cdlList = [
            SELECT ContentDocumentId, ContentDocument.Title, ContentDocument.CreatedDate, ContentDocument.FileExtension, ContentDocument.ContentSize
            FROM ContentDocumentLink 
            WHERE LinkedEntityId = :contact.AccountId
            ORDER BY ContentDocument.CreatedDate DESC
        ];
        
        // Initialize the result list to hold wrapper objects
        List<HAMJediParentFilesWrapper> result = new List<HAMJediParentFilesWrapper>();
        
        // Loop through each ContentDocumentLink and create wrapper objects with file information
        for (ContentDocumentLink cdl : cdlList) {
            result.add(new HAMJediParentFilesWrapper(
                cdl.ContentDocumentId,
                cdl.ContentDocument.Title,
                cdl.ContentDocument.CreatedDate,
                cdl.ContentDocument.FileExtension,
                cdl.ContentDocument.ContentSize
            ));
        }
        
        // Return the list of file wrapper objects
        return result;
    }
    
    // Retrieve the Account ID associated with a Contact record
    @AuraEnabled
    public static String getAccountIdFromContact(String contactId) {
        // Query the Contact record to retrieve its associated Account ID
        Contact contact = [SELECT Id, AccountId FROM Contact WHERE Id = :contactId LIMIT 1];
        
        // Return the Account ID (may be null if Contact has no Account)
        return contact.AccountId;
    }
    
    // Wrapper class to encapsulate file metadata for returning to the LWC component
    public class HAMJediParentFilesWrapper {
        @AuraEnabled public String fileId;           // The ID of the ContentDocument
        @AuraEnabled public String fileName;         // The name/title of the file
        @AuraEnabled public DateTime createdDate;    // When the file was created
        @AuraEnabled public String fileExtension;    // The file type (pdf, docx, xlsx, etc.)
        @AuraEnabled public Long fileSize;           // The file size in bytes
        
        // Constructor to initialize the wrapper with file information
        public HAMJediParentFilesWrapper(String fileId, String fileName, DateTime createdDate, String fileExtension, Long fileSize) {
            this.fileId = fileId;
            this.fileName = fileName;
            this.createdDate = createdDate;
            this.fileExtension = fileExtension;
            this.fileSize = fileSize;
        }
    }
}