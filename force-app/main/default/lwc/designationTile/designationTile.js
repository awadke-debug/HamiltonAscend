import { LightningElement, api } from 'lwc';

export default class DesignationTile extends LightningElement {
    @api
    designation;

    get name() {
        return this.designation.name;
    }
}