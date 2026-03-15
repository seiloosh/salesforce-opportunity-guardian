// Apex controller for the opportunityStaleAlerts LWC.
// Handles fetching active alerts and user actions (Keep Alive, Acknowledge).
// @author Vamsi Pappu
public with sharing class OpportunityStaleAlertController {

    @AuraEnabled(cacheable=true)
    public static List<Opportunity_Stale_Alert__c> getActiveAlerts(Id opportunityId) {
        return [
            SELECT Id, Alert_Date__c, Status__c, Projected_Auto_Close_Date__c,
                   Opportunity__r.LastModifiedDate
            FROM Opportunity_Stale_Alert__c
            WHERE Opportunity__c = :opportunityId
              AND Status__c = 'Pending'
            ORDER BY Alert_Date__c DESC
            LIMIT 5
        ];
    }

    // Updates Stale_Alert_Acknowledged_Date__c on the Opp (resets the auto-closure timer)
    // and marks the alert as Acknowledged.
    @AuraEnabled
    public static void keepAlive(Id opportunityId, Id alertId) {
        Opportunity opp = [
            SELECT Id, Stale_Alert_Acknowledged_Date__c
            FROM Opportunity
            WHERE Id = :opportunityId
            LIMIT 1
        ];
        opp.Stale_Alert_Acknowledged_Date__c = System.now();
        update opp;

        Opportunity_Stale_Alert__c alert = [
            SELECT Id, Status__c
            FROM Opportunity_Stale_Alert__c
            WHERE Id = :alertId
            LIMIT 1
        ];
        alert.Status__c = 'Acknowledged';
        update alert;
    }

    // Marks the alert as Acknowledged without resetting the timer.
    // The rep sees the warning but the Opp stays on track for closure.
    @AuraEnabled
    public static void acknowledgeAlert(Id alertId) {
        Opportunity_Stale_Alert__c alert = [
            SELECT Id, Status__c
            FROM Opportunity_Stale_Alert__c
            WHERE Id = :alertId
            LIMIT 1
        ];
        alert.Status__c = 'Acknowledged';
        update alert;
    }
}
