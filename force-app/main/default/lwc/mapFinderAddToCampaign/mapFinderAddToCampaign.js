import { LightningElement, api } from 'lwc';

export default class MapFinderAddToCampaign extends LightningElement {
    @api tableCmp;

    objectApiName = 'Campaign';
    value;

    handleClose(event) {
        this.dispatchEvent(new CustomEvent('close'));
    }

    handleAddToCampaign(event) {
        const recordPickerCmp = this.template.querySelector('lightning-record-picker');
        if(!recordPickerCmp.checkValidity()) {
            recordPickerCmp.reportValidity();
            return;
        }
        this.dispatchEvent(new CustomEvent('addtocampaign', { detail: this.value }));
    }

    handleChange(event) {
        this.value = event.detail.recordId;
    }

    get constituentSelected() {
        let selectedCount = 0;
        if (this.tableCmp) {
            selectedCount = this.tableCmp.isAllSelected ? this.tableCmp.totalSize - this.tableCmp.idsToExclude.length : this.tableCmp.idsToExport.length;
        }
        return `${selectedCount} constituent(s) selected to be added to campaign.`;
    }
}