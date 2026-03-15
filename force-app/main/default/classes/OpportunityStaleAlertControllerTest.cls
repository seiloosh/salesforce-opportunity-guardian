// Tests for OpportunityStaleAlertController.
// @author Vamsi Pappu
@IsTest
private class OpportunityStaleAlertControllerTest {

    private static Opportunity createTestOpportunity() {
        Opportunity opp = new Opportunity(
            Name = 'Controller Test Opp',
            StageName = 'Prospecting',
            CloseDate = System.today().addMonths(1)
        );
        insert opp;
        return opp;
    }

    private static Opportunity_Stale_Alert__c createTestAlert(Id oppId) {
        Opportunity_Stale_Alert__c alert = new Opportunity_Stale_Alert__c(
            Opportunity__c = oppId,
            Alert_Date__c = System.today(),
            Status__c = 'Pending',
            Projected_Auto_Close_Date__c = System.today().addMonths(1)
        );
        insert alert;
        return alert;
    }

    @IsTest
    static void getActiveAlertsReturnsPendingAlerts() {
        Opportunity opp = createTestOpportunity();
        Opportunity_Stale_Alert__c alert = createTestAlert(opp.Id);

        Test.startTest();
        List<Opportunity_Stale_Alert__c> results = OpportunityStaleAlertController.getActiveAlerts(opp.Id);
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Should return one Pending alert');
        System.assertEquals(alert.Id, results[0].Id, 'Should return the correct alert');
        System.assertEquals('Pending', results[0].Status__c, 'Alert status should be Pending');
    }

    @IsTest
    static void getActiveAlertsReturnsEmptyForNoAlerts() {
        Opportunity opp = createTestOpportunity();

        Test.startTest();
        List<Opportunity_Stale_Alert__c> results = OpportunityStaleAlertController.getActiveAlerts(opp.Id);
        Test.stopTest();

        System.assertEquals(0, results.size(), 'Should return no alerts for clean Opportunity');
    }

    @IsTest
    static void getActiveAlertsExcludesAcknowledgedAlerts() {
        Opportunity opp = createTestOpportunity();
        Opportunity_Stale_Alert__c alert = createTestAlert(opp.Id);
        alert.Status__c = 'Acknowledged';
        update alert;

        Test.startTest();
        List<Opportunity_Stale_Alert__c> results = OpportunityStaleAlertController.getActiveAlerts(opp.Id);
        Test.stopTest();

        System.assertEquals(0, results.size(), 'Should not return Acknowledged alerts');
    }

    @IsTest
    static void keepAliveUpdatesOpportunityAndAcknowledgesAlert() {
        Opportunity opp = createTestOpportunity();
        Opportunity_Stale_Alert__c alert = createTestAlert(opp.Id);

        Test.startTest();
        OpportunityStaleAlertController.keepAlive(opp.Id, alert.Id);
        Test.stopTest();

        Opportunity updatedOpp = [
            SELECT Stale_Alert_Acknowledged_Date__c FROM Opportunity WHERE Id = :opp.Id
        ];
        System.assertNotEquals(
            null,
            updatedOpp.Stale_Alert_Acknowledged_Date__c,
            'Stale_Alert_Acknowledged_Date__c should be set'
        );

        Opportunity_Stale_Alert__c updatedAlert = [
            SELECT Status__c FROM Opportunity_Stale_Alert__c WHERE Id = :alert.Id
        ];
        System.assertEquals('Acknowledged', updatedAlert.Status__c, 'Alert should be Acknowledged');
    }

    @IsTest
    static void acknowledgeAlertSetsStatusToAcknowledged() {
        Opportunity opp = createTestOpportunity();
        Opportunity_Stale_Alert__c alert = createTestAlert(opp.Id);

        Test.startTest();
        OpportunityStaleAlertController.acknowledgeAlert(alert.Id);
        Test.stopTest();

        Opportunity_Stale_Alert__c updatedAlert = [
            SELECT Status__c FROM Opportunity_Stale_Alert__c WHERE Id = :alert.Id
        ];
        System.assertEquals('Acknowledged', updatedAlert.Status__c, 'Alert should be Acknowledged');

        Opportunity unchangedOpp = [
            SELECT Stale_Alert_Acknowledged_Date__c FROM Opportunity WHERE Id = :opp.Id
        ];
        System.assertEquals(
            null,
            unchangedOpp.Stale_Alert_Acknowledged_Date__c,
            'Opportunity should not be touched by Acknowledge action'
        );
    }
}
