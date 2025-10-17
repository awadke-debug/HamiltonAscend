import { LightningElement, api, track, wire } from 'lwc';
import getactivityDetails from '@salesforce/apex/HAMJediActivityController.getactivityDetails';
import { CurrentPageReference } from 'lightning/navigation';
import { NavigationMixin } from 'lightning/navigation';

export default class HamJediActivities extends LightningElement {
    // =========================================
    // Core Properties
    // =========================================
    @track activeEventSection = 'Events';
    @api recordId;
    @track loading = false;
    @track wrapperDate = [];

    // =========================================
    // Upcoming Meetings Data & Pagination
    // =========================================
    @track allUpcomingEvents = [];
    @track pageUpcomingEvents = [];
    @track upcomingPageSize = 10;
    @track upcomingPageNumber = 1;
    @track upcomingTotalRecords = 0;
    @track upcomingSortedBy = 'StartDateTime';
    @track upcomingSortedDirection = 'asc';

    // Upcoming meetings computed properties
    get upcomingTotalPages() {
        return Math.max(1, Math.ceil(this.upcomingTotalRecords / this.upcomingPageSize));
    }
    get isUpcomingFirstPage() {
        return this.upcomingPageNumber <= 1;
    }
    get isUpcomingLastPage() {
        return this.upcomingPageNumber >= this.upcomingTotalPages || this.upcomingTotalRecords === 0;
    }
    get showUpcomingPagination() {
        return this.upcomingTotalRecords > 10;
    }

    // =========================================
    // Completed Meetings Data & Pagination
    // =========================================
    @track allCompletedEvents = [];
    @track pageCompletedEvents = [];
    @track completedPageSize = 10;
    @track completedPageNumber = 1;
    @track completedTotalRecords = 0;
    @track completedSortedBy = 'StartDateTime';
    @track completedSortedDirection = 'desc';

    // Completed meetings computed properties
    get completedTotalPages() {
        return Math.max(1, Math.ceil(this.completedTotalRecords / this.completedPageSize));
    }
    get isCompletedFirstPage() {
        return this.completedPageNumber <= 1;
    }
    get isCompletedLastPage() {
        return this.completedPageNumber >= this.completedTotalPages || this.completedTotalRecords === 0;
    }
    get showCompletedPagination() {
        return this.completedTotalRecords > 10;
    }

    // =========================================
    // Rejected Meetings Data & Pagination
    // =========================================
    @track allRejectedEvents = [];
    @track pageRejectedEvents = [];
    @track rejectedPageSize = 10;
    @track rejectedPageNumber = 1;
    @track rejectedTotalRecords = 0;
    @track rejectedSortedBy = 'StartDateTime';
    @track rejectedSortedDirection = 'desc';

    // Rejected meetings computed properties
    get rejectedTotalPages() {
        return Math.max(1, Math.ceil(this.rejectedTotalRecords / this.rejectedPageSize));
    }
    get isRejectedFirstPage() {
        return this.rejectedPageNumber <= 1;
    }
    get isRejectedLastPage() {
        return this.rejectedPageNumber >= this.rejectedTotalPages || this.rejectedTotalRecords === 0;
    }
    get showRejectedPagination() {
        return this.rejectedTotalRecords > 10;
    }

    // =========================================
    // Open Tasks Data & Pagination
    // =========================================
    @track allOpenTasks = [];
    @track pageOpenTasks = [];
    @track tasksPageSize = 10;
    @track tasksPageNumber = 1;
    @track tasksTotalRecords = 0;
    @track tasksSortedBy = 'ActivityDate';
    @track tasksSortedDirection = 'asc';

    // Open tasks computed properties
    get tasksTotalPages() {
        return Math.max(1, Math.ceil(this.tasksTotalRecords / this.tasksPageSize));
    }
    get isTasksFirstPage() {
        return this.tasksPageNumber <= 1;
    }
    get isTasksLastPage() {
        return this.tasksPageNumber >= this.tasksTotalPages || this.tasksTotalRecords === 0;
    }
    get showTasksPagination() {
        return this.tasksTotalRecords > 10;
    }

