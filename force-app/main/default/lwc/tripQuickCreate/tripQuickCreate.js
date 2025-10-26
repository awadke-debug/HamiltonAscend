import { LightningElement } from 'lwc';
import LightningConfirm from 'lightning/confirm';

import TITLE_FIELD from '@salesforce/schema/HAM_Trip_Details__c.HAM_Title__c';
import START_DATE_FIELD from '@salesforce/schema/HAM_Trip_Details__c.HAM_Start_Date_Time__c';
import END_DATE_FIELD from '@salesforce/schema/HAM_Trip_Details__c.HAM_End_Date_Time__c';
import STATUS_FIELD from '@salesforce/schema/HAM_Trip_Details__c.HAM_Trip_Status__c';

export default class TripQuickCreate extends LightningElement {
    titleField = TITLE_FIELD;
    startDateField = START_DATE_FIELD;
    endDateField = END_DATE_FIELD;
    statusField = STATUS_FIELD;

    handleSuccess(event) {
        const inputFields = this.template.querySelectorAll('lightning-input-field');

        if (inputFields) {
            inputFields.forEach(field => {
                field.reset();
            });
        }

        LightningConfirm.open({
            message: 'Continue working on trip details?',
            label: 'Trip created',
            theme: 'success'
        }).then(result => {
            this.dispatchEvent(new CustomEvent('tripcreated', {
                detail: { tripId: event.detail.id, confirmResult: result }
            }));
        })
        
        
    }
}