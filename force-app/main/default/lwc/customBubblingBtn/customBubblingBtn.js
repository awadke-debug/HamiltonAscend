import { api, LightningElement } from 'lwc';

export default class CustomBubblingBtn extends LightningElement {
    @api label;
    @api tripId;

    handleBtnClick(event) {
        
        this.dispatchEvent(new CustomEvent('btnclick', {
            bubbles: true,
            composed: true,
            cancelable: true,
            detail: {
                message: `${this.label} clicked`,
                tripId: this.tripId
            }
        }));
    }
}