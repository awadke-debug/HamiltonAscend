public class OldDeploymentItemDeleter implements Database.Batchable<sObject>,Schedulable{
    static Date today30 = Date.today().addDays(-30);

    public Database.QueryLocator start(Database.BatchableContext context)
    {
        return Database.getQueryLocator('Select Id from ucinn__RBK_Deployment_History__c where CreatedDate < :today30');
    }

    public void execute(Database.BatchableContext context, List<SObject> records)
    {
        delete records;
    }

    public void execute(SchedulableContext bc) 
    {
        Database.executeBatch(new OldDeploymentItemDeleter());
    }
    public void finish(Database.BatchableContext bc){}
}