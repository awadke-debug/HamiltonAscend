import { api, LightningElement, wire } from 'lwc';
import loadSavedFilterByExternalId from '@salesforce/apex/MapFinderController.loadSavedFilterByExternalId';
import Id from '@salesforce/user/Id';

export default class MapFilterItem extends LightningElement {
    @api mapInstance;
    @api field;
    @api value;
    @api operator = '=';
    @api isRange;
    
    @api multipickValue;
    currentUserId = Id;

    connectedCallback() {
        if (!this.field) {
            return;
        }

        this.loadSavedFilter().then(result => {
            if (result) {
                this.value = result.Value__c;
                this.operator = result.Operator__c;
                this.isRange = result.Is_Range__c;
                this.multipickValue = result.Value__c.split(';');
            } else {
                this.resetValues();
            }
        }).catch(error => {
            console.log('Error loading saved filters', error.message);
            this.resetValues();
        });;
    }

    @api
    loadSavedFilter() {
        return loadSavedFilterByExternalId({
            mapInstance: this.mapInstance,
            externalId: `${this.field.key}${this.currentUserId}`
        })
    }

    handleChange(event) {
        if (this.field.dataType === 'MULTIPICKLIST' && this.isMultiSelect) { // field data type and input type are separate
            this.operator = 'includes';
            let selectedItems = event.detail.value;
            this.value = selectedItems.filter(item => item != '--None--').reduce((accu, current, idx) => `${accu}${idx === 0 ? '': ';'}${current}`, '')
            this.multipickValue = event.detail.value;

        } else if (this.field.dataType === 'REFERENCE' && this.isRecordPicker) {
            this.value = event.detail.recordId;
        } else {
            if (this.isCombobox && this.isMultiRow) {
                if (event.detail.value.length > 0) {
                    let selectectedItem = event.detail.value[event.detail.value.length - 1]
                    this.multipickValue = [selectectedItem];
                    this.value = selectectedItem == '--None--' ? null : selectectedItem;
                    
                    this.isRange = this.field.options.find(opt => opt.value === this.value)?.isRange;

                } else {
                    this.multipickValue = null;
                    this.value = null;
                }

            } else {
                this.value = event.target.value;
            }
        }

        console.log('@@value::', this.value);
    }

    @api
    resetValues() {
        this.value = null;
        this.operator = '=';
        this.multipickValue = [];

        const recordPickerCmp = this.template.querySelector('lightning-record-picker');
        if (recordPickerCmp) {
            recordPickerCmp.clearSelection();
        }
    }

    handleOperationChange(event) {
        this.operator = event.target.value;
    }

    get label() {
        return this.field?.label;
    }

    get type() {
        return this.field?.type;
    }

    get options() {
        const opts =  this.field?.options?.map(item => ({
            label: item.label,
            value: item.value
        }));

        opts.unshift({
            label: '--None--',
            value: null
        });
        return opts;
    }

    get isBasicInput() {
        return this.field?.type === 'text' 
        || this.field?.type === 'date' 
        || this.field?.type === 'checkbox';
    }

    get isCombobox() {
        return this.field?.type === 'combobox';
    }

    get isMultiSelect() {
        return this.field?.type === 'multi-select' || (this.field?.type === 'combobox' && this.field?.isMultiRow);
    }

    get isNumber() {
        return this.field?.type === 'number';
    }

    get isMultiRow() {
        return this.field?.isMultiRow;
    }

    get isImproperlyConfigured() {
        return this.field?.improperlyConfigured;
    }

    get isRecordPicker() {
        return this.field?.type === 'record-picker';
    }

    get lookupObjectApiName() {
        return this.field?.lookupObjectApiName;
    }

    get operationOptions() {
        return [
            { label: 'Greater Than', value: '>' },
            { label: 'Greater Than or Equal', value: '>=' },
            { label: 'Equal', value: '=' },
            { label: 'Less Than', value: '<' },
            { label: 'Less Than or Equal', value: '<=' },

        ]
    }

}