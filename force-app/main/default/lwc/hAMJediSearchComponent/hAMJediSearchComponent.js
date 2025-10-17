import { LightningElement, track } from 'lwc';
import searchContact from '@salesforce/apex/HAMJediSearchController.searchContact';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';

export default class hAMJediSearchComponent extends NavigationMixin(LightningElement) {
    // =========================================
    // Search inputs
    // =========================================
    @track nameSearchString = '';
    @track donorIdStr = '';
    @track loading = false;

    // =========================================
    // Data model
    // =========================================
    @track allConstituents = [];      // full, sorted dataset; pagination slices from here
    @track pageConstituents = [];     // current page rows bound to the datatable

    // =========================================
    // Sorting state
    // =========================================
    @track sortBy;
    @track sortDirection;

    // =========================================
    // Pagination (grouped here intentionally)
    // =========================================
    @track pageSize = 10;     // rows per page
    @track pageNumber = 1;    // 1-based index
    @track totalRecords = 0;  // derived from allConstituents.length

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

    // Compute current page slice from allConstituents → pageConstituents
    derivePage() {
        const start = (this.pageNumber - 1) * this.pageSize;
        const end = start + this.pageSize;
        this.pageConstituents = this.allConstituents.slice(start, end);
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

    // =========================================
    // Error handling
    // =========================================
    @track errorStr;
    @track error;

    // =========================================
    // Datatable columns (sorting supported)
    // =========================================
    columns = [
        {
            label: 'Name',
            type: 'button',
            typeAttributes: {
                label: { fieldName: 'HAM_Name_w_Suffix__c' },
                name: 'view_prospect',
                variant: 'base'
            },
        },
        { 
            label: 'Donor Id', 
            fieldName: 'ucinn_ascendv2__Donor_ID__c', 
            type: 'Text', 
            sortable: true 
        },
        { 
            label: 'Primary Contact Type', 
            fieldName: 'ucinn_ascendv2__Primary_Contact_Type__c', 
            type: 'Text', 
            sortable: true 
        },
    ];

    // =========================================
    // Input handlers
    // =========================================
    handleInputChange(event) {
        const field = event.target.name;
        if (field === 'nameSearch') {
            this.nameSearchString = event.target.value;
        } else if (field === 'donorId') {
            this.donorIdStr = event.target.value;
        }
    }

    // =========================================
    // Search functionality
    // =========================================
    searchConstituents(event) {
        if (this.nameSearchString != '' || this.donorIdStr != '') {
            this.loading = true;
            searchContact({ searchStr: this.nameSearchString, donorId: this.donorIdStr })
                .then((data) => {
                    const rows = Array.isArray(data) ? data : [];
                    
                    // Add recordLink for future use (keeping your existing logic)
                    this.allConstituents = rows.map(row => ({
                        ...row,
                        recordLink: `/lightning/r/Contact/${row.Id}/view`
                    }));

                    this.totalRecords = this.allConstituents.length;

                    // Reset to first page and compute slice
                    this.pageNumber = 1;
                    this.derivePage();

                    if (this.totalRecords === 0) {
                        this.showNoDataToast();
                    }
                    this.error = undefined;
                })
                .catch((error) => {
                    this.errorStr = 'Error: ' + JSON.stringify(error);
                    this.allConstituents = [];
                    this.pageConstituents = [];
                    this.totalRecords = 0;
                    this.pageNumber = 1;
                })
                .finally(() => {
                    this.loading = false;
                });
        }
    }

    clearData(event) {
        this.nameSearchString = '';
        this.donorIdStr = '';

        // Reset all data and pagination
        this.allConstituents = [];
        this.pageConstituents = [];
        this.totalRecords = 0;
        this.pageNumber = 1;
    }

    // =========================================
    // Datatable sort handler
    // =========================================
    doSorting(event) {
        this.loading = true;
        this.sortBy = event.detail.fieldName;
        this.sortDirection = event.detail.sortDirection;
        
        // Sort the full dataset, then re-slice current page
        this.sortData(this.sortBy, this.sortDirection);
        
        // Reset to first page after sorting and compute slice
        this.pageNumber = 1;
        this.derivePage();
        
        this.loading = false;
    }

    sortData(fieldname, direction) {
        const dir = direction === 'desc' ? -1 : 1;

        this.allConstituents = [...this.allConstituents].sort((a, b) => {
            const va = (a[fieldname] ?? '').toString().toLowerCase();
            const vb = (b[fieldname] ?? '').toString().toLowerCase();
            if (va === vb) return 0;
            return va > vb ? dir : -dir;
        });
    }

    // =========================================
    // Toast and navigation
    // =========================================
    showNoDataToast() {
        const event = new ShowToastEvent({
            title: 'No Records Found',
            message: 'No account records were found.',
            variant: 'info'
        });
        this.dispatchEvent(event);
    }

    handleRowAction(event) {
    const actionName = event.detail.action.name;
    const row = event.detail.row;
        
    if (!row || !row.Id) {
        console.error('Row data is missing:', event.detail);
        return;
    }

    if (actionName === 'view_prospect') {
        const recordId = row.Id;
        
        // Generate the URL first, then open in new tab
        this[NavigationMixin.GenerateUrl]({
            type: 'standard__navItemPage',
            attributes: {
                apiName: 'JEDI_Overview'
            },
            state: {
                c__recordId: recordId
            }
        }).then(url => {
            window.open(url, '_blank', 'noopener,noreferrer');
        }).catch(error => {
            console.error('Navigation error:', error);
        });
    }
}
}