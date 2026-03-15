// Runs OpportunityStaleAlertBatch every Monday at 8 AM.
// Schedule via: System.schedule('Weekly Stale Opportunity Alerts', '0 0 8 ? * MON', new OpportunityStaleAlertScheduler());
// @author Vamsi Pappu
public with sharing class OpportunityStaleAlertScheduler implements Schedulable {

    public void execute(SchedulableContext sc) {
        Database.executeBatch(new OpportunityStaleAlertBatch(), 200);
    }

    public static String weeklyMondayEightAmCron() {
        return '0 0 8 ? * MON';
    }
}
