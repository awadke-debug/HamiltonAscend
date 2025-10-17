import { LightningElement, api, track, wire } from 'lwc';

import searchProspectDetails from '@salesforce/apex/HAMProspectOverviewApexController.searchProspectDetails';
import { CurrentPageReference } from 'lightning/navigation';


export default class HamProspectBioData extends LightningElement {
    @api contactrecord; 
    @track activeSectionBio = 'Demographics';
    @track biorecordId= '';
    @api recordId;
    @api ascendProfileLink = '';
    @track chapterLink = '';
    @track prmLink = '';
    @track spouseLink = '';

    connectedCallback() {
       
        if (this.recordId) {
            searchProspectDetails({ contactId: this.recordId})
                .then(result => {
                    this.contactrecord = result;
                    this.ascendProfileLink = '/' + this.recordId;
                    if(this.contactrecord.HAM_Preferred_Chapter_Lookup__c){
                        this.chapterLink = '/lightning/r/HAM_Chapter_Lookup__c/' + this.contactrecord.HAM_Preferred_Chapter_Lookup__c + '/view';
                    }
                    if(this.contactrecord.ucinn_ascendv2__PRM__c){
                        this.prmLink = '/lightning/r/User/' + this.contactrecord.ucinn_ascendv2__PRM__c + '/view';
                    }if(this.contactrecord.ucinn_ascendv2__Preferred_Spouse__c){
                        this.spouseLink = '/lightning/r/contact/' + this.contactrecord.ucinn_ascendv2__Preferred_Spouse__c + '/view';
                    }
                })
                .catch(error => {
                    console.error('Error fetching Prospect:', error);
                });
        }
    }

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            this.recordId = currentPageReference.state.c__recordId; // Or the name of your URL parameter
        }
    }


    handleSectionToggle(event) {
        const openedSections = event.detail.openSections;
        
        if (openedSections.includes('Demographics')) {
            this.activeSectionBio = 'Demographics'; // open it
        } else {
            this.activeSectionBio = ''; // close it
        }
    }
}