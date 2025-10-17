import { LightningElement,api, track } from 'lwc';

// Importing Apex methods for filter metadata, and user preferences
import getFilterMetadataAndValues from '@salesforce/apex/HAM_AlumniDirectoryController.getFilterMetadataAndValues';
import saveUserPreferences from '@salesforce/apex/HAM_AlumniDirectoryController.saveUserPreferences';
import getSavedUserPreferences from '@salesforce/apex/HAM_AlumniDirectoryController.getSavedUserPreferences';

import { ShowToastEvent } from 'lightning/platformShowToastEvent';

/**
 * @description A component that provides search and filter functionality for alumni profiles.
 * It dynamically fetches filter options, handles user input, and allows saving of preferences.
 */
export default class Ham_alumniSearchFilterCmp extends LightningElement {
    searchStr = '';
    @api label; // Custom label object passed from the parent component
    @api userContactId; // The ID of the current user's contact record
    @api mainResource; // Base path for static resources
    @track images = {};
    @track filterOptions = [];
    @track selectedFilters = [];
    bookmarkBtnCssDesktop = 'bookmark-btn desktop-only';
    bookmarkBtnCssMobile = 'bookmark-btn mobile-only';
    isLoading = false;

     /**
     * @description Lifecycle hook that runs when the component is inserted into the DOM.
     * Initializes image paths and kicks off the process of fetching filter metadata.
     */
    connectedCallback() {
        this.images = {
            searchImage: this.mainResource + '/search.png'
        };
        this.fetchFilterMetadata();
    }

    /**
     * @description Lifecycle hook that runs after the component has rendered.
     * It ensures the `<select>` elements in the HTML are correctly populated with
     * the saved user preferences, as LWC's reactivity might not set them immediately.
     */
    renderedCallback() {
        this.filterOptions.forEach(option => {
            const selectElement = this.template.querySelector(`select[data-placeholder="${option.placeholder}"]`);
            if (selectElement) {
                selectElement.value = option.selectedValue || '';
            }
        });
    }

    /**
     * @description Fetches filter metadata and their available values from Apex.
     * It also initializes the selected filters and then loads any previously saved preferences.
     */
    async fetchFilterMetadata() {
        this.isLoading =true;
        try {
            const filterMetadata = await getFilterMetadataAndValues();

            // Map the returned metadata to a new array and initialize selectedValue
            this.filterOptions = filterMetadata.map(filter => ({
                ...filter,
                selectedValue: null
            }));

            // Initialize the selectedFilters array for tracking user selections
            this.selectedFilters = this.filterOptions.map(f => ({
                placeholder: f.placeholder,
                value: ''
            }));

            // Load previously saved preferences to pre-populate filters
            await this.loadSavedPreferences();
        }catch(error) {
            console.error('Error fetching filter metadata:', error);
            const evt = new ShowToastEvent({
                title: 'Error',
                message: 'Error fetching filter metadata. Please try again.',
                variant: 'error'
            });
            this.dispatchEvent(evt);
        }finally {
            this.isLoading = false;
        }
    }

    /**
     * @description Retrieves and applies the user's previously saved filter preferences.
     * It updates both the internal state and the UI to reflect the saved values.
     */
    async loadSavedPreferences() {
        try { 
            const savedFiltersJson = await getSavedUserPreferences({ currentContactId: this.userContactId });
            
            if (savedFiltersJson) {
                const savedFilters = JSON.parse(savedFiltersJson);
                
                // Update selectedFilters based on saved values
                this.selectedFilters = this.selectedFilters.map(filter => {
                    const saved = savedFilters.find(f => f.placeholder === filter.placeholder);
                    return saved ? { ...filter, value: saved.value } : filter;
                });
                
                // Update the UI state to reflect saved values
                this.filterOptions = this.filterOptions.map(option => {
                    const saved = savedFilters.find(f => f.placeholder === option.placeholder);
                    return saved ? { ...option, selectedValue: saved.value } : option;
                });
                // Change bookmark button color to indicate saved preferences
                this.bookmarkBtnCssDesktop = 'bookmark-btn active desktop-only'; // Set bookmark to green
                this.bookmarkBtnCssMobile = 'bookmark-btn active mobile-only'; // Set bookmark to green

                // Automatically perform a search with the loaded preferences
                this.handleSearchClick(); // Auto-execute search
            }
        } catch (error) {
            console.error('Error loading saved user preferences:', error);
        }
    }

