import { LightningElement, api, track, wire } from 'lwc';
import getEventsDetail from '@salesforce/apex/HAMJediEventController.getEventsDetail';
import { CurrentPageReference } from 'lightning/navigation';
import { NavigationMixin } from 'lightning/navigation';

export default class HamJediEvents extends LightningElement {
    // =========================================
    // Accordion / Context
    // =========================================
    @track activeEventSection = 'Events';
    @api recordId;
    @track loading = false; // spinner flag

    // =========================================
    // Data model
    // =========================================
    @track allEvents = [];     // full, sorted dataset; pagination slices from here
    @track pageEvents = [];    // current page rows bound to the datatable

    // =========================================
    // Sorting state
    // =========================================
    @track sortedBy = 'Name';
    @track sortedDirection = 'asc';

    // =========================================
    // Pagination (grouped here intentionally)
    // =========================================
    @track pageSize = 10;     // rows per page
    @track pageNumber = 1;    // 1-based index
    @track totalRecords = 0;  // derived from allEvents.length

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

    // Compute current page slice from allEvents → pageEvents
    derivePage() {
        const start = (this.pageNumber - 1) * this.pageSize;
        const end = start + this.pageSize;
        this.pageEvents = this.allEvents.slice(start, end);
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
    @track eventsColumns = [
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
            label: 'Event Name',
            fieldName: 'conference360__Event_Name__c',
            type: 'text',
            sortable: true
        },
        {
            label: 'Event Date',
            fieldName: 'conference360__Event_End_Date_Time__c',
            type: 'date',
            typeAttributes: {
                year: 'numeric',
                month: 'short',
                day: '2-digit',
                hour: '2-digit',
                minute: '2-digit'
            },
            sortable: true
        },
        {
            label: 'Attendance Status',
            fieldName: 'conference360__Attendance_Status__c',
            type: 'text',
            sortable: true
        },
        {
            label: 'Registration Status',
            fieldName: 'conference360__Registration_Status__c',
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
            this.loading = true;

            getEventsDetail({ contactId: this.recordId })
                .then(result => {
                    const rows = result || [];

                    // Add recordLink for the Name URL column without mutating original rows
                    this.allEvents = rows.map(r => ({
                        ...r,
                        recordLink: `/lightning/r/${r.Id}/view`
                    }));

                    this.totalRecords = this.allEvents.length;

                    // Apply default sort once (sortedBy/sortedDirection)
                    this.sortEventData(this.sortedBy, this.sortedDirection);

                    // [pagination] reset to first page and compute slice
                    this.pageNumber = 1;
                    this.derivePage();

                    // Ensure the Events section is open
                    this.activeEventSection = 'Events';
                })
                .catch(error => {
                    console.error('Error fetching Events:', error);
                    this.allEvents = [];
                    this.pageEvents = [];
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
    handleEventSectionToggle(event) {
        const openedSections = event.detail.openSections;
        if (Array.isArray(openedSections)) {
            this.activeEventSection = openedSections.includes('Events') ? 'Events' : '';
        } else {
            this.activeEventSection = openedSections === 'Events' ? 'Events' : '';
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

        // [pagination] after sorting full dataset, show first page of new order
        this.pageNumber = 1;
        this.derivePage();
    }

    // Core sort routine. We always sort allEvents so pagination stays consistent.
    sortEventData(field, direction) {
        const key = field === 'recordLink' ? 'Name' : field; // sort by Name when link column is clicked
        const dir = direction === 'desc' ? -1 : 1;

        this.allEvents = [...this.allEvents].sort((a, b) => {
            let va = a[key] ?? '';
            let vb = b[key] ?? '';
            
            // Handle date fields specially for proper sorting
            if (field === 'conference360__Event_End_Date_Time__c') {
                va = va ? new Date(va) : new Date(0);
                vb = vb ? new Date(vb) : new Date(0);
            } else {
                va = va.toString().toLowerCase();
                vb = vb.toString().toLowerCase();
            }
            
            if (va === vb) return 0;
            return va > vb ? dir : -dir;
        });
    }
}