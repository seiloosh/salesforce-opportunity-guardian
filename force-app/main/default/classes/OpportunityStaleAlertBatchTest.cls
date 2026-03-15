// Tests for OpportunityStaleAlertBatch.
// @author Vamsi Pappu
@IsTest
private class OpportunityStaleAlertBatchTest {

    @IsTest
    static void createsAlertsForStaleOpportunities() {
        Opportunity opp = new Opportunity(
            Name = 'Stale Opp',
            StageName = 'Prospecting',
            CloseDate = System.today().addMonths(1)
        );
        insert opp;

        List<Opportunity> scope = [
            SELECT Id, OwnerId, LastModifiedDate FROM Opportunity WHERE Id = :opp.Id
        ];

        Test.startTest();
        OpportunityStaleAlertBatch batch = new OpportunityStaleAlertBatch();
        batch.execute(null, scope);
        Test.stopTest();

        List<Opportunity_Stale_Alert__c> alerts = [
            SELECT Id, Opportunity__c, Status__c, Alert_Date__c, Projected_Auto_Close_Date__c
            FROM Opportunity_Stale_Alert__c
            WHERE Opportunity__c = :opp.Id
        ];
        System.assertEquals(1, alerts.size(), 'Should create exactly one alert');
        System.assertEquals('Pending', alerts[0].Status__c, 'Alert should be Pending');
        System.assertEquals(System.today(), alerts[0].Alert_Date__c, 'Alert date should be today');
        System.assertNotEquals(null, alerts[0].Projected_Auto_Close_Date__c, 'Projected close date should be set');
    }

    @IsTest
    static void doesNotCreateDuplicateAlerts() {
        Opportunity opp = new Opportunity(
            Name = 'Already Alerted Opp',
            StageName = 'Prospecting',
            CloseDate = System.today().addMonths(1)
        );
        insert opp;

        insert new Opportunity_Stale_Alert__c(
            Opportunity__c = opp.Id,
            Alert_Date__c = System.today().addDays(-7),
            Status__c = 'Pending',
            Projected_Auto_Close_Date__c = System.today().addMonths(2)
        );

        List<Opportunity> scope = [
            SELECT Id, OwnerId, LastModifiedDate FROM Opportunity WHERE Id = :opp.Id
        ];

        Test.startTest();
        OpportunityStaleAlertBatch batch = new OpportunityStaleAlertBatch();
        batch.execute(null, scope);
        Test.stopTest();

        Integer alertCount = [
            SELECT COUNT()
            FROM Opportunity_Stale_Alert__c
            WHERE Opportunity__c = :opp.Id AND Status__c = 'Pending'
        ];
        System.assertEquals(1, alertCount, 'Should not create duplicate Pending alerts');
    }

    @IsTest
    static void skipsFreshOpportunities() {
        Opportunity opp = new Opportunity(
            Name = 'Fresh Opp',
            StageName = 'Prospecting',
            CloseDate = System.today().addMonths(1)
        );
        insert opp;

        Test.startTest();
        Database.executeBatch(new OpportunityStaleAlertBatch(), 200);
        Test.stopTest();

        Integer alertCount = [
            SELECT COUNT()
            FROM Opportunity_Stale_Alert__c
            WHERE Opportunity__c = :opp.Id
        ];
        System.assertEquals(0, alertCount, 'Fresh Opportunity should not receive an alert');
    }

    @IsTest
    static void schedulerExecutesBatchSuccessfully() {
        Test.startTest();
        String jobId = System.schedule(
            'Test Stale Alert Scheduler',
            OpportunityStaleAlertScheduler.weeklyMondayEightAmCron(),
            new OpportunityStaleAlertScheduler()
        );
        Test.stopTest();

        List<CronTrigger> jobs = [
            SELECT Id, State FROM CronTrigger WHERE Id = :jobId
        ];
        System.assertEquals(1, jobs.size(), 'Scheduled job should exist');
    }
}
