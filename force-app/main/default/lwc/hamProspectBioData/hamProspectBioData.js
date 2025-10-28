import { LightningElement, api, track, wire } from 'lwc';

import searchProspectDetails from '@salesforce/apex/HAMProspectOverviewApexController.searchProspectDetails';
import getChildrenLinks from '@salesforce/apex/HAMProspectOverviewApexController.getChildrenLinks';
import { CurrentPageReference } from 'lightning/navigation';
import { NavigationMixin } from 'lightning/navigation';


export default class HamProspectBioData extends NavigationMixin(LightningElement) {
    @api contactrecord;
    @track activeSectionBio = 'Demographics';
    @track biorecordId= '';
    @api recordId;
    @api ascendProfileLink = '';
    @track chapterLink = '';
    @track prmLink = '';
    @track spouseLink = '';
    @track childrenLinks = [];

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

                    // Load children links if HAM_Children__c has value
                    if(this.contactrecord.HAM_Children__c){
                        this.loadChildrenLinks(this.contactrecord.HAM_Children__c);
                    }
                })
                .catch(error => {
                    console.error('Error fetching Prospect:', error);
                });
        }
    }

    // Load children links from Apex
    loadChildrenLinks(childrenString) {
        getChildrenLinks({ childrenString: childrenString })
            .then(result => {
                // Add isLast property for comma separation
                const children = result || [];
                this.childrenLinks = children.map((child, index) => ({
                    ...child,
                    isLast: index === children.length - 1
                }));
            })
            .catch(error => {
                console.error('Error loading children links:', error);
                this.childrenLinks = [];
            });
    }

    // Navigate to child's JEDI Overview page
    handleChildClick(event) {
        const childId = event.target.dataset.childId;
        if (childId) {
            this[NavigationMixin.GenerateUrl]({
                type: 'standard__navItemPage',
                attributes: {
                    apiName: 'JEDI_Overview'
                },
                state: {
                    c__recordId: childId
                }
            }).then(url => {
                window.open(url, '_blank', 'noopener,noreferrer');
            }).catch(error => {
                console.error('Navigation error:', error);
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