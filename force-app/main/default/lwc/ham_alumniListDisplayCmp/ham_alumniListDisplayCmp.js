import { LightningElement,api } from 'lwc';

/**
 * @description A component to display alumni profiles in a list view.
 * It iterates through a list of alumni and dispatches an event when a profile is selected.
 */
export default class Ham_alumniListDisplayCmp extends LightningElement {

    /**
     * @description The list of alumni contact records to display.
     * This property is public and receives data from a parent component.
     * @type {Array<Object>}
     */
    @api alumniList = [];

    /**
     * @description Handles the click event on an alumni profile card in the list.
     * It dispatches a custom event to the parent component, passing the ID of the selected contact.
     * @param {Event} event The click event object.
     */
    handleProfileSelect(event) {
        this.dispatchEvent(new CustomEvent('select',{
            detail: event.currentTarget.dataset.id
        }));
        document.body.style.overflow = 'hidden';
    }
}