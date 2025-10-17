import { LightningElement, api, track, wire } from 'lwc';
import getEmailDetail from '@salesforce/apex/HAMJediEventController.getEmailDetail';
import { CurrentPageReference } from 'lightning/navigation';
import { NavigationMixin } from 'lightning/navigation';

export default class HamJEDIEmailActivities extends LightningElement {

    @track activeEmailSection = 'Emails';
    @api recordId;
    @track loading = false; 

    @track allEmails = []; // full dataset cached after fetch
    @track emailDetails = []; // holds only the current page slice

    @track sortedBy = 'Name'; 
    @track sortedDirection = 'asc';

    // ================================
    // Pagination state & helpers
    // ================================
    @track pageSize = 10;    
    @track pageNumber = 1;   
    @track totalRecords = 0; 

    get totalPages() {
        return Math.max(1, Math.ceil(this.totalRecords / this.pageSize));
    }
    get isFirstPage() {
        return this.pageNumber <= 1;
    }
    get isLastPage() {
        return this.pageNumber >= this.totalPages || this.totalRecords === 0;
    }
    derivePage() {
        const start = (this.pageNumber - 1) * this.pageSize;
        const end = start + this.pageSize;
        this.emailDetails = this.allEmails.slice(start, end);
    }
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
    // ================================

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
        }
    ];

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference?.state?.c__recordId) {
            this.recordId = currentPageReference.state.c__recordId;
            this.loading = true;

            getEmailDetail({ contactId: this.recordId })
                .then(result => {
                    const rows = result || [];
                    this.allEmails = rows.map(r => ({
                        ...r,
                        recordLink: `/lightning/r/${r.Id}/view`
                    }));
                    this.totalRecords = this.allEmails.length;
                    this.pageNumber = 1;
                    this.derivePage();
                    this.activeEmailSection = 'Emails';
                })
                .catch(error => {
                    console.error('Error fetching Eamils:', error);
                    this.allEmails = [];
                    this.emailDetails = [];
                    this.totalRecords = 0;
                    this.pageNumber = 1;
                })
                .finally(() => {
                    this.loading = false;
                });
        }
    }

    handleEmailSectionToggle(event) {
        const openedSections = event.detail.openSections;
        if (Array.isArray(openedSections)) {
            this.activeEmailSection = openedSections.includes('Emails') ? 'Emails' : '';
        } else {
            this.activeEmailSection = openedSections === 'Emails' ? 'Emails' : '';
        }
    }

    handlEmailSort(event) {
        const { fieldName: sortedBy, sortDirection } = event.detail;
        this.sortedBy = sortedBy;
        this.sortedDirection = sortDirection;
        this.sortEmailData(sortedBy, sortDirection);
        this.pageNumber = 1;
        this.derivePage();
    }

    sortEmailData(field, direction) {
        const key = field === 'recordLink' ? 'Name' : field;
        const dir = direction === 'desc' ? -1 : 1;

        this.allEmails = [...this.allEmails].sort((a, b) => {
            const va = (a[key] ?? '').toString().toLowerCase();
            const vb = (b[key] ?? '').toString().toLowerCase();
            if (va === vb) return 0;
            return va > vb ? dir : -dir;
        });
    }
}