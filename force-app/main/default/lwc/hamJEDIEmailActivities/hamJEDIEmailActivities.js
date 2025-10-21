import { LightningElement, api, track, wire } from 'lwc';
import getEmailDetail from '@salesforce/apex/HAMJediEventController.getEmailDetail';
import { CurrentPageReference } from 'lightning/navigation';
import { NavigationMixin } from 'lightning/navigation';

export default class HamJEDIEmailActivities extends LightningElement {
    // =========================================
    // Accordion / Context
    // =========================================
    @track activeEmailSection = 'Emails';
    @api recordId;
    @track loading = false; // spinner flag

    // =========================================
    // Data model
    // =========================================
    @track allEmails = [];     // full, sorted dataset; pagination slices from here
    @track emailDetails = [];  // current page rows bound to the datatable

    // =========================================
    // Sorting state
    // =========================================
    @track sortedBy = 'et4ae5__DateOpened__c';
    @track sortedDirection = 'desc';

    // =========================================
    // Pagination (grouped here intentionally)
    // =========================================
    @track pageSize = 10;     // rows per page
    @track pageNumber = 1;    // 1-based index
    @track totalRecords = 0;  // derived from allEmails.length

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

    // Compute current page slice from allEmails → emailDetails
    derivePage() {
        const start = (this.pageNumber - 1) * this.pageSize;
        const end = start + this.pageSize;
        this.emailDetails = this.allEmails.slice(start, end);
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
    // Datatable columns (sorting supported)
    // =========================================
    @track emailColumns = [
        {
            label: 'Name',
            fieldName: 'recordLink',
            type: 'url',
            typeAttributes: {
                label: { fieldName: 'Name' },
                target: '_blank'
            },
            sortable: true
        },
        {
            label: 'From Name',
            fieldName: 'et4ae5__FromName__c',
            type: 'text',
            sortable: true
        },
        {
            label: 'From Address',
            fieldName: 'et4ae5__FromAddress__c',
            type: 'text',
            sortable: true
        },
        {
            label: 'Subject Line',
            fieldName: 'et4ae5__SubjectLine__c',
            type: 'text',
            sortable: true
        },
        // Add other columns as needed; sorting will still work
        {
            label: 'Hard Bounce',
            fieldName: 'et4ae5__HardBounce__c',
            type: 'boolean',
            sortable: true
   
        },
        {
            label: 'Soft Bounce',
            fieldName: 'et4ae5__SoftBounce__c',
            type: 'boolean',
            sortable: true
        },
        {
            label: 'Date Bounced',
            fieldName: 'et4ae5__DateBounced__c',
            type: 'date',
            typeAttributes: { year: 'numeric', month: 'short', day: '2-digit', hour: '2-digit', minute: '2-digit' },
            sortable: true
        },
        {
            label: 'Opened',
            fieldName: 'et4ae5__Opened__c',
            type: 'boolean',
            sortable: true
        },
        {
            label: 'Date Opened',
            fieldName: 'et4ae5__DateOpened__c',
            type: 'date',
            typeAttributes: { year: 'numeric', month: 'short', day: '2-digit', hour: '2-digit', minute: '2-digit' },
            sortable: true
        },
        {
            label: 'Number of Total Clicks',
            fieldName: 'et4ae5__NumberOfTotalClicks__c',
            type: 'number',
            sortable: true
        },
        {
            label: 'Links Clicked',
            fieldName: 'et4ae5__NumberOfUniqueClicks__c',
            type: 'number',
            sortable: true
        }
    ];

    // =========================================
    // Read recordId from URL and load data
    // =========================================
    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference?.state?.c__recordId) {
            this.recordId = currentPageReference.state.c__recordId;
            this.loading = true;

            getEmailDetail({ contactId: this.recordId })
                .then(result => {
                    const rows = result || [];

                    // Add recordLink for the Name URL column without mutating original rows
                    this.allEmails = rows.map(r => ({
                        ...r,
                        recordLink: `/lightning/r/${r.Id}/view`
                    }));

                    this.totalRecords = this.allEmails.length;

                    // Apply default sort once (sortedBy/sortedDirection)
                    this.sortEmailData(this.sortedBy, this.sortedDirection);

                    // [pagination] reset to first page and compute slice
                    this.pageNumber = 1;
                    this.derivePage();

                    // Ensure the Emails section is open
                    this.activeEmailSection = 'Emails';
                })
                .catch(error => {
                    console.error('Error fetching Eamils:', error);
                    this.allEmails = [];
                    this.emailDetails = [];
                    this.totalRecords = 0;

                    // [pagination] reset page state on error
                    this.pageNumber = 1;
                })
                .finally(() => {
                    this.loading = false; // stop spinner either way
                });
        }
    }

    // =========================================
    // Accordion toggle handler
    // =========================================
    handleEmailSectionToggle(event) {
        const openedSections = event.detail.openSections;
        if (Array.isArray(openedSections)) {
            this.activeEmailSection = openedSections.includes('Emails') ? 'Emails' : '';
        } else {
            this.activeEmailSection = openedSections === 'Emails' ? 'Emails' : '';
        }
    }

    // =========================================
    // Datatable sort handler
    // =========================================
    handlEmailSort(event) {
        const { fieldName: sortedBy, sortDirection } = event.detail;
        this.sortedBy = sortedBy;
        this.sortedDirection = sortDirection;

        this.sortEmailData(sortedBy, sortDirection);

        // [pagination] after sorting full dataset, show first page of new order
        this.pageNumber = 1;
        this.derivePage();
    }

    // Core sort routine. We always sort allEmails so pagination stays consistent.
    sortEmailData(field, direction) {
        const key = field === 'recordLink' ? 'Name' : field; // sort by Name when link column is clicked
        const dir = direction === 'desc' ? -1 : 1;

        this.allEmails = [...this.allEmails].sort((a, b) => {
            const va = (a[key] ?? '').toString().toLowerCase();
            const vb = (b[key] ?? '').toString().toLowerCase();
            if (va === vb) return 0;
            return va > vb ? dir : -dir;
        });
    }
}