import { LightningElement, api } from 'lwc';
import noRecordsMsg from '@salesforce/label/c.ham_NoRecordsMsg';
import loadMoreMobile from '@salesforce/label/c.ham_LoadMoreMobile';

/**
 * @description A component to display philanthropy data in a card-based layout.
 * It dynamically processes and formats data received from a parent component.
 */
export default class Ham_philanthropyCardCmp extends LightningElement {
    /**
     * @description Public API property to receive data for the cards.
     * The data is expected to be an object with properties like `columnLabels`,
     * `columnApiNames`, `columnFieldTypes`, and `displayRecords`.
     * @type {object}
     */
    @api tableData; 

    /**
     * @description property to store custom labels for the cards.
     */
    label = {
        noRecordsMsg: noRecordsMsg,
        loadMoreMobile: loadMoreMobile
    }

    /**
     * @description A getter that transforms the `tableData` into a structured format suitable for
     * card display in the component's template. It creates an array of card objects, each containing
     * a title and a list of fields with formatted labels and values.
     * @returns {Array<Object>} An array of objects, where each object represents a single card.
     */
    get cardRecords() {
        // Guard against missing essential data
        if (!this.tableData.columnLabels || !this.tableData.columnApiNames || !this.tableData.columnFieldTypes) {
            return [];
        }

        // Create a map for easy lookup of labels by API name
        let columnInfoMap = new Map();
        this.tableData.columnApiNames.forEach((apiName, index) => {
            columnInfoMap.set(apiName, {
                label: this.tableData.columnLabels[index],
                fieldType: this.tableData.columnFieldTypes[index]
            });
        });

        // Map the raw data records into a structured format for card display
        return this.tableData.displayRecords.map((record, index) => {
            let fields = [];
            
            let titleFieldApiName = this.tableData.columnApiNames[0];
            let cardTitle = record[titleFieldApiName] || 'Untitled Record'; // Fallback title

            // Iterate through the column API names to populate the fields for each card
            this.tableData.columnApiNames.forEach(apiName => {
                // Skip the Id field and the title field as they are handled separately
                if (apiName !== 'Id' && apiName !== titleFieldApiName) {
                    let value = record[apiName];
                    let colInfo = columnInfoMap.get(apiName);

                    if (colInfo) { // Ensure column info exists before processing
                        fields.push({
                            label: colInfo.label || apiName, // Fallback to API name if label not found
                            // Format the value using the dedicated method
                            value: this.formattedFieldValue(value, colInfo.fieldType),
                            key: record.Id // Unique key for each field
                        });
                    }
                }
            });

            return {
                Id: record.Id || `card-${index}`, // Essential for `key` in template iteration
                title: cardTitle,
                fields: fields
            };
        });
    }

    /**
     * @description A helper method to format field values based on their type.
     * It currently handles currency formatting.
     * @param {*} fieldvalue The raw value of the field.
     * @param {string} fieldType The type of the field (e.g., 'currency', 'text').
     * @returns {*} The formatted value.
     */
    formattedFieldValue(fieldvalue, fieldType) {
        if (fieldvalue === null || fieldvalue === undefined || fieldvalue === '') {
            return '';
        }
        switch (fieldType.toLowerCase()) { // Use .toLowerCase() for robust matching
            case 'currency':
                return new Intl.NumberFormat('en-US', {
                    style: 'currency',
                    currency: 'USD',
                    maximumFractionDigits: 2
                }).format(fieldvalue);
            case 'text':
                return fieldvalue;
            default:
                return fieldvalue;
        }
    }

    /**
     * @description Handles the "Load More" action. It dispatches a custom event
     * to the parent component to request more data.
     * The parent (ham_philanthropyDetailCmp) will catch this event
     * and update the tableData, which will then reactively update this component.
     */
    handleLoadMore() {        
        let loadMoreEvent = new CustomEvent('loadmoreaction');
        this.dispatchEvent(loadMoreEvent);
    }
}