import { LightningElement, api, track } from 'lwc';

/**
 * @description A component that displays a user's personal profile information. 
 * It handles the display of various details, including contact information, degrees, and social media links.
 * It also includes a pop-up feature for a campus contact.
 */
export default class Ham_profileSection extends LightningElement {
    @api contact = {};
    @api majorMinor = {};
    @api facebookUrl;
    @api campusContact = {};
    @api myConnect = [];
    @api personalSection = [];
    @api label = {};
    @api mainResource;
    @track isPopupVisible = false;
    @track screenWidth = window.innerWidth;
    @track images = {};

    /**
     * @description Lifecycle hook that runs when the component is inserted into the DOM.
     * It sets up an event listener for window resizing and initializes image paths.
     */
    connectedCallback() {
        window.addEventListener('resize', this.handleResize.bind(this));
        this.images = {
            faceBookImage: this.mainResource + '/facebook.png',
            linkedInImage: this.mainResource + '/linkedin.png',
            mailImage: this.mainResource + '/mail.png',
            callImage: this.mainResource + '/call.png',
        };
    }

    /**
     * @description Lifecycle hook that runs when the component is removed from the DOM.
     * It removes the event listener to prevent memory leaks.
     */
    disconnectedCallback() {
        window.removeEventListener('resize', this.handleResize.bind(this));
    }

    /**
     * @description Updates the screenWidth tracked property on window resize.
     */
    handleResize() {
        this.screenWidth = window.innerWidth;
    }

    /**
     * @description Toggles the visibility of the campus contact pop-up.
     * It includes logic to prevent the pop-up from closing if the user clicks inside it.
     * @param {Event} event The click event object.
     */
    openConnectionPopUp(event) {
        const clickedInside = event.target.dataset.name;
        if (this.isPopupVisible && clickedInside === 'CampusContact') {
            this.isPopupVisible = false;
            return;
        } else {
            this.isPopupVisible = true;
        }
    }

    /**
     * @description Closes the campus contact pop-up.
     */
    closeConnectionPopUp() {
        this.isPopupVisible = false;
    }

    /**
     * @description Getter to determine if the current view is a desktop view.
     * @returns {boolean} True if the screen width is 1025px or more.
     */
    get isDesktopView() {
        return this.screenWidth >= 1025;
    }

    /**
     * @description Getter to determine if the current view is a mobile view.
     * @returns {boolean} True if the screen width is less than 1025px.
     */
    get isMobileView() {
        return this.screenWidth < 1025;
    }

    /**
     * @description Provides a safe URL for the LinkedIn button's href attribute.
     * It returns the linkedIn URL if it's a non-empty string, otherwise it returns null to prevent
     * the browser from creating a malformed link that points to the current page.
     * @returns {string | null} The valid LinkedIn URL string or null.
     */
    get linkedInLink() {
        return this.contact.linkedin ? this.contact.linkedin : null;
    }

    /**
     * @description Computes the CSS class for the LinkedIn button based on the presence of a URL.
     * It checks if the `contact.linkedin` property has a non-empty, non-whitespace value.
     * This getter ensures the button is visually enabled or disabled and has the correct styling.
     * @returns {string} The CSS class string to apply to the LinkedIn button element.
     */
    get linkedInClass() {
        return this.contact.linkedin ? "linkedin-button slds-button" : "linkedin-button-disabled slds-button";
    }
}