    // =========================================
    // Column Definitions
    // =========================================
    @track eventColumns = [
        {
            label: 'Subject',
            fieldName: 'recordLink',
            type: 'url',
            typeAttributes: {
                label: { fieldName: 'Subject' },
                target: '_blank'
            },
            sortable: true
        },
        {
            label: 'Start Date',
            fieldName: 'StartDateTime',
            type: 'date',
            typeAttributes: {
                year: "numeric",
                month: "short",
                day: "2-digit",
                hour: "2-digit",
                minute: "2-digit"
            },
            sortable: true
        },
        {
            label: 'Owner',
            fieldName: 'OwnerName',
            type: 'text',
            sortable: true
        },
        {
            label: 'Who',
            fieldName: 'WhoLink',
            type: 'url',
            typeAttributes: {
                label: { fieldName: 'WhoName' },
                target: '_blank'
            },
            sortable: true
        },
        {
            label: 'Location',
            fieldName: 'Location',
            type: 'text',
            sortable: true
        },
        {
            label: 'Type',
            fieldName: 'Type',
            type: 'text',
            sortable: true
        },
        {
            label: 'Meeting Status',
            fieldName: 'HAM_Meeting_Status__c',
            type: 'text',
            sortable: true
        },
        {
            label: 'Cancellation Reason',
            fieldName: 'HAM_Meeting_cancellation_Reason__c',
            type: 'text',
            sortable: true
        },
        {
            label: 'In Person?',
            fieldName: 'HAM_In_Person__c',
            type: 'boolean',
            sortable: true
        },
        {
           label: 'Contact Report',
            fieldName: 'ContactReportLink',
            type: 'url',
            typeAttributes: {
                label: { fieldName: 'ContactReportName' },
                target: '_blank'
            },
            sortable: true
        },
        {
            label: 'Campus Stakeholders',
            fieldName: 'HAM_Campus_Stakeholders__c',
            type: 'text',
            sortable: true
        }
    ];

    // Logic to hide Cancellation Reason
    get eventColumnsNoCancelReason() {
        return this.eventColumns.filter(col => col.fieldName !== 'HAM_Meeting_cancellation_Reason__c');
    }

    @track taskColumns = [
        {
            label: 'Subject',
            fieldName: 'recordLink',
            type: 'url',
            typeAttributes: {
                label: { fieldName: 'Subject' },
                target: '_blank'
            },
            sortable: true
        },
        {
            label: 'Due Date',
            fieldName: 'ActivityDate',
            type: 'date',
            typeAttributes: {
                year: "numeric",
                month: "short",
                day: "2-digit"
            },
            sortable: true
        },
        {
            label: 'Status',
            fieldName: 'Status',
            type: 'text',
            sortable: true
        },
        {
            label: 'Who',
            fieldName: 'WhoName',
            type: 'text',
            sortable: true
        },
        {
            label: 'Contact Report',
            fieldName: 'ContactReportLink',
            type: 'url',
            typeAttributes: {
                label: { fieldName: 'ContactReportName' },
                target: '_blank'
            },
            sortable: true
        }
    ];

    // =========================================
    // Pagination Methods - Upcoming Meetings
    // =========================================
    deriveUpcomingPage() {
        const start = (this.upcomingPageNumber - 1) * this.upcomingPageSize;
        const end = start + this.upcomingPageSize;
        this.pageUpcomingEvents = this.allUpcomingEvents.slice(start, end);
    }

    nextUpcomingPage() {
        if (!this.isUpcomingLastPage) {
            this.upcomingPageNumber += 1;
            this.deriveUpcomingPage();
        }
    }

    prevUpcomingPage() {
        if (!this.isUpcomingFirstPage) {
            this.upcomingPageNumber -= 1;
            this.deriveUpcomingPage();
        }
    }

    // =========================================
    // Pagination Methods - Completed Meetings
    // =========================================
    deriveCompletedPage() {
        const start = (this.completedPageNumber - 1) * this.completedPageSize;
        const end = start + this.completedPageSize;
        this.pageCompletedEvents = this.allCompletedEvents.slice(start, end);
    }

    nextCompletedPage() {
        if (!this.isCompletedLastPage) {
            this.completedPageNumber += 1;
            this.deriveCompletedPage();
        }
    }

    prevCompletedPage() {
        if (!this.isCompletedFirstPage) {
            this.completedPageNumber -= 1;
            this.deriveCompletedPage();
        }
    }

    // =========================================
    // Pagination Methods - Rejected Meetings
    // =========================================
    deriveRejectedPage() {
        const start = (this.rejectedPageNumber - 1) * this.rejectedPageSize;
        const end = start + this.rejectedPageSize;
        this.pageRejectedEvents = this.allRejectedEvents.slice(start, end);
    }

    nextRejectedPage() {
        if (!this.isRejectedLastPage) {
            this.rejectedPageNumber += 1;
            this.deriveRejectedPage();
        }
    }

