import { LightningElement, api, track, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { getRecord, getFieldValue, updateRecord, createRecord } from 'lightning/uiRecordApi';

import TRIP_DETAIL_OBJ from '@salesforce/schema/HAM_Trip_Details__c';
import TRIP_ID_FIELD from '@salesforce/schema/HAM_Trip_Details__c.Id';
import TRIP_NAME_FIELD from '@salesforce/schema/HAM_Trip_Details__c.Name';
import TRIP_TITLE_FIELD from '@salesforce/schema/HAM_Trip_Details__c.HAM_Title__c';
import TRIP_START_DT_FIELD from '@salesforce/schema/HAM_Trip_Details__c.HAM_Start_Date_Time__c';
import TRIP_END_DT_FIELD from '@salesforce/schema/HAM_Trip_Details__c.HAM_End_Date_Time__c';
import TRIP_STATUS_FIELD from '@salesforce/schema/HAM_Trip_Details__c.HAM_Trip_Status__c';

import tripDetailsForm from './tripDetailsForm.html';
import tripDetailsDisplay from './tripDetailsDisplay.html';

export default class TripDetails extends LightningElement {
    @track
    _tripDetails = {};

    @api
    tripDetailId;

    @api
    displayOnly;

    @api
    get tripDetails() {
        return this._tripDetails;
    }
    set tripDetails(value) {
        this._tripDetails = value;
    }

    tripPickerMatchingInfo = {
        primaryField: { fieldPath: 'HAM_Title__c', mode: 'contains' },
        additionalFields: [{ fieldPath: 'Name' }],
    }

    tripPickerDisplayInfo = {
        primaryField: 'HAM_Title__c',
        additionalFields: ['HAM_Start_Date_Time__c', 'HAM_Trip_Status__c']
    };

    tripFetchResult;

    @wire(getRecord, { recordId: '$tripDetailId', fields: [TRIP_NAME_FIELD, TRIP_TITLE_FIELD, TRIP_START_DT_FIELD, TRIP_END_DT_FIELD] })
    wiredTripDetail(result) {
        this.tripFetchResult = result;
        const { data, error } = result;
        if (data) {
            this._tripDetails.tripDetailsName = getFieldValue(data, TRIP_TITLE_FIELD);
            this._tripDetails.tripDetailsStartDate = getFieldValue(data, TRIP_START_DT_FIELD);
            this._tripDetails.tripDetailsEndDate = getFieldValue(data, TRIP_END_DT_FIELD);
        } else if (error) {
            console.error('error', JSON.stringify(error));
        }
    }

    updateTripDetail(fields) {
        const recordInput = { fields };
        return updateRecord(recordInput);
    }

    createTripDetail(fields) {
        const recordInput = { apiName: TRIP_DETAIL_OBJ.objectApiName, fields };
        return createRecord(recordInput);
    }

    @api
    saveTripDetail() {
        const fields = {};

        fields[TRIP_TITLE_FIELD.fieldApiName] = this._tripDetails.tripDetailsName;
        fields[TRIP_START_DT_FIELD.fieldApiName] = this._tripDetails.tripDetailsStartDate;
        fields[TRIP_END_DT_FIELD.fieldApiName] = this._tripDetails.tripDetailsEndDate;
        
        if (this.tripDetailId) {
            fields[TRIP_ID_FIELD.fieldApiName] = this.tripDetailId;
            return this.updateTripDetail(fields);
        } else {
            return this.createTripDetail(fields);
        }
    }

    render() {
        return this.displayOnly == 'true' ? tripDetailsDisplay : tripDetailsForm;
    }

    handleInputChange(event){
        this._tripDetails[event.currentTarget.name] = event.target.value;
    }

    @api
    tripDetailChange(tripDetailId){
        this.tripDetailId = tripDetailId;

        this.dispatchEvent(new CustomEvent('tripdetailchange', {
            detail: { 
                tripDetailId: tripDetailId, 
            }
        }));

        if (!tripDetailId) {
            this._tripDetails = {};
        }
    }
            
    handleRecordChange(event) {
        this.tripDetailChange(event.detail.recordId);
    }

    get tripDetailsName() {
        return this._tripDetails.tripDetailsName;
    }

    get tripDetailsStartDate() {
        return this._tripDetails.tripDetailsStartDate;
    }

    get tripDetailsEndDate() {
        return this._tripDetails.tripDetailsEndDate;
    }
}