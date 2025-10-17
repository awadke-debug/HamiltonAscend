import { LightningElement,api } from 'lwc';

/**
 * @description A component to display alumni profiles in a grid view.
 * It iterates through a list of alumni and handles card clicks to open a profile overview.
 */
export default class Ham_alumniGridDisplayCmp extends LightningElement {
    /**
     * @description The list of alumni contact records to display in the grid.
     * The data is passed from a parent component.
     * @type {array}
     */
    @api alumniList = [];

    /**
     * @description Handles the click event on an alumni profile card.
     * It dispatches a custom event to a parent component, passing the ID of the selected contact.
     * The contact ID is retrieved from the data-id attribute on the clicked element.
     * @param {Event} event The click event object.
     */
    handleProfileSelect(event) {
        this.dispatchEvent(new CustomEvent('select',{
            detail: event.currentTarget.dataset.id
        }));
        document.body.style.overflow = 'hidden';
    }
}