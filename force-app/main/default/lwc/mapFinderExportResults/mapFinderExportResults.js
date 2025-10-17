import { api, LightningElement, wire } from 'lwc';
import getAllProperties from '@salesforce/apex/MapFinderController.getAllProperties';

const OBJ_DISPLAY_NAME = new Map();
OBJ_DISPLAY_NAME.set('ucinn_ascendv2__Contact__r', 'Constituent >');
OBJ_DISPLAY_NAME.set('ucinn_ascendv2__Address__r', 'Address >');

const DEFAULT_FORMAT = 'data:text/csv;charset=utf-8'

export default class MapFinderExportResults extends LightningElement {
    @api tableCmp;
    @api mapInstance;
    
    selectedCols;
    _selected;

    options;
    format = DEFAULT_FORMAT;

    @api
    get selected() {
        return this._selected;
    }

    set selected(value) {
        if (!value || value.length === 0) {
            return;
        }
        this._selected = value;
        this.selectedCols = value.map(col => `${col.lookupApiName ? col.lookupApiName + '.' + col.fieldName : col.fieldName}`);
    }

    @wire(getAllProperties, { mapInstance: '$mapInstance' }) 
    wiredProperties({ error, data }) {
        if (data) {
            this.options = data.map(item => ({
                label: `${OBJ_DISPLAY_NAME.get(item.lookupApiName) ? OBJ_DISPLAY_NAME.get(item.lookupApiName) + ' ' : ''}${item.label}`,
                value: `${item.fullFieldName}`
            }));
        }
    }

    handleChange(event) {
        this.selectedCols = event.detail.value;
    }

    handleExport(event) {
        const allValid = [
            ...this.template.querySelectorAll('lightning-dual-listbox'),
        ].reduce((validSoFar, inputCmp) => {
            inputCmp.reportValidity();
            return validSoFar && inputCmp.checkValidity();
        }, true);

        if (allValid) {
            this.dispatchEvent(new CustomEvent('exportresults', {
                detail: { columns: this.selectedCols, format: this.format, extension: this.format.includes('csv') ? 'csv' : 'xls' }
            }));
        } 

    }

    handleClose(event) {
        this.dispatchEvent(new CustomEvent('close'));
    }

    handleFormatChange(event) {
        this.format = event.target.value;
    }

    get fileFormatOptions() {
        return [
            { label: 'CSV', value: 'data:text/csv;charset=utf-8' },
            { label: 'Excel', value: 'data:application/vnd.ms-excel' },
        ];
    }

    get displaySpinner() {
        return !this.options;
    }

    get constituentSelected() {
        const selectedCount = this.tableCmp.isAllSelected ? this.tableCmp.totalSize - this.tableCmp.idsToExclude.length : this.tableCmp.idsToExport.length;
        return `${selectedCount} constituent(s) selected.`;
    }

}