    /**
     * @description Handles changes in a filter dropdown, updating the selected value.
     * @param {Event} event The change event from a filter `<select>` element.
     */
    handleFilterChange(event) {
        // Reset bookmark button color as a filter has been changed
        this.bookmarkBtnCssDesktop = 'bookmark-btn desktop-only';
        this.bookmarkBtnCssMobile = 'bookmark-btn mobile-only';
        const placeholder = event.target.dataset.placeholder;
        const value = event.target.value;

        // Update the selected value for the corresponding filter in the UI state
        this.filterOptions = this.filterOptions.map(option => {
            if (option.placeholder === placeholder) {
                return { ...option, selectedValue: value };
            }
            return option;
        });

        // Update the internal state for the search
        this.selectedFilters = this.selectedFilters.map(filter => {
            if (filter.placeholder === placeholder) {
                return { ...filter, value: value };
            }
            return filter;
        });
    }

    /**
     * @description Handles changes in the search input field.
     * @param {Event} event The input event from the search box.
     */
    handleSearchChange(event) {
        this.searchStr = event.target.value || '';
    }

    /**
     * @description Dispatches a custom event with the current search string and filters.
     * This method is called when the 'Search' button is clicked or after loading preferences.
     */
    handleSearchClick() {
        const payload = {
            searchKey: this.searchStr,
            selectedFilters: this.selectedFilters.filter(f => f.value && f.value !== '')
        };
        this.dispatchEvent(new CustomEvent('search', { detail: payload }));
    }

    /**
     * @description Handles the click event on the bookmark button.
     * It saves the current filter selections as user preferences in Salesforce.
     */
    async handleBookmarkClick() {
        try {
            const filtersToSave = this.selectedFilters.filter(f => f.value && f.value !== '');
            const filtersJson = JSON.stringify(filtersToSave);
            
            await saveUserPreferences({ filtersJson: filtersJson, currentContactId: this.userContactId });
            
            // Reload preferences to ensure the UI reflects the newly saved state (e.g., green bookmark)
            await this.loadSavedPreferences();

            const evt = new ShowToastEvent({
                title: 'Success',
                message: 'Filter preferences saved successfully!',
                variant: 'success'
            });
            this.dispatchEvent(evt);
        } catch (error) {
            console.error('Error saving user preferences:', error);
            const evt = new ShowToastEvent({
                title: 'Error',
                message: 'Unable to save preferences. Please try again.',
                variant: 'error'
            });
            this.dispatchEvent(evt);
        } finally {
            this.isLoading = false;
        }
    }

    /**
     * @description Resets filters with just place holders.
     * Fetches filter metadata and their available values from Apex.
     * The bookmark button class is also changed to default state accordingly.
     */
    async handleResetFilters(){
        this.isLoading =true;
        try {
            const metaDataFilters = await getFilterMetadataAndValues();

            // Map the returned metadata to a new array and initialize selectedValue
            this.filterOptions = metaDataFilters.map(filter => ({
                ...filter,
                selectedValue: null
            }));

            // Initialize the selectedFilters array for tracking user selections
            this.selectedFilters = this.filterOptions.map(f => ({
                placeholder: f.placeholder,
                value: ''
            }));
            this.searchStr = '';
            this.bookmarkBtnCssDesktop = 'bookmark-btn desktop-only';
            this.bookmarkBtnCssMobile = 'bookmark-btn mobile-only';
        }catch(error) {
            console.error('Error fetching filter metadata:', error);
            const evt = new ShowToastEvent({
                title: 'Error',
                message: 'Error fetching filter metadata. Please try again.',
                variant: 'error'
            });
            this.dispatchEvent(evt);
        }finally {
            this.isLoading = false;
        }
    }
}