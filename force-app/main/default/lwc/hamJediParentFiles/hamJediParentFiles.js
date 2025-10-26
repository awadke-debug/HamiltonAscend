import { LightningElement, api, track, wire } from 'lwc';
import getAccountFiles from '@salesforce/apex/HAMJediParentFilesController.getAccountFiles';
import getAccountIdFromContact from '@salesforce/apex/HAMJediParentFilesController.getAccountIdFromContact';
import { CurrentPageReference } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { RefreshEvent } from 'lightning/refresh';

export default class HamJediParentFiles extends LightningElement {
    // =========================================
    // Accordion / Context
    // =========================================
    @track activeFileSection = 'Files';
    @api recordId;           // Contact ID from URL
    @track accountId = null; // Account ID retrieved from Contact
    @track loading = false;

    // =========================================
    // Data model
    // =========================================
    @track allFiles = [];
    @track pageFiles = [];

    // =========================================
    // Sorting state
    // =========================================
    @track sortedBy = 'createdDate';
    @track sortedDirection = 'desc';

    // =========================================
    // Pagination
    // =========================================
    @track pageSize = 10;
    @track pageNumber = 1;
    @track totalRecords = 0;

    // =========================================
    // File Upload
    // =========================================
    @track uploadInProgress = false;
    acceptedFormats = ['.pdf', '.doc', '.docx', '.xls', '.xlsx', '.ppt', '.pptx', '.txt', '.jpg', '.jpeg', '.png', '.gif'];

    // =========================================
    // Derived helpers for UI controls
    // =========================================
    get totalPages() {
        return Math.max(1, Math.ceil(this.totalRecords / this.pageSize));
    }

    get isFirstPage() {
        return this.pageNumber <= 1;
    }

    get isLastPage() {
        return this.pageNumber >= this.totalPages || this.totalRecords === 0;
    }

    get noFilesMessage() {
        return this.totalRecords === 0 ? 'No files found for this Account' : '';
    }

    // =========================================
    // Datatable columns
    // =========================================
    @track filesColumns = [
        {
            label: 'Name',
            fieldName: 'recordLink',
            type: 'url',
            typeAttributes: {
                label: { fieldName: 'fileName' },
                target: '_blank'
            },
            sortable: true
        },
        {
            label: 'Created Date',
            fieldName: 'createdDate',
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
            label: 'File Type',
            fieldName: 'fileExtension',
            type: 'text',
            sortable: true
        },
        {
            label: 'Size (bytes)',
            fieldName: 'fileSize',
            type: 'number',
            sortable: true
        }
    ];

    // =========================================
    // Read recordId from URL and load data
    // =========================================
    // Wire adapter that captures Contact ID from URL parameters and retrieves Account ID
    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference?.state?.c__recordId) {
            this.recordId = currentPageReference.state.c__recordId;
            console.log('Contact ID captured from URL:', this.recordId);
            this.getAccountId();
        }
    }

    // Retrieve Account ID from Contact record to use with lightning-file-upload
    getAccountId() {
        this.loading = true;
        console.log('Retrieving Account ID for Contact:', this.recordId);
        
        getAccountIdFromContact({ contactId: this.recordId })
            .then(result => {
                this.accountId = result;
                console.log('Account ID retrieved:', this.accountId);
                this.loadFiles();
            })
            .catch(error => {
                console.error('Error getting Account ID:', error);
                console.error('Error body:', error.body);
                this.showToast('Error', 'Failed to retrieve Account ID', 'error');
                this.loading = false;
            });
    }

    // Fetch all files from the Account linked to the Contact using the Apex controller
    loadFiles() {
        this.loading = true;
        console.log('loadFiles called with recordId:', this.recordId);

        getAccountFiles({ contactId: this.recordId })
            .then(result => {
                console.log('getAccountFiles result:', result);
                const rows = result || [];
                console.log('Number of files:', rows.length);

                this.allFiles = rows.map(r => ({
                    ...r,
                    recordLink: `/lightning/r/${r.fileId}/view`
                }));

                this.totalRecords = this.allFiles.length;
                console.log('totalRecords set to:', this.totalRecords);

                // Apply default sort
                this.sortFileData(this.sortedBy, this.sortedDirection);

                // Reset pagination
                this.pageNumber = 1;
                this.derivePage();

                // Ensure section is open
                this.activeFileSection = 'Files';
            })
            .catch(error => {
                console.error('Error fetching Account Files:', error);
                console.error('Error body:', error.body);
                this.showToast('Error', 'Failed to load files', 'error');
                this.allFiles = [];
                this.pageFiles = [];
                this.totalRecords = 0;
                this.pageNumber = 1;
            })
            .finally(() => {
                console.log('loadFiles finally - setting loading to false');
                this.loading = false;
            });
    }

    // Compute the current page slice from the full allFiles array based on pageNumber and pageSize
    derivePage() {
        const start = (this.pageNumber - 1) * this.pageSize;
        const end = start + this.pageSize;
        this.pageFiles = this.allFiles.slice(start, end);
    }

    // Navigate to the next page if not already on the last page
    nextPage() {
        if (!this.isLastPage) {
            this.pageNumber += 1;
            this.derivePage();
        }
    }

    // Navigate to the previous page if not already on the first page
    prevPage() {
        if (!this.isFirstPage) {
            this.pageNumber -= 1;
            this.derivePage();
        }
    }

    // Handle accordion section toggle to track which sections are open
    handleFileSectionToggle(event) {
        const openedSections = event.detail.openSections;
        if (Array.isArray(openedSections)) {
            this.activeFileSection = openedSections.includes('Files') ? 'Files' : '';
        } else {
            this.activeFileSection = openedSections === 'Files' ? 'Files' : '';
        }
    }

    // Handle datatable column sorting by updating sort state and re-sorting the data
    handleFileSort(event) {
        const { fieldName: sortedBy, sortDirection } = event.detail;
        this.sortedBy = sortedBy;
        this.sortedDirection = sortDirection;

        this.sortFileData(sortedBy, sortDirection);

        this.pageNumber = 1;
        this.derivePage();
    }

    // Sort the allFiles array by the specified field and direction, handling dates and numbers correctly
    sortFileData(field, direction) {
        const dir = direction === 'desc' ? -1 : 1;

        this.allFiles = [...this.allFiles].sort((a, b) => {
            let va = a[field] ?? '';
            let vb = b[field] ?? '';

            // Handle date fields
            if (field === 'createdDate') {
                va = va ? new Date(va) : new Date(0);
                vb = vb ? new Date(vb) : new Date(0);
            } else if (field === 'fileSize') {
                va = va || 0;
                vb = vb || 0;
            } else {
                va = va.toString().toLowerCase();
                vb = vb.toString().toLowerCase();
            }

            if (va === vb) return 0;
            return va > vb ? dir : -dir;
        });
    }

    // Handle file upload completion event from lightning-file-upload component
    handleUploadFinished(event) {
        const uploadedFiles = event.detail.files;
        console.log('Upload finished, files:', uploadedFiles);
        
        if (uploadedFiles && uploadedFiles.length > 0) {
            console.log('File successfully uploaded to Account');
            this.uploadInProgress = false;
            this.showToast('Success', 'File uploaded successfully', 'success');
            
            // Refresh the file list immediately
            console.log('Calling loadFiles after upload...');
            this.loadFiles();
            console.log('loadFiles called');
            
            // Dispatch RefreshEvent to refresh standard components on the page
            this.dispatchEvent(new RefreshEvent());
        }
    }

    // Display a toast notification with the specified title, message, and variant (success, error, warning, info)
    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: variant
            })
        );
    }
}