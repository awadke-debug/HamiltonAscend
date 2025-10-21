import { LightningElement, api, track, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import getCampaignDetail from '@salesforce/apex/HAMJEDIPledgeBalanceController.getCampaignDetail';
import getEndowdedFundsDetail from '@salesforce/apex/HAMJEDIPledgeBalanceController.getEndowdedFundsDetail';
import getLast5YearsDetail from '@salesforce/apex/HAMJEDIPledgeBalanceController.getLast5YearsDetail';
import getGivingByPurposeDetail from '@salesforce/apex/HAMJEDIPledgeBalanceController.getGivingByPurposeDetail';
import getOpenPledgeDetail from '@salesforce/apex/HAMJEDIPledgeBalanceController.getOpenPledgeDetail';

export default class HAMJediPledgeBalanceConfigTable extends LightningElement {
    // =========================================
    // Core Properties
    // =========================================
    @api tableName; // Parameter to find the table
    @api recordId;
    @track loading = false; // Spinner control
    
    // =========================================
    // Data model
    // =========================================
    @track balanceDetails = [];        // full dataset
    @track pageBalance = [];           // current page rows bound to the datatable
    @track displayColumns = [];
    
    // =========================================
    // UI Properties
    // =========================================
    @track accordianName = '';
    @track fundDate = '';
    @track activeBalanceSection = 'Campaign';
   
    // =========================================
    // Sorting state
    // =========================================
    @track sortedBy = 'Name';
    @track sortedDirection = 'asc';

    // =========================================
    // Pagination (following your standards)
    // =========================================
    @track pageSize = 10;     // rows per page
    @track pageNumber = 1;    // 1-based index
    @track totalRecords = 0;  // derived from balanceDetails.length

    // Derived helpers for UI controls
    get totalPages() {
        return Math.max(1, Math.ceil(this.totalRecords / this.pageSize));
    }
    get isFirstPage() {
        return this.pageNumber <= 1;
    }
    get isLastPage() {
        return this.pageNumber >= this.totalPages || this.totalRecords === 0;
    }
    get showPagination() {
        return this.totalRecords > this.pageSize;
    }

    // Compute current page slice from balanceDetails → pageBalance
    derivePage() {
        const start = (this.pageNumber - 1) * this.pageSize;
        const end = start + this.pageSize;
        this.pageBalance = this.balanceDetails.slice(start, end);
    }

    // Handlers for footer buttons
    nextPage() {
        if (!this.isLastPage) {
            this.pageNumber += 1;
            this.derivePage();
        }
    }
    prevPage() {
        if (!this.isFirstPage) {
            this.pageNumber -= 1;
            this.derivePage();
        }
    }

    // =========================================
    // Data Loading and Setup
    // =========================================
    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference?.state?.c__recordId) {
            this.recordId = currentPageReference.state.c__recordId;
           
            if(this.tableName){
                 this.accordianName = this.tableName;
            } else {
                this.accordianName = 'Campaign';
            }
           
            this.loading = true; // Start spinner
            
            if(this.tableName == 'Endowed Funds'){
                this.loadEndowedFunds();
            } else if(this.tableName == 'Campaign'){
                this.loadCampaign();
            } else if(this.tableName == 'Giving By Purpose'){
                this.loadGivingByPurpose();
            } else if(this.tableName == 'Last 5 year Giving'){
                this.pageSize = 5;
                this.loadLast5Years();
            } else {
                // open Pledge (default)
                this.loadOpenPledge();
            }
        }
    }

    // =========================================
    // Data Loading Methods
    // =========================================
    loadEndowedFunds() {
        getEndowdedFundsDetail({ contactId: this.recordId })
            .then(result => {
                this.balanceDetails = result || [];
                this.displayColumns = [
                    {
                        label: 'Name',
                        fieldName: 'HAM_Designation__c',
                        type: 'text',
                        sortable: true
                    },
                    {
                        label: 'Book Value',
                        fieldName: 'HAM_Pledged__c',
                        type: 'currency',
                        typeAttributes: {
                            currencyCode: 'USD',
                            minimumFractionDigits: 2
                        },
                        sortable: true
                    },
                    {
                        label: 'Market Value',
                        fieldName: 'HAM_Paid__c',
                        type: 'currency',
                        typeAttributes: {
                            currencyCode: 'USD',
                            minimumFractionDigits: 2
                        },
                        sortable: true
                    },
                    {
                        label: 'As Of',
                        fieldName: 'HAM_Endowed_Fund_Date__c',
                        type: 'date',
                        typeAttributes: {
                            year: 'numeric',
                            month: 'short',
                            day: '2-digit',
                            hour: '2-digit',
                            minute: '2-digit'
                        },
                        sortable: true
                    }
                ];
                
                //Sorting Table
                this.sortedBy = 'HAM_Paid__c';
                this.sortedDirection = 'desc';

                this.finalizeDataSetup();
            })
            .catch(error => {
                console.error('Error fetching Endowed Funds:', error);
                this.handleError();
            })
            .finally(() => {
                this.loading = false;
            });
    }

    loadCampaign() {
        getCampaignDetail({ contactId: this.recordId })
            .then(result => {
                this.balanceDetails = result || [];
                
                this.displayColumns = [
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
                
                this.finalizeDataSetup();
            })
            .catch(error => {
                console.error('Error fetching Campaign:', error);
                this.handleError();
            })
            .finally(() => {
                this.loading = false;
            });
    }

    loadGivingByPurpose() {
        getGivingByPurposeDetail({ contactId: this.recordId })
            .then(result => {
                this.balanceDetails = result || [];
                
                this.displayColumns = [
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
                
                this.finalizeDataSetup();
            })
            .catch(error => {
                console.error('Error fetching Giving by Purpose:', error);
                this.handleError();
            })
            .finally(() => {
                this.loading = false;
            });
    }

    loadLast5Years() {
        getLast5YearsDetail({ contactId: this.recordId })
            .then(result => {
                this.balanceDetails = result || [];
                
                this.displayColumns = [
                    {
                        label: 'Fiscal Year',
                        fieldName: 'HAM_Fiscal_Year__c',
                        type: 'text',
                        sortable: true
                    },
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
                //Sorting Table
                this.sortedBy = 'HAM_Fiscal_Year__c';
                this.sortedDirection = 'desc';

                this.finalizeDataSetup();
            })
            .catch(error => {
                console.error('Error fetching Last 5 Years:', error);
                this.handleError();
            })
            .finally(() => {
                this.loading = false;
            });
    }

    loadOpenPledge() {
        getOpenPledgeDetail({ contactId: this.recordId })
            .then(result => {
                this.balanceDetails = result || [];
                
                this.displayColumns = [
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
                    },
                    {
                        label: 'Balance',
                        fieldName: 'HAM_Pledge_Balance__c',
                        type: 'currency',
                        typeAttributes: {
                            currencyCode: 'USD',
                            minimumFractionDigits: 2
                        },
                        sortable: true
                    }
                ];
                
                this.finalizeDataSetup();
            })
            .catch(error => {
                console.error('Error fetching Open Pledge:', error);
                this.handleError();
            })
            .finally(() => {
                this.loading = false;
            });
    }

    // =========================================
    // Helper Methods
    // =========================================
    finalizeDataSetup() {
        this.totalRecords = this.balanceDetails.length;
        
        // Apply default sort
        this.sortEventData(this.sortedBy, this.sortedDirection);

        // Reset to first page and compute slice
        this.pageNumber = 1;
        this.derivePage();

        // Set active section
        this.activeBalanceSection = this.tableName;
    }

    handleError() {
        this.balanceDetails = [];
        this.pageBalance = [];
        this.totalRecords = 0;
        this.pageNumber = 1;
    }

    // =========================================
    // Event Handlers
    // =========================================
    handleBalanceSectionToggle(event) {
        const openedSections = event.detail.openSections;
        
        if (Array.isArray(openedSections)) {
            this.activeBalanceSection = openedSections.includes(this.tableName) ? this.tableName : '';
        } else {
            this.activeBalanceSection = openedSections === this.tableName ? this.tableName : '';
        }
    }

    // =========================================
    // Datatable sort handler
    // =========================================
    handleEventSort(event) {
        const { fieldName: sortedBy, sortDirection } = event.detail;
        this.sortedBy = sortedBy;
        this.sortedDirection = sortDirection;

        this.sortEventData(sortedBy, sortDirection);

        // Reset to first page after sorting and compute slice
        this.pageNumber = 1;
        this.derivePage();
    }

    // Core sort routine. We always sort balanceDetails so pagination stays consistent.
    sortEventData(field, direction) {
        const key = field === 'recordLink' ? 'Name' : field;
        const dir = direction === 'desc' ? -1 : 1;

        this.balanceDetails = [...this.balanceDetails].sort((a, b) => {
            let va = a[key] ?? '';
            let vb = b[key] ?? '';
            
            // Handle currency fields specially
            if (field === 'HAM_Pledged__c' || field === 'HAM_Paid__c' || field === 'HAM_Pledge_Balance__c') {
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
}