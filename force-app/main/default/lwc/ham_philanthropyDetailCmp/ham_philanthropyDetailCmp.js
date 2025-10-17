import { LightningElement, track, api, wire } from 'lwc';
import { subscribe, MessageContext } from 'lightning/messageService';

// Importing Lightning Message Service channel
import MY_IMPACT_CHANNEL from '@salesforce/messageChannel/myImpactChannel__c';

/**
 * @description A component that displays detailed philanthropy information in a collapsible accordion format.
 * It handles data received from a parent component and manages sorting, pagination, and various UI states.
 */
export default class Ham_philanthropyDetailCmp extends LightningElement {
    // Public API property for passing labels from a parent
    @api label;

    @track activePopup = null;
    @api campusContact;
    @track showPhilDetails = false;
    @track isOpenPledges = false;
    @track openPledgesDirection = '▶';
    @track isGivingLifetime = false;
    @track givingLifetimeDirection = '▶';
    @track isGivingPast = false;
    @track givingPastDirection = '▶';
    @track isEndowed = false;
    @track endowedDirection = '▶';
    @track isCampaign = false;
    @track campaignDirection = '▶';
    
 /*********** Table Details  ****************/
 // Tracked properties to hold data for each collapsible section's table
    @track openPledgesData = { tableRecords: [], displayRecords: [], hasMore: false, currentLimit: 0, tableName: '', columnApiNames: [], columnLabels: [],columnFieldTypes: [], sortField: '', sortDirection: 'asc' };
    @track givingLifetimeData = { tableRecords: [], displayRecords: [], hasMore: false, currentLimit: 0, tableName: '', columnApiNames: [], columnLabels: [],columnFieldTypes: [], sortField: '', sortDirection: 'asc' };
    @track givingPastData = { tableRecords: [], displayRecords: [], hasMore: false, currentLimit: 0, tableName: '', columnApiNames: [], columnLabels: [],columnFieldTypes: [], sortField: '', sortDirection: 'asc' };
    @track endowedData = { tableRecords: [], displayRecords: [], hasMore: false, currentLimit: 0, tableName: '', columnApiNames: [], columnLabels: [],columnFieldTypes: [], sortField: '', sortDirection: 'asc' };
    @track campaignData = { tableRecords: [], displayRecords: [], hasMore: false, currentLimit: 0, tableName: '', columnApiNames: [], columnLabels: [],columnFieldTypes: [], sortField: '', sortDirection: 'asc' };

    // Public API properties to receive data from the parent component
    @api philanthropySections = [];
    @api philanthropyDataTables = [];

    @track philanthropyDataTables1 = []; // Internal variable to hold the data

    // property to hold the subscription to the message channel
    subscription = null;
    

    /**
     * @description Toggles the visibility of the main philanthropy details section.
     */
    togglePhilDetails() {
        this.showPhilDetails = !this.showPhilDetails;
    }
   
   // Wire service to inject the Lightning Message Service context
    @wire(MessageContext)
    messageContext;

    /**
     * @description Lifecycle hook that runs when the component is inserted into the DOM.
     * It sets up event listeners and subscribes to the message channel.
     */
    connectedCallback() {
        this.subscribeToMessageChannel();
        this.screenWidth = window.innerWidth;
        window.addEventListener('resize', this.handleResize.bind(this));

        if (this.philanthropyDataTables1 && this.philanthropyDataTables1.length > 0) {
            this.processPhilanthropyDataTables();
        }
    }

    /**
     * @description Subscribes to the Lightning Message Service channel.
     * This allows the component to receive messages from other components, regardless of their position in the DOM.
     */
    subscribeToMessageChannel() {
        if (!this.subscription) {
            this.subscription = subscribe(
                this.messageContext,
                MY_IMPACT_CHANNEL,
                (message) => this.handleMessage(message)
            );
        }
    }

    /**
     * @description Handles an incoming message from the Lightning Message Service channel.
     * If the message is from 'Deeper Dive', it opens the philanthropy details section.
     * @param {Object} message The message object received.
     */
    handleMessage(message) {
        if (message.CalledFrom === 'Deeper Dive') {
            this.showPhilDetails = true;
        }
    }
    
    /**
     * @description Getter for the philanthropyDataTables property.
     * @returns {Array} The internal array holding philanthropy data.
     */
    get philanthropyDataTables() {
        return this.philanthropyDataTables1;
    }

    /**
     * @description Setter for the philanthropyDataTables property.
     * When new data is passed in, this setter processes it and updates the table properties.
     * @param {Array} value The new array of philanthropy data tables.
     */
    set philanthropyDataTables(value) {
        this.philanthropyDataTables1 = value;
        this.processPhilanthropyDataTables(); // Process the new data
    }

