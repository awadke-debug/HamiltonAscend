import { LightningElement, api, track, wire } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import getFundsWithGroupedBeneficiaries from '@salesforce/apex/HAMJediEndowedFundRecipientsController.getFundsWithGroupedBeneficiaries';

export default class HamJEDIEndowedFundRecipients extends LightningElement {
    // =========================================
    // Context
    // =========================================
    @api recordId; // Can be set via component property
    @api designationId; // Deprecated - kept for backward compatibility
    contactId; // Will be extracted from URL or recordId
    @track loading = false;
    @track error;

    // =========================================
    // Data model
    // =========================================
    @track funds = []; // Array of FundWithBeneficiaries with pagination state
    @track mainSection = ['endowedFunds']; // Main section open by default

    // Pagination settings
    pageSize = 10;

    // =========================================
    // Datatable columns
    // =========================================
    columns = [
        {
            label: 'Year',
            fieldName: 'HAM_Sort_Fiscal_Year__c',
            type: 'text',
            sortable: true
        },
        {
            label: 'Student',
            fieldName: 'contactName',
            type: 'text',
            sortable: true
        },
        {
            label: 'Anonymous to Donor',
            fieldName: 'anonymousLabel',
            type: 'text',
            sortable: true,
            cellAttributes: {
                iconName: { fieldName: 'anonymousIcon' },
                iconAlternativeText: 'Anonymous Status'
            },
            fixedWidth: 200
        }
    ];

