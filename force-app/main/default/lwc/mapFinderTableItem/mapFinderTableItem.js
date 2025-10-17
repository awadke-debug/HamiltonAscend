import { LightningElement, api } from 'lwc';

export default class MapFinderTableItem extends LightningElement {
    @api contact;
    @api fieldApiName;
    @api idx;

    get value() {
        return this.contact[this.fieldApiName];
    }
}