    /**
     * @description Processes and initializes the data for each philanthropy table.
     * It structures the data and applies initial sorting and pagination.
     */
    processPhilanthropyDataTables() {
        if (!this.philanthropyDataTables1 || this.philanthropyDataTables1.length === 0) {
            // Reset all table data if no data is provided, or clear previous data
            this.openPledgesData = { ...this.openPledgesData, tableRecords: [], displayRecords: [], hasMore: false };
            this.givingLifetimeData = { ...this.givingLifetimeData, tableRecords: [], displayRecords: [], hasMore: false };
            this.givingPastData = { ...this.givingPastData, tableRecords: [], displayRecords: [], hasMore: false };
            this.endowedData = { ...this.endowedData, tableRecords: [], displayRecords: [], hasMore: false };
            this.campaignData = { ...this.campaignData, tableRecords: [], displayRecords: [], hasMore: false };
            return; // Exit if no data
        }

        this.philanthropyDataTables1.forEach(tableData => {
            // Create a fresh data object for processing each table
            let dataObject = {
                tableName: tableData.tableName,
                columnApiNames: tableData.columnApiNames,
                columnLabels: tableData.columnLabels,
                columnFieldTypes: tableData.fieldTypes,
                tableRecords: tableData.records || [], // Full raw dataset
                currentLimit: tableData.displayLimit, // Start with initial limit for display                
                sortField: '',
                sortDirection: 'desc',
                displayRecords: [],
                hasMore: false,
                showLoadMore: tableData.displayLoadMore
            };

            // Apply sorting and pagination and assign to the correct tracked property
            const processedData = this.applySortAndPagination(dataObject);

            switch (tableData.tableName) {
                case 'Open Pledges':
                    this.openPledgesData = processedData;
                    break;
                case 'Giving By Purpose - Lifetime':
                    this.givingLifetimeData = processedData;
                    break;
                case 'Giving Over Past 5 Years':
                    this.givingPastData = processedData;
                    break;
                case 'Endowed Funds':
                    this.endowedData = processedData;
                    break;
                case 'Campaigns':
                    this.campaignData = processedData;
                    break;
                default:
                    console.warn(`Unknown table name: ${tableData.tableName}`);
            }
        });
    }

    /**
     * @description Handles a 'sortaction' event from a child component.
     * It updates the sort field and direction for the corresponding table.
     * @param {Event} event The custom event object containing the sort payload.
     */
    handleSort(event) {
            let sectionName = event.currentTarget.dataset.section; // e.g., 'openPledges'
            let actionPayload = event.detail.payload; // Contains {field, direction} for 'sort'
            let targetData;
            switch (sectionName) {
                case 'Open Pledges': targetData = { ...this.openPledgesData }; break;
                case 'Giving By Purpose - Lifetime': targetData = { ...this.givingLifetimeData }; break;
                case 'Giving Over Past 5 Years': targetData = { ...this.givingPastData }; break;
                case 'Endowed Funds': targetData = { ...this.endowedData }; break;
                case 'Campaigns': targetData = { ...this.campaignData }; break;
                default:
                    console.error(`handleSort: Unknown sectionName - ${sectionName}`);
                    return;
            }

            targetData.sortField = actionPayload.field;
            targetData.sortDirection = actionPayload.direction;

            // Apply sorting and pagination with the updated parameters
            let updatedData = this.applySortAndPagination(targetData);

            // Update the correct @track property to trigger reactivity in the child
            switch (sectionName) {
                case 'Open Pledges': this.openPledgesData = updatedData; break;
                case 'Giving By Purpose - Lifetime': this.givingLifetimeData = updatedData; break;
                case 'Giving Over Past 5 Years': this.givingPastData = updatedData; break;
                case 'Endowed Funds': this.endowedData = updatedData; break;
                case 'Campaigns': this.campaignData = updatedData; break;
            }
        }

        /**
         * @description Handles a 'loadmoreaction' event from a child component.
         * It increases the display limit and re-applies sorting and pagination.
         * @param {Event} event The custom event object.
        */
        handleLoadMore(event) {
            let sectionName = event.currentTarget.dataset.section; // e.g., 'openPledges'
            let targetData;
            switch (sectionName) {
                case 'Open Pledges': targetData = { ...this.openPledgesData}; break;
                case 'Giving By Purpose - Lifetime': targetData = { ...this.givingLifetimeData }; break;
                case 'Giving Over Past 5 Years': targetData = { ...this.givingPastData }; break;
                case 'Endowed Funds': targetData = { ...this.endowedData }; break;
                case 'Campaigns': targetData = { ...this.campaignData }; break;
                default:
                    console.error(`handleLoadMore: Unknown sectionName - ${sectionName}`);
                    return;
            }

            targetData.currentLimit += targetData.currentLimit; // Increase limit by 5 for next load

            const updatedData = this.applySortAndPagination(targetData);

            // Update the correct @track property to trigger reactivity in the child
            switch (sectionName) {
                case 'Open Pledges': this.openPledgesData = updatedData; break;
                case 'Giving By Purpose - Lifetime': this.givingLifetimeData = updatedData; break;
                case 'Giving Over Past 5 Years': this.givingPastData = updatedData; break;
                case 'Endowed Funds': this.endowedData = updatedData; break;
                case 'Campaigns': this.campaignData = updatedData; break;
            }

        }

