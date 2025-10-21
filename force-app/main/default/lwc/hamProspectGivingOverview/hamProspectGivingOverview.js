import { LightningElement, api, track, wire } from 'lwc';
import searchProspectGivingDetails from '@salesforce/apex/HAMProspectOverviewApexController.searchProspectGivingDetails';
import { CurrentPageReference } from 'lightning/navigation';
import { NavigationMixin } from 'lightning/navigation';
import getCampaignDetail from '@salesforce/apex/HAMJEDIPledgeBalanceController.getCampaignDetail';
import getGivingByPurposeDetail from '@salesforce/apex/HAMJEDIPledgeBalanceController.getGivingByPurposeDetail';
import badge1812 from '@salesforce/resourceUrl/HAMBadgeFor1812'; // Replace with your resource name
import badge10to5 from '@salesforce/resourceUrl/HAM10To5';  
import alumniCouncil from '@salesforce/resourceUrl/HAMAlumniCouncil'; 
import chapelBell from '@salesforce/resourceUrl/HAMChapelBell'; 
import CoperGuild from '@salesforce/resourceUrl/HAMCouperGuild'; 
import founderCircle from '@salesforce/resourceUrl/HAMFoundersCircle'; 
import jBABadge from '@salesforce/resourceUrl/HAMJBABadge'; 
import trusteebadge from '@salesforce/resourceUrl/HAMTrusteeBadge'; 
import formURL from '@salesforce/label/c.HAM_JEDI_Feedback_Link';




export default class HamProspectGivingOverview extends LightningElement {
    @api contactgivingrecord; 
    @track activeGivingSectionBio = 'Giving Summary';
    @api recordId;
    @track contactDetails;
    @track designationDetails = [];
    @track campaignDetails = [];
    @track givingDetails = [];
    @track loading = false; // Spinner control
    @track badgeFor1812 = badge1812;
    @track badgeFor10to5 = badge10to5;
    @track badgeAC = alumniCouncil;
    @track badgeCB = chapelBell;
    @track badgeCG = CoperGuild;
    @track badgeFC = founderCircle;
    @track badgeForJBA = jBABadge;
    @track badgeTrustee = trusteebadge;
    @track sortedByGiving = 'HAM_Pledged__c';
    @track sortedDirectionGiving = 'desc';
    @track sortedByCampaign = 'HAM_Pledged__c';
    @track sortedDirectionCampaign = 'desc';

    @track designationColumns = [
        {
            label: 'Name',
            fieldName: 'recordLink',
            type: 'url',
            typeAttributes: {
                label: { fieldName: 'HAM_Fund_Name__c' },
                target: '_blank' // Opens in new tab
            }, cellAttributes: {
            class: 'slds-truncate' // optional for better mobile behavior
        }
        }
    ];

     @track campaignColumns =  [
        {
            label: 'Name',
            fieldName: 'HAM_Designation__c',
            type: 'text',
            //sortable: true
        },
        {
            label: 'Committed',
            fieldName: 'HAM_Pledged__c',
            type: 'currency',
            typeAttributes: {
                currencyCode: 'USD',
                minimumFractionDigits: 2
            },
            //sortable: true
        },
        {
            label: 'Paid',
            fieldName: 'HAM_Paid__c',
            type: 'currency',
            typeAttributes: {
                currencyCode: 'USD',
                minimumFractionDigits: 2
            },
            //sortable: true
        }
    ];

