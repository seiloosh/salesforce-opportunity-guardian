# Salesforce Opportunity Guardian

Every sales team has the same problem — Opportunities sit in the pipeline for months with no updates. Reps forget about them, managers can't tell what's real and what's dead, and forecasting becomes guesswork.

This project fixes that. It watches for stale Opportunities, warns reps before anything happens, and automatically cleans up the ones nobody cares about.

## The Problem

An open Opportunity that hasn't been touched in 6 months is almost certainly dead. But in most orgs, these just pile up forever because nobody goes through and closes them manually. Meanwhile, reps get blindsided when a batch job suddenly closes their deals without warning.

## How I Solved It

I built two systems that work together — an early warning system and an auto-cleanup job.

**The alert system** runs every Monday morning. It looks for open Opps that haven't been modified in 5+ months and creates an alert record for each one. When a rep opens that Opportunity, they see a warning banner at the top of the page with two buttons:

- **Keep Alive** — "This deal is still active, don't close it." Updates the record so the timer resets.
- **Acknowledge** — "I see the warning, I'll deal with it." Dismisses the alert but doesn't reset the timer.

**The close batch** runs on the 1st of every month. It finds anything still untouched after 6 months and sets it to Closed Lost. If there were any pending alerts for those Opps, they get marked as Auto_Closed too.

So reps get a full month of warnings before anything actually closes. No surprises.

## Project Structure

```
force-app/
├── classes/
│   ├── OpportunityStaleAlertBatch          # weekly — finds stale Opps, creates alerts
│   ├── OpportunityStaleAlertScheduler      # runs the alert batch every Monday 8 AM
│   ├── OpportunityStaleAlertController     # backs the LWC — fetches alerts, handles buttons
│   ├── OpportunityCloseLostBatch           # monthly — closes 6-month stale Opps
│   ├── OpportunityCloseLostScheduler       # runs the close batch on the 1st at 2 AM
│   └── test classes for all of the above
├── lwc/
│   └── opportunityStaleAlerts/             # the warning banner component
├── objects/
│   ├── Opportunity_Stale_Alert__c/         # custom object that tracks each alert
│   └── Opportunity/
│       └── Stale_Alert_Acknowledged_Date__c
├── tabs/
│   └── Opportunity_Stale_Alert__c
└── triggers/
    └── Contact_SetNomadOnSystemFirstName   # separate data hygiene trigger
```

The custom object `Opportunity_Stale_Alert__c` is pretty simple — it has a lookup to the Opportunity, the date the alert was created, a status picklist (Pending / Acknowledged / Auto Closed), and a projected auto-close date so the rep knows exactly when the clock runs out.

## Getting Started

You'll need the Salesforce CLI and a target org (scratch org or sandbox).

**Deploy:**

```bash
sf project deploy start --source-dir force-app --test-level RunLocalTests
```

**Schedule the jobs** (run this as anonymous Apex):

```apex
System.schedule('Weekly Stale Opportunity Alerts', '0 0 8 ? * MON', new OpportunityStaleAlertScheduler());
System.schedule('Monthly Close Lost Scheduler', '0 0 2 1 * ?', new OpportunityCloseLostScheduler());
```

**Add the LWC to the page:**

Open any Opportunity > gear icon > Edit Page > drag "Opportunity Stale Alerts" to the top of the layout > Save.

## Tests

12 tests, all passing. Coverage is 94-100% across all classes.

The tests cover the important stuff — alerts actually get created for stale Opps, duplicates are prevented, fresh Opps are skipped, Keep Alive resets the timer, Acknowledge only dismisses the alert, and the close batch properly flips alert statuses when it closes an Opp.

## Security

All classes run `with sharing` so users only see records they have access to. Batch queries use `WITH SECURITY_ENFORCED` for field-level security. DML is partial-success so one bad record doesn't kill the whole batch.

## Author

Vamsi Pappu