    /**
     * @description Helper method to apply sorting and pagination logic to a given data object.
     * It returns a new object with the processed data.
     * @param {Object} dataObj The data object to process.
     * @returns {Object} A new data object with sorted and paginated records.
     */
    applySortAndPagination(dataObj) {
        if (!dataObj.tableRecords || dataObj.tableRecords.length === 0) {
            return { ...dataObj, displayRecords: [], hasMore: false };
        }

        let sortedRecords = [...dataObj.tableRecords]; // Always work on a copy for sorting

        if (dataObj.sortField) {
            sortedRecords.sort((a, b) => {
                let valA = a[dataObj.sortField];
                let valB = b[dataObj.sortField];

                // Handle undefined/null values gracefully for comparison
                if (valA === undefined || valA === null) valA = '';
                if (valB === undefined || valB === null) valB = '';

                // Case-insensitive string comparison
                if (typeof valA === 'string' && typeof valB === 'string') {
                    valA = valA.toLowerCase();
                    valB = valB.toLowerCase();
                }

                // Numeric comparison or default string comparison
                // Using standard comparison for non-string/non-numeric to prevent errors
                if (typeof valA === 'number' && typeof valB === 'number') {
                    return (valA - valB) * (dataObj.sortDirection === 'asc' ? 1 : -1);
                }
                return (valA > valB ? 1 : -1) * (dataObj.sortDirection === 'asc' ? 1 : -1);
            });
        }

        // Apply pagination
        let displayRecords = sortedRecords.slice(0, dataObj.currentLimit);
        let hasMore = dataObj.showLoadMore && (sortedRecords.length > dataObj.currentLimit);

        return {
            ...dataObj,
            tableRecords: sortedRecords, // Keep the full sorted array for future operations
            displayRecords: displayRecords,
            hasMore: hasMore
        };
    }

    /**
     * @description Toggles the visibility of a philanthropy accordion section.
     * @param {Event} event The click event.
     */
    toggleSection(event) {
        const section = event.currentTarget.dataset.id;
        // Toggle the visibility flags and the arrow direction
        if (section === 'openPledges') {
            this.openPledgesDirection = (this.openPledgesDirection === '▶') ? '▼' : '▶';
            this.isOpenPledges = !this.isOpenPledges;
        } else if (section === 'givingLifetime') {
            this.givingLifetimeDirection = (this.givingLifetimeDirection === '▶') ? '▼' : '▶';
            this.isGivingLifetime = !this.isGivingLifetime;
        } else if (section === 'givingPast') {
            this.givingPastDirection = (this.givingPastDirection === '▶') ? '▼' : '▶';
            this.isGivingPast = !this.isGivingPast;
        } else if (section === 'endowed') {
            this.endowedDirection = (this.endowedDirection === '▶') ? '▼' : '▶';
            this.isEndowed = !this.isEndowed;
        } else if (section === 'campaign') {
            this.campaignDirection = (this.campaignDirection === '▶') ? '▼' : '▶';
            this.isCampaign = !this.isCampaign;
        }
    }

    // Getters to apply CSS classes for accordion headers
    get openPledgesClass() {
        return this.isOpenPledges ? 'accordion-header' : 'accordion-header-collapsed';
      }

    get givingLifetimeClass() {
        return this.isGivingLifetime ? 'accordion-header' : 'accordion-header-collapsed';
      }

    get givingPastDirectionClass() {
        return this.isGivingPast ? 'accordion-header' : 'accordion-header-collapsed';
      }

    get endowedDirectionClass() {
        return this.isEndowed ? 'accordion-header' : 'accordion-header-collapsed';
      }

    get campaignDirectionClass() {
        return this.isCampaign ? 'accordion-header' : 'accordion-header-collapsed';
      }

    /**
     * @description Toggles the visibility of the pop-up modal.
     * @param {Event} event The click event.
     */
    openConnectionPopUp(event) {
        const popupName = event.currentTarget.dataset.name;
        this.activePopup = this.activePopup === popupName ? null : popupName;
    }

    /**
     * @description Closes the active pop-up modal.
     */
    closeConnectionPopUp() {
        this.activePopup = null;
    }

    handleResize() {
        this.screenWidth = window.innerWidth;
    }

    /**
     * @description Getter to determine if the view is desktop-sized.
     */
    get isDesktopView() {
        return this.screenWidth >= 1025;
    }

    /**
     * @description Getter to determine if the view is mobile-sized.
     */
    get isMobileView() {
        return this.screenWidth < 1025;
    }

    /**
     * @description Getter to check if the Tax Receipt pop-up should be visible.
     */
    get isTaxPopupVisible() {
        return this.activePopup === 'taxReceipt';
    }

    /**
     * @description Getter to check if the Donation History pop-up should be visible.
     */
    get isDonationPopupVisible() {
        return this.activePopup === 'donationHistory';
    }

}