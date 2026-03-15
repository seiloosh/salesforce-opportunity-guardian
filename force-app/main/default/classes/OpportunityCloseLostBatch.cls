// Marks stale open Opportunities as Closed Lost.
// Picks up Opps where IsClosed = false and LastModifiedDate is older than 6 months.
// Also flips any related Pending stale alerts to Auto_Closed.
// Runs monthly via OpportunityCloseLostScheduler.
// @author Vamsi Pappu
public with sharing class OpportunityCloseLostBatch implements Database.Batchable<SObject>, Database.Stateful {

    public enum STAGE_VALUES {
        CLOSED_LOST
    }

    private static final Integer BATCH_SIZE = 200;

    public Database.QueryLocator start(Database.BatchableContext bc) {
        Date cutoff = System.today().addMonths(-6);

        String soql = 'SELECT Id, StageName FROM Opportunity ' +
                      'WHERE IsClosed = false AND LastModifiedDate < :cutoff ' +
                      'WITH SECURITY_ENFORCED';

        return Database.getQueryLocator(soql);
    }

    public void execute(Database.BatchableContext bc, List<Opportunity> scope) {
        if (scope == null || scope.isEmpty()) {
            return;
        }

        for (Opportunity o : scope) {
            if (o.IsClosed == false) {
                o.StageName = 'Closed Lost';
            }
        }

        Database.SaveResult[] results = Database.update(scope, false);

        // Figure out which Opps actually got closed so we can update their alerts
        Set<Id> closedOppIds = new Set<Id>();
        for (Integer i = 0; i < results.size(); i++) {
            if (results[i].isSuccess()) {
                closedOppIds.add(results[i].getId());
            }
        }

        if (!closedOppIds.isEmpty()) {
            List<Opportunity_Stale_Alert__c> alertsToClose = [
                SELECT Id, Status__c FROM Opportunity_Stale_Alert__c
                WHERE Opportunity__c IN :closedOppIds AND Status__c = 'Pending'
            ];
            for (Opportunity_Stale_Alert__c alert : alertsToClose) {
                alert.Status__c = 'Auto_Closed';
            }
            if (!alertsToClose.isEmpty()) {
                Database.update(alertsToClose, false);
            }
        }
    }

    public void finish(Database.BatchableContext bc) {
    }
}
