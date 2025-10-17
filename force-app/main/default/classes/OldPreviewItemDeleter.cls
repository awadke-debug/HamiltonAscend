public class OldPreviewItemDeleter implements Database.Batchable<sObject>,Schedulable{
    static Date today7 = Date.today().addDays(-7);

    public Database.QueryLocator start(Database.BatchableContext context)
    {
        return Database.getQueryLocator('Select ID from ucinn__RBK_Preview_Item__c where CreatedDate < :today7');
    }

    public void execute(Database.BatchableContext context, List<SObject> records)
    {
        delete records;
    }

    public void execute(SchedulableContext bc) 
    {
        Database.executeBatch(new OldPreviewItemDeleter());
    }
    public void finish(Database.BatchableContext bc){}
}