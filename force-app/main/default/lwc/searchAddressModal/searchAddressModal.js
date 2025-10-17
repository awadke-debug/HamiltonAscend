import { api, LightningElement, wire } from 'lwc';
import LightningModal from 'lightning/modal';

import searchAddress from '@salesforce/apex/HamItineraryController.searchAddress';

export default class SearchAddressModal extends LightningModal {
    @api
    searchString;

    addressOptions;
    
    addressOptionsLoading = true;

    @wire(searchAddress, { searchString: '$searchString' })
    fetchAddressOptions({data, error}){
        if (data) {
            this.addressOptions = data.map((add, idx) => ({
                value: add,
                idx: idx
            }));
            
            this.addressOptionsLoading = false;
        } else if (error) {
            this.addressOptionsLoading = false;
        }
    }

    handleAddressOptionClick(event) {
        const { address } = event.target.dataset;

        this.close(address);
    }

    get displayAddressOptions() {
        return this.addressOptions && this.addressOptions.length > 0;
    }

}