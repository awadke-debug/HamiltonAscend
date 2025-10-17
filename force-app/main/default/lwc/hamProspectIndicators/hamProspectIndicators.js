import { LightningElement, api, wire, track } from 'lwc';
import searchIndicatorDetails from '@salesforce/apex/HAMProspectOverviewApexController.searchIndicatorDetails';
import { CurrentPageReference } from 'lightning/navigation';


export default class HamProspectIndicators extends LightningElement {
    @api showDoNotContact = false;
    @api showDeceased = false;
    @api recordId;
    @track loading = false; // Spinner control
    
    @wire(CurrentPageReference)
            getStateParameters(currentPageReference) {
                console.log('Inside Education-----');
                if (currentPageReference?.state?.c__recordId) {
                    this.recordId = currentPageReference.state.c__recordId;
                    console.log('Record ID:', this.recordId);
        
                    this.loading = true; // Start spinner
                    searchIndicatorDetails({ contactId: this.recordId })
                        .then(result => {
                            console.log('Apex method Returend');
                            
                            this.showDoNotContact = result.isDoNotContact;
                            this.showDeceased = result.isDeceased;
                            console.log('DNC-----',this.showDoNotContact);
                            console.log('Dead-----',this.showDeceased);
                            
                        })
                        .catch(error => {
                            console.error('Error fetching Prospect:', error);
                        })
                        .finally(() => {
                            this.loading = false; // Stop spinner
                        });
                }
            }
}