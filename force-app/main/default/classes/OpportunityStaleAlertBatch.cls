// Finds open Opps not modified in 5+ months and creates alert records so reps get warned before auto-closure.
// Runs weekly via OpportunityStaleAlertScheduler.
// @author Vamsi Pappu
public with sharing class OpportunityStaleAlertBatch implements Database.Batchable<SObject>, Database.Stateful {

    public Date testCutoffOverride;

    public Database.QueryLocator start(Database.BatchableContext bc) {
        Date cutoff = testCutoffOverride != null ? testCutoffOverride : System.today().addMonths(-5);

        String soql = 'SELECT Id, OwnerId, LastModifiedDate FROM Opportunity ' +
                      'WHERE IsClosed = false AND LastModifiedDate < :cutoff ' +
                      'WITH SECURITY_ENFORCED';

        return Database.getQueryLocator(soql);
    }

    public void execute(Database.BatchableContext bc, List<Opportunity> scope) {
        if (scope == null || scope.isEmpty()) {
            return;
        }

        Set<Id> oppIds = new Set<Id>();
        for (Opportunity opp : scope) {
            oppIds.add(opp.Id);
        }

        // Skip Opps that already have a Pending alert
        Set<Id> oppsWithExistingAlerts = new Set<Id>();
        for (Opportunity_Stale_Alert__c alert : [
            SELECT Opportunity__c FROM Opportunity_Stale_Alert__c
            WHERE Opportunity__c IN :oppIds AND Status__c = 'Pending'
        ]) {
            oppsWithExistingAlerts.add(alert.Opportunity__c);
        }

        List<Opportunity_Stale_Alert__c> newAlerts = new List<Opportunity_Stale_Alert__c>();

        for (Opportunity opp : scope) {
            if (!oppsWithExistingAlerts.contains(opp.Id)) {
                // Projected close = 1st of the month after LastModifiedDate + 6 months
                // If that date already passed, bump to 1st of next month
                Date lastMod = opp.LastModifiedDate.date();
                Date projectedClose = lastMod.addMonths(6).toStartOfMonth().addMonths(1);
                Date nextBatchRun = System.today().toStartOfMonth().addMonths(1);
                if (projectedClose < nextBatchRun) {
                    projectedClose = nextBatchRun;
                }

                newAlerts.add(new Opportunity_Stale_Alert__c(
                    Opportunity__c = opp.Id,
                    Alert_Date__c = System.today(),
                    Status__c = 'Pending',
                    Projected_Auto_Close_Date__c = projectedClose,
                    OwnerId = opp.OwnerId
                ));
            }
        }

        if (!newAlerts.isEmpty()) {
            Database.insert(newAlerts, false);
        }
    }

    public void finish(Database.BatchableContext bc) {
    }
}
