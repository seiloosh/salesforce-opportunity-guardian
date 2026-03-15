// Runs OpportunityCloseLostBatch on the 1st of every month at 2 AM.
// Schedule via: System.schedule('Monthly Close Lost Scheduler', '0 0 2 1 * ?', new OpportunityCloseLostScheduler());
// @author Vamsi Pappu
public with sharing class OpportunityCloseLostScheduler implements Schedulable {

    public void execute(SchedulableContext sc) {
        Database.executeBatch(new OpportunityCloseLostBatch(), 200);
    }

    public static String monthlyFirstAtTwoAmCron() {
        return '0 0 2 1 * ?';
    }
}
