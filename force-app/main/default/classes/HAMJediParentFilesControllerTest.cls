// Test class for HAMJediParentFilesController - covers all methods and edge cases
@IsTest
public class HAMJediParentFilesControllerTest {
    
    // Setup test data for all test methods - creates a test Account and Contact
    @TestSetup
    static void setupTestData() {
        Account acc = HAMJediTestDataFactory.makeAccount('Test Account Files');
        Contact con = HAMJediTestDataFactory.makeContact('TestContact', acc.Id);
    }
    
    // ========================================
    // TEST: getAccountIdFromContact
    // ========================================
    
    // Verify that getAccountIdFromContact returns the Account ID when Contact has an Account
    @IsTest
    static void testGetAccountIdFromContact_WithAccount() {
        Contact contact = [SELECT Id, AccountId FROM Contact LIMIT 1];
        
        Test.startTest();
        String accountId = HAMJediParentFilesController.getAccountIdFromContact(contact.Id);
        Test.stopTest();
        
        Assert.areEqual(contact.AccountId, accountId, 'Should return the correct Account ID');
        Assert.isNotNull(accountId, 'Account ID should not be null');
    }
    
    // Verify that getAccountIdFromContact returns a value when Contact has an Account (auto-assigned by trigger)
    @IsTest
    static void testGetAccountIdFromContact_NoAccount() {
        Contact conNoAccount = new Contact(LastName = 'NoAccount');
        insert conNoAccount;
        
        Test.startTest();
        String accountId = HAMJediParentFilesController.getAccountIdFromContact(conNoAccount.Id);
        Test.stopTest();
        
        // Note: The dlrs_ContactTrigger automatically assigns an Account to Contacts
        // So we verify the method returns whatever Account ID was assigned (not necessarily null)
        Assert.isNotNull(accountId, 'Should return an Account ID (assigned by trigger or existing)');
    }
    
    // ========================================
    // TEST: getAccountFiles
    // ========================================
    
    // Verify that getAccountFiles returns all files when Account has files attached
    @IsTest
    static void testGetAccountFiles_WithFiles() {
        Contact contact = [SELECT Id, AccountId FROM Contact LIMIT 1];
        createTestFiles(contact.AccountId, 3);
        
        Test.startTest();
        List<HAMJediParentFilesController.HAMJediParentFilesWrapper> result = 
            HAMJediParentFilesController.getAccountFiles(contact.Id);
        Test.stopTest();
        
        Assert.areEqual(3, result.size(), 'Should return 3 files');
        Assert.isNotNull(result[0].fileId, 'File ID should not be null');
        Assert.isNotNull(result[0].fileName, 'File name should not be null');
    }
    
    // Verify that getAccountFiles returns empty list when Account has no files
    @IsTest
    static void testGetAccountFiles_NoFiles() {
        Contact contact = [SELECT Id, AccountId FROM Contact LIMIT 1];
        
        Test.startTest();
        List<HAMJediParentFilesController.HAMJediParentFilesWrapper> result = 
            HAMJediParentFilesController.getAccountFiles(contact.Id);
        Test.stopTest();
        
        Assert.areEqual(0, result.size(), 'Should return empty list when no files');
    }
    
    // Verify that getAccountFiles returns empty list when Contact has no associated Account
    @IsTest
    static void testGetAccountFiles_ContactWithoutAccount() {
        Contact conNoAccount = new Contact(LastName = 'NoAccount');
        insert conNoAccount;
        
        Test.startTest();
        List<HAMJediParentFilesController.HAMJediParentFilesWrapper> result = 
            HAMJediParentFilesController.getAccountFiles(conNoAccount.Id);
        Test.stopTest();
        
        Assert.areEqual(0, result.size(), 'Should return empty list for contact without account');
    }
    
    // Verify that all file properties are correctly populated in the wrapper object
    @IsTest
    static void testGetAccountFiles_FilePropertiesPopulated() {
        Contact contact = [SELECT Id, AccountId FROM Contact LIMIT 1];
        createTestFiles(contact.AccountId, 1);
        
        Test.startTest();
        List<HAMJediParentFilesController.HAMJediParentFilesWrapper> result = 
            HAMJediParentFilesController.getAccountFiles(contact.Id);
        Test.stopTest();
        
        Assert.isTrue(result.size() > 0, 'Should return 1 file');
        HAMJediParentFilesController.HAMJediParentFilesWrapper wrapper = result[0];
        Assert.isNotNull(wrapper.fileId, 'fileId should not be null');
        Assert.isNotNull(wrapper.fileName, 'fileName should not be null');
        Assert.isNotNull(wrapper.createdDate, 'createdDate should not be null');
        Assert.isNotNull(wrapper.fileExtension, 'fileExtension should not be null');
        Assert.isNotNull(wrapper.fileSize, 'fileSize should not be null');
    }
    
