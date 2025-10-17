import { LightningElement,track, api } from 'lwc';

/**
 * @description A component to display and manage a user's service and volunteer information.
 * It also includes functionality to show a pop-up for campus contact details.
 */
export default class Ham_myServiceCmp extends LightningElement {
    @track showService = false;
    @api myServices = [];
    @api campusContact = {};
    @api label = {};
    @api mainResource;
    @track isPopupVisible = false;
    @track screenWidth = window.innerWidth;
    @track images = {};
    
    /**
     * @description Toggles the visibility of the service details section.
     */
    toggleService() {
        this.showService = !this.showService;
    }

    /**
     * @description Lifecycle hook that runs when the component is inserted into the DOM.
     * It adds an event listener for window resizing and initializes image paths.
     */
    connectedCallback() {
        window.addEventListener('resize', this.handleResize.bind(this));
        this.images = {
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
}