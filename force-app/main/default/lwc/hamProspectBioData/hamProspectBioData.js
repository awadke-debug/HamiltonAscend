import { LightningElement, api, track, wire } from 'lwc';

import searchProspectDetails from '@salesforce/apex/HAMProspectOverviewApexController.searchProspectDetails';
import getChildrenFromRelationships from '@salesforce/apex/HAMProspectOverviewApexController.getChildrenFromRelationships';
import getParentsFromRelationships from '@salesforce/apex/HAMProspectOverviewApexController.getParentsFromRelationships';
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
    @track parentsLinks = [];

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

                    // Load children from Relationship object
                    this.loadChildrenFromRelationships(this.recordId);

                    // Load parents from Relationship object
                    this.loadParentsFromRelationships(this.recordId);
                })
                .catch(error => {
                    console.error('Error fetching Prospect:', error);
                });
        }
    }

    /**
     * Loads children contacts from the Relationship object via Apex
     *
     * @param {String} contactId - The ID of the parent contact
     *
     * This method:
     * - Calls getChildrenFromRelationships Apex method
     * - Maps results and adds isLast property for comma separation in template
     * - Populates childrenLinks array with {displayName, contactId, isLast} objects
     */
    loadChildrenFromRelationships(contactId) {
        getChildrenFromRelationships({ contactId: contactId })
            .then(result => {
                // Add isLast property for comma separation
                const children = result || [];
                this.childrenLinks = children.map((child, index) => ({
                    ...child,
                    isLast: index === children.length - 1
                }));
            })
            .catch(error => {
                console.error('Error loading children from relationships:', error);
                this.childrenLinks = [];
            });
    }

    /**
     * Loads parent contacts from the Relationship object via Apex
     *
     * @param {String} contactId - The ID of the child contact
     *
     * This method:
     * - Calls getParentsFromRelationships Apex method
     * - Maps results and adds isLast property for comma separation in template
     * - Populates parentsLinks array with {displayName, contactId, isLast} objects
     */
    loadParentsFromRelationships(contactId) {
        getParentsFromRelationships({ contactId: contactId })
            .then(result => {
                // Add isLast property for comma separation
                const parents = result || [];
                this.parentsLinks = parents.map((parent, index) => ({
                    ...parent,
                    isLast: index === parents.length - 1
                }));
            })
            .catch(error => {
                console.error('Error loading parents from relationships:', error);
                this.parentsLinks = [];
            });
    }

    /**
     * Handles click event on child name link
     *
     * @param {Event} event - The click event containing data-child-id attribute
     *
     * Navigation Logic:
     * - Extracts child contact ID from data attribute
     * - Generates URL to JEDI_Overview custom tab with c__recordId state parameter
     * - Opens in new browser tab with security flags (noopener, noreferrer)
     */
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

    /**
     * Handles click event on parent name link
     *
     * @param {Event} event - The click event containing data-parent-id attribute
     *
     * Navigation Logic:
     * - Extracts parent contact ID from data attribute
     * - Generates URL to JEDI_Overview custom tab with c__recordId state parameter
     * - Opens in new browser tab with security flags (noopener, noreferrer)
     */
    handleParentClick(event) {
        const parentId = event.target.dataset.parentId;
        if (parentId) {
            this[NavigationMixin.GenerateUrl]({
                type: 'standard__navItemPage',
                attributes: {
                    apiName: 'JEDI_Overview'
                },
                state: {
                    c__recordId: parentId
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