 @track givingDesignationColumns =  [
    {
        label: 'Purpose',
        fieldName: 'Purpose',
        type: 'text',
        //sortable: true
    },
    {
        label: 'Committed',
        fieldName: 'Committed',
        type: 'currency',
        typeAttributes: {
            currencyCode: 'USD',
            minimumFractionDigits: 2
        },
        //sortable: true
    },
    {
        label: 'Paid',
        fieldName: 'Paid',
        type: 'currency',
        typeAttributes: {
            currencyCode: 'USD',
            minimumFractionDigits: 2
        },
        //sortable: true
    }
];

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference?.state?.c__recordId) {
            this.recordId = currentPageReference.state.c__recordId;

            this.loading = true; // Start spinner
            searchProspectGivingDetails({ contactId: this.recordId })
                .then(result => {
                    this.contactgivingrecord = result;
                    

                    this.contactDetails = this.contactgivingrecord.objRecord;
                    this.designationDetails = this.contactgivingrecord.designations;
                     if (this.designationDetails) {
                        this.designationDetails = this.designationDetails.map(fund => ({
                            ...fund,
                            recordLink: `/lightning/r/${fund.Id}/view`
                        }));
                    }
                    
                })
                .catch(error => {
                    console.error('Error fetching Prospect:', error);
                })
                .finally(() => {
                    this.loading = false; // Stop spinner
                });
            this.loading = true; // Start spinner
            getGivingByPurposeDetail({ contactId: this.recordId })
                .then(result => {
                    this.givingDetails = result || [];

                        // Sort by Committed (HAM_Pledged__c) descending
                        this.givingDetails = [...this.givingDetails].sort((a, b) => {
                        const va = parseFloat(a.HAM_Pledged__c) || 0;
                        const vb = parseFloat(b.HAM_Pledged__c) || 0;
                        return vb - va; // desc order
                        });

                    this.givingDesignationColumns = [
                        {
                            label: 'Purpose',
                            fieldName: 'HAM_Designation__c',
                            type: 'text',
                            //sortable: true
                        },
                        {
                            label: 'Committed',
                            fieldName: 'HAM_Pledged__c',
                            type: 'currency',
                            typeAttributes: {
                                currencyCode: 'USD',
                                minimumFractionDigits: 2
                            },
                            //sortable: true
                        },
                        {
                            label: 'Paid',
                            fieldName: 'HAM_Paid__c',
                            type: 'currency',
                            typeAttributes: {
                                currencyCode: 'USD',
                                minimumFractionDigits: 2
                            },
                            //sortable: true
                        }
                    ];
                })
                .catch(error => {
                    console.error('Error fetching Balance:', error);
                })
                .finally(() => {
                    this.loading = false; // Stop spinner
                });
        }
    }
   
    @wire(CurrentPageReference)
    getCampaignParameters(currentPageReference) {
        if (currentPageReference?.state?.c__recordId) {
            this.recordId = currentPageReference.state.c__recordId;

            this.loading = true; // Start spinner
            getCampaignDetail({ contactId: this.recordId })
            .then(result => {
                this.campaignDetails = result || [];

                    // Sort by Committed (HAM_Pledged__c) descending
                    this.campaignDetails = [...this.campaignDetails].sort((a, b) => {
                    const va = parseFloat(a.HAM_Pledged__c) || 0;
                    const vb = parseFloat(b.HAM_Pledged__c) || 0;
                    return vb - va; // desc order
                    });

                this.campaignColumns = [
                    {
                        label: 'Purpose',
                        fieldName: 'HAM_Designation__c',
                        type: 'text',
                        wrapText: true,
                        cellAttributes: { class: 'wrapText' },
                        //sortable: true
                    },{
                        label: 'Committed',
                        fieldName: 'HAM_Pledged__c',
                        type: 'currency',
                        wrapText: true,
                        cellAttributes: { class: 'wrapText' },
                        typeAttributes: {
                            currencyCode: 'USD',
                            minimumFractionDigits: 2
                        },
                        //sortable: true
                    },
                    {
                        label: 'Paid',
                        fieldName: 'HAM_Paid__c',
                        type: 'currency',
                        wrapText: true,
                        cellAttributes: { class: 'wrapText' },
                        typeAttributes: {
                            currencyCode: 'USD',
                            minimumFractionDigits: 2
                        },
                        //sortable: true
                    }
                ];
            })
            .catch(error => {
                console.error('Error fetching Balance:', error);
            })
            .finally(() => {
                this.loading = false; // Stop spinner
            });
        }
    }

    handleGivingSectionToggle(event) {
        
        const openedSections = event.detail.openSections;
        
        if (Array.isArray(openedSections)) {
            this.activeGivingSectionBio = openedSections.includes('Giving Summary') ? 'Giving Summary' : '';
        } else {
            this.activeGivingSectionBio = openedSections === 'Giving Summary' ? 'Giving Summary' : '';
        }
 
    }

    navigateToHelp() {
        window.open(formURL, '_blank'); // Opens in a new tab
    }
}