import { LightningElement, api, wire } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { refreshApex } from "@salesforce/apex";
import getActiveAlerts from "@salesforce/apex/OpportunityStaleAlertController.getActiveAlerts";
import keepAlive from "@salesforce/apex/OpportunityStaleAlertController.keepAlive";
import acknowledgeAlert from "@salesforce/apex/OpportunityStaleAlertController.acknowledgeAlert";

export default class OpportunityStaleAlerts extends LightningElement {
    @api recordId;

    alerts;
    wiredAlertsResult;
    isProcessing = false;

    @wire(getActiveAlerts, { opportunityId: "$recordId" })
    wiredAlerts(result) {
        this.wiredAlertsResult = result;
        if (result.data) {
            this.alerts = result.data;
        }
    }

    get hasAlerts() {
        return this.alerts && this.alerts.length > 0;
    }

    get primaryAlert() {
        return this.hasAlerts ? this.alerts[0] : null;
    }

    get alertDate() {
        return this.primaryAlert
            ? this.primaryAlert.Alert_Date__c
            : null;
    }

    get opportunityLastModifiedDate() {
        return this.primaryAlert?.Opportunity__r?.LastModifiedDate ?? null;
    }

    get projectedCloseDate() {
        return this.primaryAlert
            ? this.primaryAlert.Projected_Auto_Close_Date__c
            : null;
    }

    async handleKeepAlive() {
        this.isProcessing = true;
        try {
            await keepAlive({
                opportunityId: this.recordId,
                alertId: this.primaryAlert.Id,
            });
            this.dispatchEvent(
                new ShowToastEvent({
                    title: "Success",
                    message:
                        "Opportunity marked as active. The auto-closure timer has been reset.",
                    variant: "success",
                }),
            );
            await refreshApex(this.wiredAlertsResult);
        } catch (error) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: "Error",
                    message:
                        error.body?.message || "An unexpected error occurred.",
                    variant: "error",
                }),
            );
        } finally {
            this.isProcessing = false;
        }
    }

    async handleAcknowledge() {
        this.isProcessing = true;
        try {
            await acknowledgeAlert({
                alertId: this.primaryAlert.Id,
            });
            this.dispatchEvent(
                new ShowToastEvent({
                    title: "Alert Acknowledged",
                    message:
                        "The alert has been acknowledged. Please review this opportunity.",
                    variant: "info",
                }),
            );
            await refreshApex(this.wiredAlertsResult);
        } catch (error) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: "Error",
                    message:
                        error.body?.message || "An unexpected error occurred.",
                    variant: "error",
                }),
            );
        } finally {
            this.isProcessing = false;
        }
    }
}