    prevRejectedPage() {
        if (!this.isRejectedFirstPage) {
            this.rejectedPageNumber -= 1;
            this.deriveRejectedPage();
        }
    }

    // =========================================
    // Pagination Methods - Open Tasks
    // =========================================
    deriveTasksPage() {
        const start = (this.tasksPageNumber - 1) * this.tasksPageSize;
        const end = start + this.tasksPageSize;
        this.pageOpenTasks = this.allOpenTasks.slice(start, end);
    }

    nextTasksPage() {
        if (!this.isTasksLastPage) {
            this.tasksPageNumber += 1;
            this.deriveTasksPage();
        }
    }

    prevTasksPage() {
        if (!this.isTasksFirstPage) {
            this.tasksPageNumber -= 1;
            this.deriveTasksPage();
        }
    }

    // =========================================
    // Sorting Methods - Upcoming Meetings
    // =========================================
    handleUpcomingSort(event) {
        const { fieldName: sortedBy, sortDirection } = event.detail;
        this.upcomingSortedBy = sortedBy;
        this.upcomingSortedDirection = sortDirection;

        this.sortUpcomingData(sortedBy, sortDirection);
        this.upcomingPageNumber = 1;
        this.deriveUpcomingPage();
    }

    sortUpcomingData(field, direction) {
        const key = field === 'recordLink' ? 'Subject' : (field === 'WhoLink' ? 'WhoName' : (field === 'ContactReportLink' ? 'ContactReportName' : field));
        const dir = direction === 'desc' ? -1 : 1;

        this.allUpcomingEvents = [...this.allUpcomingEvents].sort((a, b) => {
            let va = a[key] ?? '';
            let vb = b[key] ?? '';
            
            // Handle date fields specially
            if (field === 'StartDateTime') {
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

    // =========================================
    // Sorting Methods - Completed Meetings
    // =========================================
    handleCompletedSort(event) {
        const { fieldName: sortedBy, sortDirection } = event.detail;
        this.completedSortedBy = sortedBy;
        this.completedSortedDirection = sortDirection;

        this.sortCompletedData(sortedBy, sortDirection);
        this.completedPageNumber = 1;
        this.deriveCompletedPage();
    }

    sortCompletedData(field, direction) {
        const key = field === 'recordLink' ? 'Subject' : (field === 'WhoLink' ? 'WhoName' : (field === 'ContactReportLink' ? 'ContactReportName' : field));
        const dir = direction === 'desc' ? -1 : 1;

        this.allCompletedEvents = [...this.allCompletedEvents].sort((a, b) => {
            let va = a[key] ?? '';
            let vb = b[key] ?? '';
            
            // Handle date fields specially
            if (field === 'StartDateTime') {
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

    // =========================================
    // Sorting Methods - Rejected Meetings
    // =========================================
    handleRejectedSort(event) {
        const { fieldName: sortedBy, sortDirection } = event.detail;
        this.rejectedSortedBy = sortedBy;
        this.rejectedSortedDirection = sortDirection;

        this.sortRejectedData(sortedBy, sortDirection);
        this.rejectedPageNumber = 1;
        this.deriveRejectedPage();
    }

    sortRejectedData(field, direction) {
        const key = field === 'recordLink' ? 'Subject' : (field === 'WhoLink' ? 'WhoName' : (field === 'ContactReportLink' ? 'ContactReportName' : field));
        const dir = direction === 'desc' ? -1 : 1;

        this.allRejectedEvents = [...this.allRejectedEvents].sort((a, b) => {
            let va = a[key] ?? '';
            let vb = b[key] ?? '';
            
            // Handle date fields specially
            if (field === 'StartDateTime') {
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

    // =========================================
    // Sorting Methods - Open Tasks
    // =========================================
    handleTasksSort(event) {
        const { fieldName: sortedBy, sortDirection } = event.detail;
        this.tasksSortedBy = sortedBy;
        this.tasksSortedDirection = sortDirection;

        this.sortTasksData(sortedBy, sortDirection);
        this.tasksPageNumber = 1;
        this.deriveTasksPage();
    }

    sortTasksData(field, direction) {
        const key = field === 'recordLink' ? 'Subject' : (field === 'ContactReportLink' ? 'ContactReportName' : field);
        const dir = direction === 'desc' ? -1 : 1;

        this.allOpenTasks = [...this.allOpenTasks].sort((a, b) => {
            let va = a[key] ?? '';
            let vb = b[key] ?? '';
            
            // Handle date fields specially
            if (field === 'ActivityDate') {
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

    // =========================================
    // Data Loading
    // =========================================
    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference?.state?.c__recordId) {
            this.recordId = currentPageReference.state.c__recordId;
            this.loading = true;
            
            getactivityDetails({ contactId: this.recordId })
                .then(result => {
                    this.wrapperDate = result;
                    
                    // Process Upcoming Meetings
                    this.allUpcomingEvents = (result.upcomingMeeting || []).map(evt => ({
                        ...evt,
                        recordLink: `/lightning/r/Event/${evt.Id}/view`,
                        WhoName: evt.Who?.Name || '',
                        WhoLink: evt.WhoId ? `/lightning/r/Contact/${evt.WhoId}/view` : '',
                        OwnerName: evt.Owner?.Name || '',
                        ContactReportName: evt.HAM_Contact_Report__r?.Name || '',
                        ContactReportLink: evt.HAM_Contact_Report__c ? `/lightning/r/${evt.HAM_Contact_Report__c}/view` : ''
                    }));
                    this.upcomingTotalRecords = this.allUpcomingEvents.length;
                    this.sortUpcomingData(this.upcomingSortedBy, this.upcomingSortedDirection);
                    this.upcomingPageNumber = 1;
                    this.deriveUpcomingPage();

                    // Process Completed Meetings
                    this.allCompletedEvents = (result.pastMeeting || []).map(evt => ({
                        ...evt,
                        recordLink: `/lightning/r/Event/${evt.Id}/view`,
                        WhoName: evt.Who?.Name || '',
                        WhoLink: evt.WhoId ? `/lightning/r/Contact/${evt.WhoId}/view` : '',
                        OwnerName: evt.Owner?.Name || '',
                        ContactReportName: evt.HAM_Contact_Report__r?.Name || '',
                        ContactReportLink: evt.HAM_Contact_Report__c ? `/lightning/r/${evt.HAM_Contact_Report__c}/view` : ''
                    }));
                    this.completedTotalRecords = this.allCompletedEvents.length;
                    this.sortCompletedData(this.completedSortedBy, this.completedSortedDirection);
                    this.completedPageNumber = 1;
                    this.deriveCompletedPage();

                    // Process Rejected Meetings
                    this.allRejectedEvents = (result.rejectedMeeting || []).map(evt => ({
                        ...evt,
                        recordLink: `/lightning/r/Event/${evt.Id}/view`,
                        WhoName: evt.Who?.Name || '',
                        WhoLink: evt.WhoId ? `/lightning/r/Contact/${evt.WhoId}/view` : '',
                        OwnerName: evt.Owner?.Name || '',
                        ContactReportName: evt.HAM_Contact_Report__r?.Name || '',
                        ContactReportLink: evt.HAM_Contact_Report__c ? `/lightning/r/${evt.HAM_Contact_Report__c}/view` : ''
                    }));
                    this.rejectedTotalRecords = this.allRejectedEvents.length;
                    this.sortRejectedData(this.rejectedSortedBy, this.rejectedSortedDirection);
                    this.rejectedPageNumber = 1;
                    this.deriveRejectedPage();

                    // Process Open Tasks
                    this.allOpenTasks = (result.dueTask || []).map(task => ({
                        ...task,
                        recordLink: `/lightning/r/Task/${task.Id}/view`,
                        WhoName: task.Who?.Name || '',
                        WhoLink: task.WhoId ? `/lightning/r/Contact/${task.WhoId}/view` : '',
                        ContactReportName: task.What?.Name || '',
                        ContactReportLink: task.WhatId ? `/lightning/r/${task.WhatId}/view` : ''
                    }));
                    this.tasksTotalRecords = this.allOpenTasks.length;
                    this.sortTasksData(this.tasksSortedBy, this.tasksSortedDirection);
                    this.tasksPageNumber = 1;
                    this.deriveTasksPage();
                })
                .catch(error => {
                    console.error('Error fetching Activities:', error);
                    // Reset all data on error
                    this.allUpcomingEvents = [];
                    this.pageUpcomingEvents = [];
                    this.upcomingTotalRecords = 0;
                    this.allCompletedEvents = [];
                    this.pageCompletedEvents = [];
                    this.completedTotalRecords = 0;
                    this.allRejectedEvents = [];
                    this.pageRejectedEvents = [];
                    this.rejectedTotalRecords = 0;
                    this.allOpenTasks = [];
                    this.pageOpenTasks = [];
                    this.tasksTotalRecords = 0;
                })
                .finally(() => {
                    this.loading = false;
                });
        }
    }
}