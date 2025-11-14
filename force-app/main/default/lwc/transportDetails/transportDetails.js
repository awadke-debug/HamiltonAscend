import { LightningElement, api, track } from 'lwc';

import saveEvent from '@salesforce/apex/HamItineraryController.saveEvent';

import transportDetailsForm from './transportDetailsForm.html';
import transportDetailsDisplay from './transportDetailsDisplay.html';

import { showSearchAddresModal } from 'c/tripPlannerUtil';

export default class TransportDetails extends LightningElement {
    _showSearchAddresModal = showSearchAddresModal.bind(this);

    @api
    displayOnly;

    @track
    _transportDetails = {};

    isFlightOrTrain = false;

    @api
    get transportDetails() {
        return this._transportDetails;
    }

    set transportDetails(value) {
        this._transportDetails = Object.assign({}, value);
        this.isFlightOrTrain = value.mode === 'Flight' || value.mode === 'Train';
    }

    render() {
        return this.displayOnly == 'true' ? transportDetailsDisplay : transportDetailsForm;
    }

    handleInputChange(event) {
        this._transportDetails[event.currentTarget.name] = event.target.value;

        console.log('value', this._transportDetails[event.currentTarget.name]);
        

        if (event.currentTarget.name === 'mode') {
            this.isFlightOrTrain = event.target.value === 'Flight' || event.target.value === 'Train';
        }
    }

    @api
    async updateForm(tripDetailId) {
        
        return await saveEvent({
            eventDetail: {
                id: this._transportDetails.id,
                mode: this._transportDetails.mode,
                startDateTime: this._transportDetails.travelStartDate,
                endDateTime: this._transportDetails.travelEndDate,
                flightOrTrainNumber: this._transportDetails.mode === 'Flight' ? this._transportDetails.flightNumber : 
                    this._transportDetails.mode === 'Train' ? this._transportDetails.trainNumber : '',
                type: 'HAM_Transportation',
                tripDetailId: this._transportDetails.tripDetailId || tripDetailId,
                sourceAirport: this._transportDetails.sourceAddress,
                destinationAirport: this._transportDetails.destinationAddress,

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

    showSearchAddresModal(event){
        this._showSearchAddresModal('_transportDetails', event.target.dataset.addressProp);
    }

    get modeOptions() {
        return [
            { label: 'Car', value: 'Car' },
            { label: 'Flight', value: 'Flight' },
            { label: 'Bus', value: 'Bus' },
            { label: 'Train', value: 'Train' },

        ]
    }

    get mode() {
        return this._transportDetails.mode;
    }

    get travelStartDate() {
        return this._transportDetails.travelStartDate;
    }

    get travelEndDate() {
        return this._transportDetails.travelEndDate;
    }

    get flightNumber() {
        return this._transportDetails.flightNumber;
    }

    get trainNumber() {
        return this._transportDetails.trainNumber;
    }

    get sourceAddress() {
        return this._transportDetails.sourceAddress;
    }

    get destinationAddress() {
        return this._transportDetails.destinationAddress;
    }

    get disableSearchSource() {
        return this._transportDetails.sourceAddress == undefined || 
            this._transportDetails.sourceAddress == null || 
            this._transportDetails.sourceAddress == '';
    }

    get disableSearchDestination() {
        return this._transportDetails.destinationAddress == undefined || 
            this._transportDetails.destinationAddress == null || 
            this._transportDetails.destinationAddress == '';
    }

    // handleAddressChange(event) {
    //     this._transportDetails[`${event.currentTarget.name}Street`] = event.target.street;
    //     this._transportDetails[`${event.currentTarget.name}City`] = event.target.city;
    //     this._transportDetails[`${event.currentTarget.name}Country`] = event.target.country;
    //     this._transportDetails[`${event.currentTarget.name}Province`] = event.target.province;
    //     this._transportDetails[`${event.currentTarget.name}PostalCode`] = event.target.postalCode;
    // }

    // get sourceProvince() {
    //     return this._transportDetails.sourceProvince;
    // }

    // get sourceStreet() {
    //     return this._transportDetails.sourceStreet;
    // }

    // get sourceCity() {
    //     return this._transportDetails.sourceCity;
    // }

    // get sourceCountry() {
    //     return this._transportDetails.sourceCountry;
    // }

    // get sourceProvince() {
    //     return this._transportDetails.sourceProvince;
    // }

    // get sourcePostalCode() {
    //     return this._transportDetails.sourcePostalCode;
    // }

    // get destinationStreet() {
    //     return this._transportDetails.destinationStreet;
    // }

    // get destinationCity() {
    //     return this._transportDetails.destinationCity;
    // }

    // get destinationCountry() {
    //     return this._transportDetails.destinationCountry;
    // }

    // get destinationProvince() {
    //     return this._transportDetails.destinationProvince;
    // }

    // get destinationPostalCode() {
    //     return this._transportDetails.destinationPostalCode;
    // }
}