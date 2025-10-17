import { LightningElement, api, track } from 'lwc';
// Importing a static resource
import HAM_ICONS from '@salesforce/resourceUrl/HAM_Icons';

/**
 * @description A basic header component that displays a logo.
 * It's designed to be a simple, reusable component for a consistent header across pages.
 */
export default class Ham_HeaderCmp extends LightningElement {
    @track images = {};

    /**
     * @description Lifecycle hook that runs when the component is inserted into the DOM.
     * It's used here to initialize the `images` object with the correct path to the logo.
     */
    connectedCallback() {
        // Static resources for images
        this.images = {
            logo: HAM_ICONS + '/logo.png'
        };
    }
}