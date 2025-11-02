import { LightningElement, api, track, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import getInvolvements from '@salesforce/apex/HamJEDIInvolvementController.getInvolvements';

export default class HamJEDIInvolvement extends LightningElement {
    // =========================================
    // Design Properties (Configurable in App Builder)
    // =========================================
    @api tableTitle;  // Table header title (no default)
    @api recordTypeId;  // Record Type ID filter

    // =========================================
    // Core Properties
    // =========================================
    @api recordId;  // Contact ID from page context
    @track loading = false;

    // =========================================
    // Data model
    // =========================================
    @track involvementDetails = [];  // full dataset
    @track pageInvolvements = [];    // current page rows
    @track displayColumns = [];

    // =========================================
    // UI Properties
    // =========================================
    @track activeSection = '';

    // =========================================
    // Sorting state
    // =========================================
    @track sortedBy = 'ucinn_ascendv2__Status__c';
    @track sortedDirection = 'asc';

    // =========================================
    // Pagination
    // =========================================
    @track pageSize = 10;
    @track pageNumber = 1;
    @track totalRecords = 0;

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

    // Compute current page slice
    derivePage() {
        const start = (this.pageNumber - 1) * this.pageSize;
        const end = start + this.pageSize;
        this.pageInvolvements = this.involvementDetails.slice(start, end);
    }

    // Pagination handlers
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
    // Data Loading
    // =========================================
    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference?.state?.c__recordId) {
            this.recordId = currentPageReference.state.c__recordId;
            this.loadInvolvements();
        }
    }

    loadInvolvements() {
        if (!this.recordId || !this.recordTypeId) {
            return;
        }

        this.loading = true;

        getInvolvements({ contactId: this.recordId, recordTypeId: this.recordTypeId })
            .then(result => {
                this.involvementDetails = result || [];

                // Define columns for datatable
                this.displayColumns = [
                    {
                        label: 'Involvement Code Description',
                        fieldName: 'recordLink',
                        type: 'url',
                        typeAttributes: {
                            label: { fieldName: 'ucinn_ascendv2__Involvement_Code_Description_Formula__c' },
                            target: '_blank'
                        },
                        sortable: true
                    },
                    {
                        label: 'Category',
                        fieldName: 'HAM_Category__c',
                        type: 'text',
                        sortable: true
                    },
                    {
                        label: 'Start Date',
                        fieldName: 'ucinn_ascendv2__Start_Date__c',
                        type: 'date',
                        sortable: true
                    },
                    {
                        label: 'End Date',
                        fieldName: 'ucinn_ascendv2__End_Date__c',
                        type: 'date',
                        sortable: true
                    },
                    {
                        label: 'Role',
                        fieldName: 'ucinn_ascendv2__Role__c',
                        type: 'text',
                        sortable: true
                    },
                    {
                        label: 'Involvement ID',
                        fieldName: 'Name',
                        type: 'text',
                        sortable: true
                    }
                ];

                // Add record links for navigation
                this.involvementDetails = this.involvementDetails.map(record => ({
                    ...record,
                    recordLink: `/${record.Id}`
                }));

                this.finalizeDataSetup();
            })
            .catch(error => {
                console.error('Error fetching involvements:', error);
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
        this.totalRecords = this.involvementDetails.length;

        // Apply default sort
        this.sortData(this.sortedBy, this.sortedDirection);

        // Reset to first page and compute slice
        this.pageNumber = 1;
        this.derivePage();

        // Set active section
        this.activeSection = this.tableTitle;
    }

    handleError() {
        this.involvementDetails = [];
        this.pageInvolvements = [];
        this.totalRecords = 0;
        this.pageNumber = 1;
    }

    // =========================================
    // Event Handlers
    // =========================================
    handleSectionToggle(event) {
        const openedSections = event.detail.openSections;

        if (Array.isArray(openedSections)) {
            this.activeSection = openedSections.includes(this.tableTitle) ? this.tableTitle : '';
        } else {
            this.activeSection = openedSections === this.tableTitle ? this.tableTitle : '';
        }
    }

    handleSort(event) {
        const { fieldName: sortedBy, sortDirection } = event.detail;
        this.sortedBy = sortedBy;
        this.sortedDirection = sortDirection;

        this.sortData(sortedBy, sortDirection);

        // Reset to first page after sorting
        this.pageNumber = 1;
        this.derivePage();
    }

    sortData(field, direction) {
        const key = field === 'recordLink' ? 'ucinn_ascendv2__Involvement_Code_Description_Formula__c' : field;
        const dir = direction === 'desc' ? -1 : 1;

        this.involvementDetails = [...this.involvementDetails].sort((a, b) => {
            let va = a[key] ?? '';
            let vb = b[key] ?? '';

            // Handle date fields
            if (field === 'ucinn_ascendv2__Start_Date__c' || field === 'ucinn_ascendv2__End_Date__c') {
                va = va ? new Date(va).getTime() : 0;
                vb = vb ? new Date(vb).getTime() : 0;
            } else {
                va = va.toString().toLowerCase();
                vb = vb.toString().toLowerCase();
            }

            // Primary sort by the selected field
            if (va !== vb) {
                return va > vb ? dir : -dir;
            }

            // Secondary sort: Status ASC (Current before Former)
            let statusA = (a.ucinn_ascendv2__Status__c ?? '').toString().toLowerCase();
            let statusB = (b.ucinn_ascendv2__Status__c ?? '').toString().toLowerCase();
            if (statusA !== statusB) {
                return statusA > statusB ? 1 : -1;
            }

            // Tertiary sort: Start Date ASC
            let dateA = a.ucinn_ascendv2__Start_Date__c ? new Date(a.ucinn_ascendv2__Start_Date__c).getTime() : 0;
            let dateB = b.ucinn_ascendv2__Start_Date__c ? new Date(b.ucinn_ascendv2__Start_Date__c).getTime() : 0;
            return dateA - dateB;
        });
    }
}