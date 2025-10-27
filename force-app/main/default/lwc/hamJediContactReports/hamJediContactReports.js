import { LightningElement, api, track, wire } from 'lwc';
import getContactReportDetail from '@salesforce/apex/HAMJediContactReportController.getContactReportDetail';
import { CurrentPageReference } from 'lightning/navigation';

export default class HamJediContactReports extends LightningElement {
    // =========================================
    // Accordion / Context
    // =========================================
    @track activeReportSection = 'Contact Reports';
    @api recordId;
    @track loading = false; // spinner flag

    // =========================================
    // Data model
    // =========================================
    @track allContactReports = [];  // full, sorted dataset; pagination slices from here
    @track pageReports = [];        // current page rows bound to the datatable

    // =========================================
    // Sorting state
    // =========================================
    @track sortedBy = 'ucinn_ascendv2__Date__c';
    @track sortedDirection = 'desc';

    // =========================================
    // Pagination (grouped here intentionally)
    // =========================================
    @track pageSize = 10;     // rows per page
    @track pageNumber = 1;    // 1-based index
    @track totalRecords = 0;  // derived from allContactReports.length

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

    // Compute current page slice from allContactReports → pageReports
    derivePage() {
        const start = (this.pageNumber - 1) * this.pageSize;
        const end = start + this.pageSize;
        this.pageReports = this.allContactReports.slice(start, end);
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

    // Modal and Flow
    @track isFlowModalOpen = false;
    @track flowInputVariables = [];

    // =========================================
    // Datatable columns (sorting supported)
    // =========================================
    @track contactReportColumns = [
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
            label: 'Contact Method',
            fieldName: 'ucinn_ascendv2__Contact_Method__c',
            type: 'text',
            sortable: true
        },
        {
            label: 'Substantive Contact',
            fieldName: 'ucinn_ascendv2__Substantive_Contact__c',
            type: 'text',
            sortable: true
        },
        {
            label: 'Description',
            fieldName: 'ucinn_ascendv2__Description__c',
            type: 'text',
            sortable: true
        },
        {
            label: 'Contact Report Body',
            fieldName: 'ucinn_ascendv2__Contact_Report_Body__c',
            type: 'text',
            sortable: true
        },
        {
            label: 'Date',
            fieldName: 'ucinn_ascendv2__Date__c',
            type: 'date',
            sortable: true
        },
        {
            label: 'PRM at Time of Meeting',
            fieldName: 'HAM_PRM_at_Time_of_Meeting__c',
            type: 'text',
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
            this.fetchContactReports();
        }
    }

    fetchContactReports() {
        this.loading = true;

        getContactReportDetail({ contactId: this.recordId })
            .then(result => {
                const rows = result || [];

                // Add recordLink for the Name URL column without mutating original rows
                this.allContactReports = rows.map(r => ({
                    ...r,
                    recordLink: `/lightning/r/${r.Id}/view`
                }));

                this.totalRecords = this.allContactReports.length;

                // Apply default sort once (sortedBy/sortedDirection)
                this.sortContactReportData(this.sortedBy, this.sortedDirection);

                // [pagination] reset to first page and compute slice
                this.pageNumber = 1;
                this.derivePage();

                // Ensure the Contact Reports section is open
                this.activeReportSection = 'Contact Reports';
            })
            .catch(error => {
                console.error('Error fetching Contact Reports:', error);
                this.allContactReports = [];
                this.pageReports = [];
                this.totalRecords = 0;

                // [pagination] reset page state on error
                this.pageNumber = 1;
            })
            .finally(() => {
                this.loading = false; // stop spinner either way
            });
    }

    // =========================================
    // Accordion toggle handler
    // =========================================
    handleReportSectionToggle(event) {
        const openedSections = event.detail.openSections;
        if (Array.isArray(openedSections)) {
            this.activeReportSection = openedSections.includes('Contact Reports') ? 'Contact Reports' : '';
        } else {
            this.activeReportSection = openedSections === 'Contact Reports' ? 'Contact Reports' : '';
        }
    }

    // =========================================
    // Datatable sort handler
    // =========================================
    handleReportSort(event) {
        const { fieldName: sortedBy, sortDirection } = event.detail;
        this.sortedBy = sortedBy;
        this.sortedDirection = sortDirection;

        this.sortContactReportData(sortedBy, sortDirection);

        // [pagination] after sorting full dataset, show first page of new order
        this.pageNumber = 1;
        this.derivePage();
    }

    // Core sort routine. We always sort allContactReports so pagination stays consistent.
    sortContactReportData(field, direction) {
        const key = field === 'recordLink' ? 'Name' : field; // sort by Name when link column is clicked
        const dir = direction === 'desc' ? -1 : 1;

        this.allContactReports = [...this.allContactReports].sort((a, b) => {
            const va = (a[key] ?? '').toString().toLowerCase();
            const vb = (b[key] ?? '').toString().toLowerCase();
            if (va === vb) return 0;
            return va > vb ? dir : -dir;
        });
    }

    // =========================================
    // Modal Flow Methods
    // =========================================
    openFlowModal() {
        this.flowInputVariables = [
            {
                name: 'contactId',
                type: 'String',
                value: this.recordId
            }
        ];
        console.log('Flow Variable-------', this.flowInputVariables);
        this.isFlowModalOpen = true;
    }

    closeFlowModal() {
        this.isFlowModalOpen = false;
    }

    handleFlowStatusChange(event) {
        if (event.detail.status === 'FINISHED' || event.detail.status === 'FINISHED_SCREEN') {
            this.closeFlowModal();
            this.fetchContactReports(); // refresh after flow
        }
    }
}