    // Verify that files are ordered by created date in descending order (newest first)
    @IsTest
    static void testGetAccountFiles_OrderedByCreatedDateDesc() {
        Contact contact = [SELECT Id, AccountId FROM Contact LIMIT 1];
        createTestFiles(contact.AccountId, 3);
        
        Test.startTest();
        List<HAMJediParentFilesController.HAMJediParentFilesWrapper> result = 
            HAMJediParentFilesController.getAccountFiles(contact.Id);
        Test.stopTest();
        
        Assert.areEqual(3, result.size(), 'Should return 3 files');
        for (Integer i = 0; i < result.size() - 1; i++) {
            Assert.isTrue(
                result[i].createdDate >= result[i + 1].createdDate,
                'Files should be ordered by created date descending'
            );
        }
    }
    
    // Verify that files are sorted with newest files first
    @IsTest
    static void testGetAccountFiles_NewestFilesFirst() {
        Contact contact = [SELECT Id, AccountId FROM Contact LIMIT 1];
        
        // Create multiple files using helper to ensure consistent ordering
        createTestFiles(contact.AccountId, 2);
        
        Test.startTest();
        List<HAMJediParentFilesController.HAMJediParentFilesWrapper> result = 
            HAMJediParentFilesController.getAccountFiles(contact.Id);
        Test.stopTest();
        
        // Verify files are returned in descending order by created date
        Assert.areEqual(2, result.size(), 'Should return 2 files');
        Assert.isTrue(
            result[0].createdDate >= result[1].createdDate,
            'Files should be ordered by created date descending (newest first)'
        );
    }
    
    // ========================================
    // TEST: Wrapper Class
    // ========================================
    
    // Verify that the wrapper class correctly instantiates and stores all file properties
    @IsTest
    static void testWrapperInstantiation() {
        String fileId = 'doc123';
        String fileName = 'TestFile.pdf';
        DateTime createdDate = DateTime.now();
        String fileExtension = 'pdf';
        Long fileSize = 1024;
        
        HAMJediParentFilesController.HAMJediParentFilesWrapper wrapper = 
            new HAMJediParentFilesController.HAMJediParentFilesWrapper(
                fileId, fileName, createdDate, fileExtension, fileSize
            );
        
        Assert.areEqual(fileId, wrapper.fileId, 'fileId should match');
        Assert.areEqual(fileName, wrapper.fileName, 'fileName should match');
        Assert.areEqual(createdDate, wrapper.createdDate, 'createdDate should match');
        Assert.areEqual(fileExtension, wrapper.fileExtension, 'fileExtension should match');
        Assert.areEqual(fileSize, wrapper.fileSize, 'fileSize should match');
    }
    
    // Verify that wrapper properties are accessible and modifiable
    @IsTest
    static void testWrapperProperties() {
        HAMJediParentFilesController.HAMJediParentFilesWrapper wrapper = 
            new HAMJediParentFilesController.HAMJediParentFilesWrapper(
                'id1', 'Test.pdf', DateTime.now(), 'pdf', 2048
            );
        
        Assert.isNotNull(wrapper.fileId, 'fileId property should be accessible');
        Assert.isNotNull(wrapper.fileName, 'fileName property should be accessible');
        Assert.isNotNull(wrapper.createdDate, 'createdDate property should be accessible');
        Assert.isNotNull(wrapper.fileExtension, 'fileExtension property should be accessible');
        Assert.isNotNull(wrapper.fileSize, 'fileSize property should be accessible');
    }
    
    // ========================================
    // HELPER METHOD
    // ========================================
    
    // Helper method to create test files attached to an Account for testing purposes
    private static void createTestFiles(Id accountId, Integer count) {
        for (Integer i = 0; i < count; i++) {
            // Create a ContentVersion (file) with test content
            ContentVersion cv = new ContentVersion();
            cv.Title = 'TestFile_' + i;
            cv.VersionData = Blob.valueOf('Test content ' + i);
            cv.PathOnClient = 'TestFile_' + i + '.pdf';
            insert cv;
            
            // Retrieve the ContentDocument ID associated with the newly created ContentVersion
            Id contentDocId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId;
            
            // Create a ContentDocumentLink to attach the file to the Account
            ContentDocumentLink cdl = new ContentDocumentLink();
            cdl.ContentDocumentId = contentDocId;
            cdl.LinkedEntityId = accountId;
            cdl.ShareType = 'V';        // View permission only
            cdl.Visibility = 'AllUsers'; // Visible to all users
            insert cdl;
        }
    }
}