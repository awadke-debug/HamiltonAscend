import { LightningElement,wire,track,api } from 'lwc';
// Importing Apex methods
import getAlumniRecords from '@salesforce/apex/HAM_AlumniDirectoryController.getAlumniRecords';
import getAlumniRecordCount from '@salesforce/apex/HAM_AlumniDirectoryController.getAlumniRecordCount';
// Importing custom labels 
import BuildAlumniCommunity from '@salesforce/label/c.ham_BuildAlumniCommunity';
import AlumniSearchPlaceHolder from '@salesforce/label/c.ham_AlumniSearchPlaceHolder'; 
import gridView from '@salesforce/label/c.ham_GridView';
import listView from '@salesforce/label/c.ham_ListView';
import result from '@salesforce/label/c.ham_Results';
import search from '@salesforce/label/c.ham_Search';
import save from '@salesforce/label/c.ham_Save';
import resetFilters from '@salesforce/label/c.ham_Reset_Filters';

/**
 * @description This component displays a searchable and filterable list of alumni profiles.
 * It handles fetching data, pagination, view toggling (grid vs. list), and opening a detailed profile overview.
 */
export default class Ham_alumniDisplayCmp extends LightningElement {
    @api mainResource;
    @api userContactId;
    @track selectedContactId;
    alumniRecords = [];
    visibleRecords = [];
    @track totalRecords = 0;
    @track pageSize = 9;
    @track currentPage = 1;
    @track totalPages = 0;
    startCount = 0;
    endCount = 0;
    @track isGridView = true;
    @track searchStr = null;
    @track selectedFilters = [];
    @track firstPageClass = '';
    @track lastPageClass = '';  
    showPageNation = false; // Flag to control pagination visibility
    @track isProfileOverViewOpen = false; // Flag to control profile overview visibility
    @track images = {};


    /**
     * @description Lifecycle hook to initialize component properties upon insertion into the DOM.
     * Sets the image paths based on the mainResource public property.
     */
    connectedCallback() {
        this.images = {
            gridSelectedImage: this.mainResource + '/grid.png',
            listImage: this.mainResource + '/list.png',
            gridImage: this.mainResource + '/grid-dark.png',
            listSelectedImage: this.mainResource + '/list-light.png'
        };
    }

    /**
     * @description Custom labels used in the component for easy maintenance.
     */
    label = {
        buildalumnicommunity: BuildAlumniCommunity,
        alumnisearchplaceholder: AlumniSearchPlaceHolder,
        gridview: gridView,
        listview: listView,
        result: result,
        search: search,
        save: save,
        resetFilters: resetFilters
    };

    isLoading = false;

    /**
     * @description Wire service to imperatively get the total count of alumni records.
     * The method is re-evaluated when searchKey or selectedFilters change.
     */
    @wire(getAlumniRecordCount, {
        searchKey: '$searchStr',
        selectedFilters: '$selectedFilters'
    })
    wiredAlumniRecordCount({error, data}){
        if (error) {
            console.error('Error fetching alumni records:', error);
            this.showPageNation = false; // Hide pagination on error
        }
        else {
            this.totalRecords = data;
            this.showPageNation = this.totalRecords > 0; // Show pagination only if there are results
            this.totalPages = Math.ceil(this.totalRecords / this.pageSize);
            this.fetchAlumniRecords();
        }
         
    }

    /**
     * @description Imperatively fetches a paginated list of alumni records from the server.
     * This method is called whenever the page number, search term, or filters change.
     */
    fetchAlumniRecords() {
        this.isLoading = true; 
        this.firstPageClass = this.currentPage === 1 ? '' : 'page-btn';
        this.lastPageClass = this.currentPage === this.totalPages ? '' : 'page-btn';
        let recordsToSkip = ((this.currentPage - 1) * this.pageSize) ;
        getAlumniRecords({ pageSize: this.pageSize, recordsToSkip: recordsToSkip, searchKey: this.searchStr, selectedFilters: this.selectedFilters })
            .then(result => {
                this.alumniRecords = result;
                this.updateVisibleRecords();                
                this.isLoading = false;
            })
            .catch(error => {
                console.error('Error fetching alumni records:', error);
                this.isLoading = false;
            });
    }

