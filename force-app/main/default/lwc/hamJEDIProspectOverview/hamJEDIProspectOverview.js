import { LightningElement, api, track, wire } from 'lwc';
import searchProspectDetails from '@salesforce/apex/HAMProspectOverviewApexController.searchProspectDetails';
import searchProspectGivingDetails from '@salesforce/apex/HAMProspectOverviewApexController.searchProspectGivingDetails';

import { CurrentPageReference } from 'lightning/navigation';

export default class HamJEDIProspectOverview extends LightningElement {
    @api recordId;
    @track prospectData;
    @track givingData;

    connectedCallback() {
        console.log('Inside the method call -------'+this.recordId);
        if (this.recordId) {
            console.log('Record Id ---------'+this.recordId);
            searchProspectDetails({ contactId: this.recordId})
                .then(result => {
                    this.prospectData = result;
                    console.log('Record ---------'+this.prospectData);

                })
                .catch(error => {
                    console.error('Error fetching Prospect:', error);
                });
            searchProspectGivingDetails({ contactId: this.recordId})
            .then(result => {
                    this.givingData = result;
                    console.log('Record ---------'+this.givingData);

                })
                .catch(error => {
                    console.error('Error fetching Giving details:', error);
                });
        }
    }

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        console.log('URL parameter----'+currentPageReference);
        if (currentPageReference) {
            console.log('URL parameter----'+currentPageReference.state.c__recordId);
            console.log('URL parameter--State--'+currentPageReference.state);
            this.recordId = currentPageReference.state.c__recordId; // Or the name of your URL parameter
            console.log('Record ID:', this.recordId);
        }
    }
}