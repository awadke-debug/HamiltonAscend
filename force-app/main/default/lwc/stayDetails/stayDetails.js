import { api, LightningElement, track } from 'lwc';

import saveEvent from '@salesforce/apex/HamItineraryController.saveEvent';

import stayDetailsForm from './stayDetailsForm.html';
import stayDetailsDisplay from './stayDetailsDisplay.html';
import { showSearchAddresModal } from 'c/tripPlannerUtil';

export default class StayDetails extends LightningElement {
    _showSearchAddresModal = showSearchAddresModal.bind(this);

    @api
    displayOnly;

    @track
    _stayDetails = {};

    @api
    get stayDetails() {
        return this._stayDetails;
    }
    set stayDetails(value) {
        this._stayDetails = Object.assign({}, value);
    }

    render() {
        return this.displayOnly == 'true' ? stayDetailsDisplay : stayDetailsForm;
    }

    handleInputChange(event){
        this._stayDetails[event.currentTarget.name] = event.target.value;
    }

    @api
    async updateForm(tripDetailId) {
        return await saveEvent({
            eventDetail: {
                id: this._stayDetails.id,
                stayDetailsName: this._stayDetails.stayDetailsName,
                startDateTime: this._stayDetails.stayStartDate,
                endDateTime: this._stayDetails.stayEndDate,
                type: 'HAM_Accommodation',
                tripDetailId: this._stayDetails.tripDetailId || tripDetailId,
                address: this._stayDetails.stayAddress,
            }
        });
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

    showSearchAddresModal(event) {
        this._showSearchAddresModal('_stayDetails', event.target.dataset.addressProp);
    }

    get stayAddress() {
        return this._stayDetails.stayAddress;
    }

    get stayDetailsName() {
        return this._stayDetails.stayDetailsName;
    }

    get stayStartDate() {
        return this._stayDetails.stayStartDate;
    }

    get stayEndDate() {
        return this._stayDetails.stayEndDate;
    }

    get disableSearchAddress () {
        return this._stayDetails.stayAddress == undefined || this._stayDetails.stayAddress == null || this._stayDetails.stayAddress == '';
    }

    // handleAddressChange(event) {
    //     this._stayDetails.street = event.target.street;
    //     this._stayDetails.city = event.target.city;
    //     this._stayDetails.country = event.target.country;
    //     this._stayDetails.province = event.target.province;
    //     this._stayDetails.postalCode = event.target.postalCode;
    // }

    // get street() {
    //     return this._stayDetails.street;
    // }

    // get city() {
    //     return this._stayDetails.city;
    // }

    // get country() {
    //     return this._stayDetails.country;
    // }

    // get province() {
    //     return this._stayDetails.province;
    // }

    // get postalCode() {
    //     return this._stayDetails.postalCode;
    // }

}