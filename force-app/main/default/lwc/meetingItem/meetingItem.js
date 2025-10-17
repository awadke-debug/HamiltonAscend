import { LightningElement, api, track } from 'lwc';
import saveEvent from '@salesforce/apex/HamItineraryController.saveEvent';

import meetingItemForm from './meetingItemForm.html';
import meetingItemDisplay from './meetingItemDisplay.html';

export default class MeetingItem extends LightningElement {
    @api
    displayOnly;

    @track
    _meeting = {}
    
    @api
    get meeting() {
        return this._meeting;
    }
    set meeting(value) {
        this._meeting = Object.assign({}, value);
    }

    render() {
        if (this.displayOnly == 'true') {
            return meetingItemDisplay;
        } else {
            return meetingItemForm;

        }    
    }

    handleInputChange(event){
        this._meeting[event.currentTarget.name] = event.target.value;
    }

    @api
    async updateForm(tripDetailId) {
        return await saveEvent({
            eventDetail: {
                id: this._meeting.id,
                meetingTitle: this._meeting.title,
                meetingStatus: this._meeting.status,
                startDateTime: this._meeting.startDate,
                endDateTime: this._meeting.endDate,
                type: 'HAM_Meeting',
                tripDetailId: this._meeting.tripDetailId || tripDetailId,
                contactId: this._meeting.contactId,
                address: this.addressText,
            }
        })
    }

    @api
    validateForm() {
        const isValidSoFar = [
            ...this.template.querySelectorAll('lightning-input'),
        ].reduce((validSoFar, inputCmp) => {
            inputCmp.reportValidity();
            return validSoFar && inputCmp.checkValidity();
        }, true);

        return isValidSoFar;
    }

    get statusOptions() {
        return [
            { label: 'Planned', value: 'Planned' },
            { label: 'Scheduled', value: 'Scheduled' },
            { label: 'Rescheduled', value: 'Rescheduled' },
            { label: 'Cancelled', value: 'Cancelled' },
        ]
    }

    get addressText() {
        if (!this._meeting.address) {
            return this._meeting.hamAddress;
        }

        const addressElems = [this._meeting?.address?.Street, this._meeting?.address?.City, this._meeting?.address?.State, this._meeting?.address?.PostalCode, this._meeting?.address?.Country];
        return addressElems.filter(elem => elem).join(', ');
    }

    get city() {
        return this._meeting?.address?.City;
    }

    get country() {
        return this._meeting?.address?.Country;
    }

    get state() {
        return this._meeting?.address?.State;
    }

    get street() {
        return this._meeting?.address?.Street;
    }

    get postalCode() {
        return this._meeting?.address?.PostalCode;
    }

    get name() {
        return this._meeting.name;
    }

    get title(){
        return this._meeting.title;
    }

    get startDate(){
        return this._meeting.startDate;
    }

    get endDate(){
        return this._meeting.endDate;
    }

    get status(){
        return this._meeting.status;
    }

    get street() {
        return this._meeting.Street;
    }

    get city() {
        return this._meeting.City;
    }

    get country() {
        return this._meeting.Country;
    }

    get postalCode() {
        return this._meeting.PostalCode;
    }

    get province() {
        return this._meeting.State;
    }
}