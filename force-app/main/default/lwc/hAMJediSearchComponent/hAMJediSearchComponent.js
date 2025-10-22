import { LightningElement, track } from 'lwc';
import searchContact from '@salesforce/apex/HAMJediSearchController.searchContact';
import getClassYearOptions from '@salesforce/apex/HAMJediSearchController.getClassYearOptions';
import getSportsAssociationOptions from '@salesforce/apex/HAMJediSearchController.getSportsAssociationOptions';
import getStudentOrganizationsOptions from '@salesforce/apex/HAMJediSearchController.getStudentOrganizationsOptions';
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
    // Picklist options - Options arrays from Apex
    // =========================================
    @track classYearOptions = [];          // Class Year values from HAM_Reunion_Year__c
    @track sportsAssociationOptions = [];  // Sports Association from Involvement_Value__c (NCAA Athletics)
    @track studentOrganizationOptions = []; // Student Organizations from Involvement_Value__c (Clubs & Societies)

    // =========================================
    // Picklist selected values
    // =========================================
    @track selectedClassYear = '';         // Selected Class Year value
    @track selectedSportsAssociation = ''; // Selected Sports Association value
    @track selectedStudentOrganization = ''; // Selected Student Organization value

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
    // Component initialization
    // =========================================
    connectedCallback() {
        this.loadClassYearOptions();
        this.loadSportsAssociationOptions();
        this.loadStudentOrganizationsOptions();
    }

    // Fetch Class Year options from Apex
    loadClassYearOptions() {
        getClassYearOptions()
            .then((data) => {
                // Convert string array to combobox format
                this.classYearOptions = [
                    { label: 'Select Class Year', value: '' },
                    ...data.map(year => ({
                        label: year,
                        value: year
                    }))
                ];
                console.log('Class Year options loaded:', this.classYearOptions);
            })
            .catch((error) => {
                console.error('Error loading class years:', error);
                this.showErrorToast('Error loading class year options');
            });
    }

    // Fetch Sports Association options from Apex
    loadSportsAssociationOptions() {
        getSportsAssociationOptions()
            .then((data) => {
                // Convert string array to combobox format
                this.sportsAssociationOptions = [
                    { label: 'Select Sports Association', value: '' },
                    ...data.map(sport => ({
                        label: sport,
                        value: sport
                    }))
                ];
                console.log('Sports Association options loaded:', this.sportsAssociationOptions);
            })
            .catch((error) => {
                console.error('Error loading sports associations:', error);
                this.showErrorToast('Error loading sports association options');
            });
    }

    // Fetch Student Organizations options from Apex
    loadStudentOrganizationsOptions() {
        getStudentOrganizationsOptions()
            .then((data) => {
                // Convert string array to combobox format
                this.studentOrganizationOptions = [
                    { label: 'Select Student Organization', value: '' },
                    ...data.map(org => ({
                        label: org,
                        value: org
                    }))
                ];
                console.log('Student Organizations options loaded:', this.studentOrganizationOptions);
            })
            .catch((error) => {
                console.error('Error loading student organizations:', error);
                this.showErrorToast('Error loading student organizations options');
            });
    }

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

    handlePicklistChange(event) {
        const field = event.target.name;
        const value = event.detail.value;

        if (field === 'Picklist1') {
            this.selectedClassYear = value;
        } else if (field === 'Picklist2') {
            this.selectedSportsAssociation = value;
        } else if (field === 'Picklist3') {
            this.selectedStudentOrganization = value;
        }
    }

    // =========================================
    // Search functionality
    // =========================================
    searchConstituents(event) {
        if (this.nameSearchString != '' || this.donorIdStr != '' || this.selectedClassYear != '' || this.selectedSportsAssociation != '' || this.selectedStudentOrganization != '') {
            this.loading = true;
            searchContact({ 
                searchStr: this.nameSearchString, 
                donorId: this.donorIdStr,
                classYear: this.selectedClassYear,
                sportsAssociation: this.selectedSportsAssociation,
                studentOrganization: this.selectedStudentOrganization
            })
                .then((data) => {
                    const rows = Array.isArray(data) ? data : [];
                    
                    // Add recordLink for future use
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
        this.selectedClassYear = '';
        this.selectedSportsAssociation = '';
        this.selectedStudentOrganization = '';

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
            message: 'No constituent records were found.',
            variant: 'info'
        });
        this.dispatchEvent(event);
    }

    showErrorToast(message) {
        const event = new ShowToastEvent({
            title: 'Error',
            message: message,
            variant: 'error'
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