    /**
     * @description Dynamically generates the list of page numbers for pagination.
     * The getter ensures the pagination buttons are always up-to-date.
     */
    get pages() {
        let pages = [];
        if (this.totalPages > 0) {
            let visiblePages = 4; 
            let startPage = Math.max(1, this.currentPage - Math.floor(visiblePages / 2));
            let endPage = Math.min(this.totalPages, startPage + visiblePages - 1);

            if (startPage > 1) {
                pages.push({ number: 1, isCurrent: false, class: 'page-btn' });
                pages.push({ number: '...', isCurrent: false, isEllipsis: true });                
            }

            for (let i = startPage; i <= endPage; i++) {
                let pageClass = (i === this.currentPage) ? 'page-btn active' : 'page-btn';
                pages.push({
                    number:i,
                    isCurrent: i === this.currentPage,
                    class: pageClass
                });
            }

            if (endPage < this.totalPages) {
                pages.push({ number: '...', isCurrent: false, isEllipsis: true });
                pages.push({ number: this.totalPages, isCurrent: false, class: 'page-btn' });
            }
        }
        return pages;
    }

    /**
     * @description Updates the list of visible records based on the current page.
     */
    updateVisibleRecords() {
        let start = ((this.currentPage - 1) * this.pageSize);
        let end = this.currentPage * this.pageSize;
        this.visibleRecords = this.alumniRecords;
        this.startCount = start+1;
        this.endCount = this.visibleRecords.length < this.pageSize ? (end - (this.pageSize - this.visibleRecords.length)) : end ;
    }

    /**
     * @description Handles a click on a pagination number, updating the current page.
     * @param event The click event from the pagination button.
     */
    handlePageChange(event) {
        this.currentPage = Number(event.target.dataset.page);
        this.fetchAlumniRecords();
    }

    /**
     * @description Navigates to the previous page of records.
     */
    goToPreviousPage() {
        if (this.currentPage > 1) {
            this.currentPage--;
            this.fetchAlumniRecords();
        }
    }

    /**
     * @description Navigates to the next page of records.
     */
    goToNextPage() {
        if (this.currentPage < this.totalPages) {
            this.currentPage++;
            this.fetchAlumniRecords();
        }
    }

    /**
     * @description Getter to check if the current page is the first page.
     * @returns {boolean} True if on the first page, otherwise false.
     */
    get isFirstPage() {
        return this.currentPage === 1;
    }

    /**
     * @description Getter to check if the current page is the last page.
     * @returns {boolean} True if on the last page, otherwise false.
     */
    get isLastPage() {
        return this.currentPage === this.totalPages;
    }

    /**
     * @description Toggles between grid and list view for the alumni display.
     * It also adjusts the page size accordingly and resets the current page to 1.
     * @param event The click event from the view toggle button.
     */
     handleViewToggle(event) {
        console.log('<<handleViewToggle>>', event.currentTarget.classList);
        let clickedButton = event.currentTarget;
        this.isGridView = clickedButton.classList.contains('grid-view');
        
        this.pageSize = this.isGridView === false ? 15 : 9;
        this.currentPage = 1;
        this.totalPages = Math.ceil(this.totalRecords / this.pageSize);
        this.fetchAlumniRecords();
        
    }

    /**
     * @description Handles search and filter changes from child components.
     * It updates the search string and filters, and resets the pagination.
     * @param event A custom event containing the search key and selected filters.
     */
    handleSearch(event) {
        this.searchStr = event.detail.searchKey;
        this.selectedFilters = event.detail.selectedFilters;
        this.currentPage = 1;
        this.fetchAlumniRecords();
    }
    
    /**
     * @description Handles the event fired when an alumni profile card is selected.
     * It stores the contact ID and opens the profile overview modal.
     * @param event A custom event containing the selected contact's ID.
     */
    handleProfileSelect(event) {
        this.selectedContactId = event.detail;
        this.isProfileOverViewOpen = true; // Open profile overview

    }
    
    /**
     * @description Closes the alumni profile overview modal.
     */
    handleProfileClose() {
        this.isProfileOverViewOpen = false; // Close profile overview
        this.selectedContactId = null;
    }
}