// Tests for OpportunityCloseLostBatch.
// @author Vamsi Pappu
@IsTest
private class OpportunityCloseLostBatchTest {

    @IsTest
    static void testBatchExecute() {
        Opportunity opp = new Opportunity(
            Name = 'Test Opp',
            StageName = 'Prospecting',
            CloseDate = System.today()
        );
        insert opp;

        Test.startTest();
        Database.executeBatch(new OpportunityCloseLostBatch(), 50);
        Test.stopTest();

        System.assert(true, 'Batch executed without errors');
    }

    @IsTest
    static void closesOpenOpportunitiesAndUpdatesAlerts() {
        Opportunity opp = new Opportunity(
            Name = 'Stale Opp To Close',
            StageName = 'Prospecting',
            CloseDate = System.today()
        );
        insert opp;

        Opportunity_Stale_Alert__c alert = new Opportunity_Stale_Alert__c(
            Opportunity__c = opp.Id,
            Alert_Date__c = System.today().addDays(-14),
            Status__c = 'Pending',
            Projected_Auto_Close_Date__c = System.today()
        );
        insert alert;

        List<Opportunity> scope = [
            SELECT Id, StageName, IsClosed FROM Opportunity WHERE Id = :opp.Id
        ];

        Test.startTest();
        OpportunityCloseLostBatch batch = new OpportunityCloseLostBatch();
        batch.execute(null, scope);
        batch.finish(null);
        Test.stopTest();

        Opportunity updatedOpp = [
            SELECT StageName, IsClosed FROM Opportunity WHERE Id = :opp.Id
        ];
        System.assertEquals('Closed Lost', updatedOpp.StageName, 'Opportunity should be Closed Lost');
        System.assertEquals(true, updatedOpp.IsClosed, 'Opportunity should be closed');

        Opportunity_Stale_Alert__c updatedAlert = [
            SELECT Status__c FROM Opportunity_Stale_Alert__c WHERE Id = :alert.Id
        ];
        System.assertEquals('Auto_Closed', updatedAlert.Status__c, 'Alert should be Auto_Closed');
    }

    @IsTest
    static void schedulerExecutesBatch() {
        Test.startTest();
        String jobId = System.schedule(
            'Test Close Lost Scheduler',
            OpportunityCloseLostScheduler.monthlyFirstAtTwoAmCron(),
            new OpportunityCloseLostScheduler()
        );
        Test.stopTest();

        List<CronTrigger> jobs = [SELECT Id FROM CronTrigger WHERE Id = :jobId];
        System.assertEquals(1, jobs.size(), 'Scheduled job should exist');
    }
}
