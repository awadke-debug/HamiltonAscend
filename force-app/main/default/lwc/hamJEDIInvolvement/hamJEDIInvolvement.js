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
    @track rawInvolvements = [];     // original unfiltered dataset from server
    @track involvementDetails = [];  // full, sorted dataset; pagination slices from here
    @track pageInvolvements = [];    // current page rows
    @track displayColumns = [];

    // =========================================
    // UI Properties
    // =========================================
    @track activeSection = '';

    // =========================================
    // Advance Filters
    // =========================================
    @track showAdvanceFilters = false;
    @track filterCategory = [];  // Array for multi-select
    @track filterRole = '';
    @track filterStartDate = '';
    @track filterEndDate = '';
    @track categoryOptions = [];
    @track roleOptions = [];

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
                const rows = result || [];

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
                const processedRows = rows.map(record => ({
                    ...record,
                    recordLink: `/${record.Id}`
                }));

                // Store original unfiltered data
                this.rawInvolvements = [...processedRows];
                this.involvementDetails = [...processedRows];

                // Extract unique Categories for filter options (multi-select, no --None--)
                const uniqueCategories = new Set();
                processedRows.forEach(row => {
                    if (row.HAM_Category__c) {
                        uniqueCategories.add(row.HAM_Category__c);
                    }
                });
                this.categoryOptions = Array.from(uniqueCategories).sort().map(cat => ({
                    label: cat,
                    value: cat
                }));

                // Extract unique Roles for filter options
                const uniqueRoles = new Set();
                processedRows.forEach(row => {
                    if (row.ucinn_ascendv2__Role__c) {
                        uniqueRoles.add(row.ucinn_ascendv2__Role__c);
                    }
                });
                this.roleOptions = [
                    { label: '--None--', value: '' },
                    ...Array.from(uniqueRoles).sort().map(role => ({
                        label: role,
                        value: role
                    }))
                ];

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

        // Set active section - only open if there are records
        this.activeSection = this.totalRecords > 0 ? this.tableTitle : '';
    }

    handleError() {
        this.rawInvolvements = [];
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

    // =========================================
    // Advance Filter Methods
    // =========================================
    toggleAdvanceFilters() {
        this.showAdvanceFilters = !this.showAdvanceFilters;
    }

    handleCategoryChange(event) {
        this.filterCategory = event.detail.value;
    }

    handleRoleChange(event) {
        this.filterRole = event.detail.value;
    }

    handleStartDateChange(event) {
        this.filterStartDate = event.target.value;
    }

    handleEndDateChange(event) {
        this.filterEndDate = event.target.value;
    }

    handleSearchFilters() {
        // Start with original unfiltered data
        let filteredInvolvements = [...this.rawInvolvements];

        // Apply Category Filter (multi-select)
        if (this.filterCategory && this.filterCategory.length > 0) {
            filteredInvolvements = filteredInvolvements.filter(involvement => {
                return this.filterCategory.includes(involvement.HAM_Category__c);
            });
        }

        // Apply Role Filter
        if (this.filterRole) {
            filteredInvolvements = filteredInvolvements.filter(involvement => {
                return involvement.ucinn_ascendv2__Role__c === this.filterRole;
            });
        }

        // Apply Date Filters (BOTH start date and end date must fall within filter range)
        if (this.filterStartDate || this.filterEndDate) {
            filteredInvolvements = filteredInvolvements.filter(involvement => {
                const involvementStartDate = involvement.ucinn_ascendv2__Start_Date__c;
                const involvementEndDate = involvement.ucinn_ascendv2__End_Date__c;

                // Skip if no start date
                if (!involvementStartDate) return false;

                // Normalize involvement start date to date-only (strip time)
                const invStartDateOnly = new Date(involvementStartDate);
                invStartDateOnly.setHours(0, 0, 0, 0);
                const invStartDateStr = invStartDateOnly.toISOString().split('T')[0];

                // Normalize involvement end date if it exists
                let invEndDateStr = null;
                if (involvementEndDate) {
                    const invEndDateOnly = new Date(involvementEndDate);
                    invEndDateOnly.setHours(0, 0, 0, 0);
                    invEndDateStr = invEndDateOnly.toISOString().split('T')[0];
                }

                // Scenario 1: Only Filter Start Date → from filter start date to today (inclusive)
                if (this.filterStartDate && !this.filterEndDate) {
                    const filterStartDateObj = new Date(this.filterStartDate);
                    const filterStartDateStr = filterStartDateObj.toISOString().split('T')[0];
                    const today = new Date();
                    const todayStr = today.toISOString().split('T')[0];

                    // BOTH start and end date must be in range
                    const startInRange = invStartDateStr >= filterStartDateStr && invStartDateStr <= todayStr;
                    if (!invEndDateStr) return startInRange; // If no end date, only check start
                    const endInRange = invEndDateStr >= filterStartDateStr && invEndDateStr <= todayStr;
                    return startInRange && endInRange;
                }

                // Scenario 2: Only Filter End Date → from beginning to filter end date (inclusive)
                if (!this.filterStartDate && this.filterEndDate) {
                    const filterEndDateObj = new Date(this.filterEndDate);
                    const filterEndDateStr = filterEndDateObj.toISOString().split('T')[0];

                    // BOTH start and end date must be in range
                    const startInRange = invStartDateStr <= filterEndDateStr;
                    if (!invEndDateStr) return startInRange; // If no end date, only check start
                    const endInRange = invEndDateStr <= filterEndDateStr;
                    return startInRange && endInRange;
                }

                // Scenario 3: Both Filter Start and End Date → specific range (both inclusive)
                if (this.filterStartDate && this.filterEndDate) {
                    const filterStartDateObj = new Date(this.filterStartDate);
                    const filterStartDateStr = filterStartDateObj.toISOString().split('T')[0];
                    const filterEndDateObj = new Date(this.filterEndDate);
                    const filterEndDateStr = filterEndDateObj.toISOString().split('T')[0];

                    // BOTH start and end date must be in range
                    const startInRange = invStartDateStr >= filterStartDateStr && invStartDateStr <= filterEndDateStr;
                    if (!invEndDateStr) return startInRange; // If no end date, only check start
                    const endInRange = invEndDateStr >= filterStartDateStr && invEndDateStr <= filterEndDateStr;
                    return startInRange && endInRange;
                }

                return true;
            });
        }

        // Update involvementDetails with filtered data
        this.involvementDetails = [...filteredInvolvements];
        this.totalRecords = this.involvementDetails.length;

        // Re-apply current sort
        this.sortData(this.sortedBy, this.sortedDirection);

        // Reset to page 1 and update display
        this.pageNumber = 1;
        this.derivePage();
    }

    handleClearFilters() {
        // Clear filter values
        this.filterCategory = [];  // Clear array for multi-select
        this.filterRole = '';
        this.filterStartDate = '';
        this.filterEndDate = '';

        // Reset to original unfiltered data
        this.involvementDetails = [...this.rawInvolvements];
        this.totalRecords = this.involvementDetails.length;

        // Re-apply current sort
        this.sortData(this.sortedBy, this.sortedDirection);

        // Reset to page 1 and update display
        this.pageNumber = 1;
        this.derivePage();

        // Keep active section open if records exist after clearing filters
        if (this.totalRecords > 0) {
            this.activeSection = this.tableTitle;
        }
    }
}