import { LightningElement,track, api } from 'lwc';

/**
 * @description A component to display and toggle a list of the user's affinities.
 * It receives the list of affinities and custom labels from a parent component.
 */
export default class Ham_myAffinitiesCmp extends LightningElement {
    @track showAffinities = false;
    /**
     * @description Public API property to receive an array of affinity data from a parent component.
     * The parent component is responsible for fetching and formatting the affinity details.
     * @type {Array<Object>}
     */
    @api myAffinities = [];
    @api label ={};
    
    /**
     * @description Toggles the `showAffinities` boolean property.
     * This method is typically called by a button or a click event to show or hide the affinity list.
     */
    toggleAffinities() {
        this.showAffinities = !this.showAffinities;
    }

}