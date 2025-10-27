import { LightningElement, track, api } from 'lwc';
import noRecordsMsg from '@salesforce/label/c.ham_NoRecordsMsg';
import loadMore from '@salesforce/label/c.ham_LoadMore';

/**
 * @description A component that displays philanthropy data in a custom, sortable data table.
 * It receives structured data from a parent component and handles sorting and pagination events.
 */
export default class Ham_philanthropyDataTableCmp extends LightningElement {
    /**
     * @description Public API property to receive data for the table.
     * The data structure includes `columnLabels`, `columnApiNames`, `columnFieldTypes`,
     * `displayRecords`, `sortField`, and `sortDirection`.
     * @type {object}
     */
    @api tableData  = {};

    /**
     * @description property to store custom labels for the cards.
     */
    label = {
        noRecordsMsg: noRecordsMsg,
        loadMore: loadMore
    }

    /**
     * @description Getter to check if there are any records to display in the table.
     * This is useful for conditional rendering of the table vs. an empty state message.
     * @returns {boolean} True if `displayRecords` is not null and has a length greater than 0.
     */
    get hasRecords() {
        return this.tableData.displayRecords && this.tableData.displayRecords.length > 0;
    }

    /**
     * @description Getter to determine the icon for the sort direction.
     * @returns {string} The character '▲' for ascending or '▼' for descending.
     */
    get sortDirectionIcon() {
        return this.tableData.sortDirection === 'asc' ? '▲' : '▼';
    }

    /**
     * @description A getter that transforms the raw column metadata into a structured format
     * suitable for iterating in the HTML template's table header.
     * @returns {Array<Object>} An array of column objects with labels, API names, and sort state.
     */
    get columns() {
        // Guard against missing essential data
        if (!this.tableData.columnLabels || !this.tableData.columnApiNames || !this.tableData.columnFieldTypes) {
            return [];
        }
        // Map the column labels to a more usable object format
        return this.tableData.columnLabels.map((label, index) => ({
            label: label,
            apiName: this.tableData.columnApiNames[index],
            fieldType: this.tableData.columnFieldTypes[index],
	        isSortedColumn: this.tableData.sortField === this.tableData.columnApiNames[index] 
        }));
    }

    /**
     * @description A getter that prepares table rows and cells from the raw record data.
     * It formats field values and creates a structure optimized for the template's loops.
     * @returns {Array<Object>} An array of row objects, where each object contains an ID and an array of cell objects.
     */
    get displayRecords() {
        if (!this.tableData.displayRecords || this.tableData.displayRecords.length === 0) {
            return [];
        }
        return this.tableData.displayRecords.map((record) => {
            let cells = this.columns.map(col => {
                let value = record[col.apiName];
                return {
                    value: this.formattedFieldValue(value, col.fieldType),
                    key: record.Id
                };
            });
            return {
                Id: record.Id,
                cells: cells
            };
        });
    }

    /**
     * @description A helper method to format field values based on their type.
     * It currently handles currency and date formatting.
     * @param {*} fieldvalue The value to format.
     * @param {string} fieldType The type of the field (e.g., 'currency', 'date').
     * @returns {*} The formatted value.
     */
    formattedFieldValue(fieldvalue, fieldType) {
        if (fieldvalue === null || fieldvalue === undefined || fieldvalue === '') {
            return '';
        }
        switch (fieldType.toLowerCase()) {
            case 'currency':
                // Use the en-US locale for consistent currency formatting
                return new Intl.NumberFormat('en-US', {
                    style: 'currency',
                    currency: 'USD',
                    maximumFractionDigits: 2
                }).format(fieldvalue);
            case 'date':
            // 1. Split the "yyyy-mm-dd" string into parts
            const parts = fieldvalue.split('-'); 
            
            // 2. Check if the split was successful and has 3 parts
            if (parts.length === 3) {
                // parts[0] is yyyy, parts[1] is mm, parts[2] is dd
                // Reassemble in "mm/dd/yyyy" format
                return `${parts[1]}/${parts[2]}/${parts[0]}`;
            }
            case 'text':
                return fieldvalue;
            default:
                return fieldvalue;
        }
    }

    /**
     * @description Handles a click on a column header to initiate sorting.
     * It dispatches a 'sortaction' event to the parent component with the field and new sort direction.
     * @param {Event} event The click event object.
     */
    handleSort(event) {
        let field = event.currentTarget.dataset.field;
        let currentDirection = this.tableData.sortField === field ? this.tableData.sortDirection : 'asc';
        let newDirection = currentDirection === 'asc' ? 'desc' : 'asc';

        this.dispatchEvent(new CustomEvent('sortaction', {
            detail: {
                payload: { field: field, direction: newDirection }
            }
        }));
    }

    /**
     * @description Handles the "Load More" button click.
     * It dispatches a 'loadmoreaction' event to the parent component to fetch more data.
     */
    handleLoadMore() {
        this.dispatchEvent(new CustomEvent('loadmoreaction'));
    }

}