    // =========================================
    // Read contactId from URL
    // =========================================
    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference?.state?.c__recordId) {
            this.contactId = currentPageReference.state.c__recordId;
            console.log('Contact ID from URL:', this.contactId);
            this.loadFundsAndBeneficiaries();
        } else if (this.recordId) {
            this.contactId = this.recordId;
            console.log('Contact ID from recordId:', this.contactId);
            this.loadFundsAndBeneficiaries();
        } else {
            console.warn('No contactId found in URL or recordId property');
        }
    }

    loadFundsAndBeneficiaries() {
        if (!this.contactId) {
            console.warn('No contactId available to load funds');
            return;
        }

        console.log('Loading funds and beneficiaries for contact:', this.contactId);
        this.loading = true;
        this.error = undefined;

        getFundsWithGroupedBeneficiaries({ contactId: this.contactId })
            .then(result => {
                console.log('Apex result:', result);
                console.log('Number of funds returned:', result ? result.length : 0);

                // Process each fund - beneficiaries are already grouped in Apex
                this.funds = (result || []).map(fund => {
                    const processedBeneficiaries = (fund.beneficiaries || []).map(b => ({
                        ...b,
                        // Map fiscal year to expected field name
                        HAM_Sort_Fiscal_Year__c: b.fiscalYear,
                        // Semesters are already combined in Apex as List<String>
                        HAM_Award_Session__c: b.semesters && b.semesters.length > 0 ? b.semesters.join(', ') : '',
                        // contactName is already available from Apex
                        contactName: b.contactName || '',
                        // Map isAnonymous to expected field name
                        HAM_Anonymous__c: b.isAnonymous === true,
                        anonymousIcon: b.isAnonymous === true ? 'utility:check' : 'utility:close',
                        anonymousLabel: '' // Empty string to hide text, only show icon
                    }));

                    // Data is already sorted in Apex query, but we can apply client-side sorting if needed
                    const sortedBeneficiaries = processedBeneficiaries; // Already sorted from Apex

                    const totalRecords = sortedBeneficiaries.length;
                    const totalPages = Math.max(1, Math.ceil(totalRecords / this.pageSize));

                    return {
                        ...fund,
                        beneficiaries: sortedBeneficiaries,
                        allBeneficiaries: sortedBeneficiaries,
                        hasBeneficiaries: totalRecords > 0,
                        // Pagination state
                        pageNumber: 1,
                        totalRecords: totalRecords,
                        totalPages: totalPages,
                        showPagination: totalRecords > this.pageSize,
                        isFirstPage: true,
                        isLastPage: totalPages <= 1,
                        paginatedBeneficiaries: sortedBeneficiaries.slice(0, this.pageSize),
                        // Sorting state
                        sortedBy: 'HAM_Sort_Fiscal_Year__c',
                        sortedDirection: 'desc',
                        // Expand/collapse state
                        isExpanded: true,
                        expandIcon: 'utility:chevrondown'
                    };
                });

                console.log('Processed funds:', this.funds);
            })
            .catch(error => {
                this.error = error;
                this.funds = [];
                console.error('Error loading funds and beneficiaries:', error);
                console.error('Error details:', JSON.stringify(error));
            })
            .finally(() => {
                this.loading = false;
                console.log('Loading finished');
            });
    }

    get hasFunds() {
        return this.funds && this.funds.length > 0;
    }

    get noFunds() {
        return !this.loading && !this.hasFunds;
    }

    // =========================================
    // Pagination handlers
    // =========================================
    handleNextPage(event) {
        const fundId = event.target.dataset.fundId;
        this.updatePagination(fundId, 'next');
    }

    handlePrevPage(event) {
        const fundId = event.target.dataset.fundId;
        this.updatePagination(fundId, 'prev');
    }

    updatePagination(fundId, direction) {
        this.funds = this.funds.map(fund => {
            if (fund.stewardshipId === fundId) {
                let newPageNumber = fund.pageNumber;

                if (direction === 'next' && !fund.isLastPage) {
                    newPageNumber += 1;
                } else if (direction === 'prev' && !fund.isFirstPage) {
                    newPageNumber -= 1;
                }

                const start = (newPageNumber - 1) * this.pageSize;
                const end = start + this.pageSize;
                const paginatedBeneficiaries = fund.allBeneficiaries.slice(start, end);

                return {
                    ...fund,
                    pageNumber: newPageNumber,
                    isFirstPage: newPageNumber <= 1,
                    isLastPage: newPageNumber >= fund.totalPages,
                    paginatedBeneficiaries: paginatedBeneficiaries
                };
            }
            return fund;
        });
    }

    // =========================================
    // Sorting handlers
    // =========================================
    handleSort(event) {
        const fundId = event.currentTarget.dataset.fundId;
        const { fieldName: sortedBy, sortDirection } = event.detail;

        this.funds = this.funds.map(fund => {
            if (fund.stewardshipId === fundId) {
                // Sort the beneficiaries
                const sortedBeneficiaries = this.sortData([...fund.allBeneficiaries], sortedBy, sortDirection);

                // Reset to page 1 after sorting
                const paginatedBeneficiaries = sortedBeneficiaries.slice(0, this.pageSize);

                return {
                    ...fund,
                    allBeneficiaries: sortedBeneficiaries,
                    paginatedBeneficiaries: paginatedBeneficiaries,
                    sortedBy: sortedBy,
                    sortedDirection: sortDirection,
                    pageNumber: 1,
                    isFirstPage: true,
                    isLastPage: fund.totalPages <= 1
                };
            }
            return fund;
        });
    }

    sortData(data, fieldName, direction) {
        const sortDirection = direction === 'desc' ? -1 : 1;

        return [...data].sort((a, b) => {
            let aVal = a[fieldName] ?? '';
            let bVal = b[fieldName] ?? '';

            // Convert to strings for comparison
            aVal = String(aVal).toLowerCase();
            bVal = String(bVal).toLowerCase();

            if (aVal === bVal) return 0;
            return aVal > bVal ? sortDirection : -sortDirection;
        });
    }

    // =========================================
    // Expand/collapse handlers
    // =========================================
    handleToggleFund(event) {
        const fundId = event.currentTarget.dataset.fundId;

        this.funds = this.funds.map(fund => {
            if (fund.stewardshipId === fundId) {
                const newExpandedState = !fund.isExpanded;
                return {
                    ...fund,
                    isExpanded: newExpandedState,
                    expandIcon: newExpandedState ? 'utility:chevrondown' : 'utility:chevronright'
                };
            }
            return fund;
        });
    }
}