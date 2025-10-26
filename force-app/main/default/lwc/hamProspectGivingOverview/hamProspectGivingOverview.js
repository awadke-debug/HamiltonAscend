import { LightningElement, api, track, wire } from 'lwc';
import searchProspectGivingDetails from '@salesforce/apex/HAMProspectOverviewApexController.searchProspectGivingDetails';
import { CurrentPageReference } from 'lightning/navigation';
import { NavigationMixin } from 'lightning/navigation';
import getCampaignDetail from '@salesforce/apex/HAMJEDIPledgeBalanceController.getCampaignDetail';
import getGivingByPurposeDetail from '@salesforce/apex/HAMJEDIPledgeBalanceController.getGivingByPurposeDetail';
import badge1812 from '@salesforce/resourceUrl/HAMBadgeFor1812';
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
    @track loading = false;
    @track badgeFor1812 = badge1812;
    @track badgeFor10to5 = badge10to5;
    @track badgeAC = alumniCouncil;
    @track badgeCB = chapelBell;
    @track badgeCG = CoperGuild;
    @track badgeFC = founderCircle;
    @track badgeForJBA = jBABadge;
    @track badgeTrustee = trusteebadge;

    // =========================================
    // Giving by Designation Data & Pagination
    // =========================================
    @track allGivingDetails = [];
    @track pageGivingDetails = [];
    @track givingPageSize = 10;
    @track givingPageNumber = 1;
    @track givingTotalRecords = 0;
    @track givingSortedBy = 'HAM_Pledged__c';
    @track givingSortedDirection = 'desc';

    get givingTotalPages() {
        return Math.max(1, Math.ceil(this.givingTotalRecords / this.givingPageSize));
    }
    get isGivingFirstPage() {
        return this.givingPageNumber <= 1;
    }
    get isGivingLastPage() {
        return this.givingPageNumber >= this.givingTotalPages || this.givingTotalRecords === 0;
    }
    get showGivingPagination() {
        return this.givingTotalRecords > 10;
    }

    deriveGivingPage() {
        const start = (this.givingPageNumber - 1) * this.givingPageSize;
        const end = start + this.givingPageSize;
        this.pageGivingDetails = this.allGivingDetails.slice(start, end);
    }

    nextGivingPage() {
        if (!this.isGivingLastPage) {
            this.givingPageNumber += 1;
            this.deriveGivingPage();
        }
    }

    prevGivingPage() {
        if (!this.isGivingFirstPage) {
            this.givingPageNumber -= 1;
            this.deriveGivingPage();
        }
    }

    handleGivingSort(event) {
        const { fieldName: sortedBy, sortDirection } = event.detail;
        this.givingSortedBy = sortedBy;
        this.givingSortedDirection = sortDirection;
        this.sortGivingData(sortedBy, sortDirection);
        this.givingPageNumber = 1;
        this.deriveGivingPage();
    }

    sortGivingData(field, direction) {
        const dir = direction === 'desc' ? -1 : 1;
        this.allGivingDetails = [...this.allGivingDetails].sort((a, b) => {
            let va = a[field] ?? '';
            let vb = b[field] ?? '';
            
            if (field === 'HAM_Pledged__c' || field === 'HAM_Paid__c') {
                va = parseFloat(va) || 0;
                vb = parseFloat(vb) || 0;
            } else {
                va = va.toString().toLowerCase();
                vb = vb.toString().toLowerCase();
            }
            
            if (va === vb) return 0;
            return va > vb ? dir : -dir;
        });
    }

    // =========================================
    // Campaign Data & Pagination
    // =========================================
    @track allCampaignDetails = [];
    @track pageCampaignDetails = [];
    @track campaignPageSize = 10;
    @track campaignPageNumber = 1;
    @track campaignTotalRecords = 0;
    @track campaignSortedBy = 'HAM_Pledged__c';
    @track campaignSortedDirection = 'desc';

    get campaignTotalPages() {
        return Math.max(1, Math.ceil(this.campaignTotalRecords / this.campaignPageSize));
    }
    get isCampaignFirstPage() {
        return this.campaignPageNumber <= 1;
    }
    get isCampaignLastPage() {
        return this.campaignPageNumber >= this.campaignTotalPages || this.campaignTotalRecords === 0;
    }
    get showCampaignPagination() {
        return this.campaignTotalRecords > 10;
    }

    deriveCampaignPage() {
        const start = (this.campaignPageNumber - 1) * this.campaignPageSize;
        const end = start + this.campaignPageSize;
        this.pageCampaignDetails = this.allCampaignDetails.slice(start, end);
    }

    nextCampaignPage() {
        if (!this.isCampaignLastPage) {
            this.campaignPageNumber += 1;
            this.deriveCampaignPage();
        }
    }

    prevCampaignPage() {
        if (!this.isCampaignFirstPage) {
            this.campaignPageNumber -= 1;
            this.deriveCampaignPage();
        }
    }

    handleCampaignSort(event) {
        const { fieldName: sortedBy, sortDirection } = event.detail;
        this.campaignSortedBy = sortedBy;
        this.campaignSortedDirection = sortDirection;
        this.sortCampaignData(sortedBy, sortDirection);
        this.campaignPageNumber = 1;
        this.deriveCampaignPage();
    }

    sortCampaignData(field, direction) {
        const dir = direction === 'desc' ? -1 : 1;
        this.allCampaignDetails = [...this.allCampaignDetails].sort((a, b) => {
            let va = a[field] ?? '';
            let vb = b[field] ?? '';
            
            if (field === 'HAM_Pledged__c' || field === 'HAM_Paid__c') {
                va = parseFloat(va) || 0;
                vb = parseFloat(vb) || 0;
            } else {
                va = va.toString().toLowerCase();
                vb = vb.toString().toLowerCase();
            }
            
            if (va === vb) return 0;
            return va > vb ? dir : -dir;
        });
    }

    // =========================================
    // Column Definitions
    // =========================================
    @track designationColumns = [
        {
            label: 'Name',
            fieldName: 'recordLink',
            type: 'url',
            typeAttributes: {
                label: { fieldName: 'HAM_Fund_Name__c' },
                target: '_blank'
            }, 
            cellAttributes: {
                class: 'slds-truncate'
            }
        }
    ];

    @track campaignColumns = [
        {
            label: 'Name',
            fieldName: 'HAM_Designation__c',
            type: 'text',
            sortable: true
        },
        {
            label: 'Committed',
            fieldName: 'HAM_Pledged__c',
            type: 'currency',
            typeAttributes: {
                currencyCode: 'USD',
                minimumFractionDigits: 2
            },
            sortable: true
        },
        {
            label: 'Paid',
            fieldName: 'HAM_Paid__c',
            type: 'currency',
            typeAttributes: {
                currencyCode: 'USD',
                minimumFractionDigits: 2
            },
            sortable: true
        }
    ];

    @track givingDesignationColumns = [
        {
            label: 'Purpose',
            fieldName: 'Purpose',
            type: 'text',
            sortable: true
        },
        {
            label: 'Committed',
            fieldName: 'Committed',
            type: 'currency',
            typeAttributes: {
                currencyCode: 'USD',
                minimumFractionDigits: 2
            },
            sortable: true
        },
        {
            label: 'Paid',
            fieldName: 'Paid',
            type: 'currency',
            typeAttributes: {
                currencyCode: 'USD',
                minimumFractionDigits: 2
            },
            sortable: true
        }
    ];

    // =========================================
    // Data Loading
    // =========================================
    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference?.state?.c__recordId) {
            this.recordId = currentPageReference.state.c__recordId;

            this.loading = true;
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
                    this.loading = false;
                });

            this.loading = true;
            getGivingByPurposeDetail({ contactId: this.recordId })
                .then(result => {
                    this.allGivingDetails = result || [];
                    this.givingTotalRecords = this.allGivingDetails.length;
                    
                    this.givingDesignationColumns = [
                        {
                            label: 'Purpose',
                            fieldName: 'HAM_Designation__c',
                            type: 'text',
                            sortable: true
                        },
                        {
                            label: 'Committed',
                            fieldName: 'HAM_Pledged__c',
                            type: 'currency',
                            typeAttributes: {
                                currencyCode: 'USD',
                                minimumFractionDigits: 2
                            },
                            sortable: true
                        },
                        {
                            label: 'Paid',
                            fieldName: 'HAM_Paid__c',
                            type: 'currency',
                            typeAttributes: {
                                currencyCode: 'USD',
                                minimumFractionDigits: 2
                            },
                            sortable: true
                        }
                    ];
                    
                    this.sortGivingData(this.givingSortedBy, this.givingSortedDirection);
                    this.givingPageNumber = 1;
                    this.deriveGivingPage();
                })
                .catch(error => {
                    console.error('Error fetching Balance:', error);
                })
                .finally(() => {
                    this.loading = false;
                });
        }
    }
   
    @wire(CurrentPageReference)
    getCampaignParameters(currentPageReference) {
        if (currentPageReference?.state?.c__recordId) {
            this.recordId = currentPageReference.state.c__recordId;

            this.loading = true;
            getCampaignDetail({ contactId: this.recordId })
                .then(result => {
                    this.allCampaignDetails = result || [];
                    this.campaignTotalRecords = this.allCampaignDetails.length;
                    
                    this.campaignColumns = [
                        {
                            label: 'Purpose',
                            fieldName: 'HAM_Designation__c',
                            type: 'text',
                            wrapText: true,
                            cellAttributes: { class: 'wrapText' },
                            sortable: true
                        },
                        {
                            label: 'Committed',
                            fieldName: 'HAM_Pledged__c',
                            type: 'currency',
                            wrapText: true,
                            cellAttributes: { class: 'wrapText' },
                            typeAttributes: {
                                currencyCode: 'USD',
                                minimumFractionDigits: 2
                            },
                            sortable: true
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
                            sortable: true
                        }
                    ];
                    
                    this.sortCampaignData(this.campaignSortedBy, this.campaignSortedDirection);
                    this.campaignPageNumber = 1;
                    this.deriveCampaignPage();
                })
                .catch(error => {
                    console.error('Error fetching Balance:', error);
                })
                .finally(() => {
                    this.loading = false;
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
        window.open(formURL, '_blank');
    }
}