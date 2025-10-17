import { LightningElement, track, wire } from 'lwc';

// Importing custom labels for static content
import Address from '@salesforce/label/c.ham_Address';
import AddressLink from '@salesforce/label/c.ham_AddressLink';
import Phone from '@salesforce/label/c.ham_PhoneNo';
import Copyright from '@salesforce/label/c.ham_CopyRight';

// Importing static resource
import HAM_ICONS from '@salesforce/resourceUrl/HAM_Icons';

// Importing Apex method
import getHCFooterMetaData from '@salesforce/apex/HAM_FooterNavigationController.getHCFooterMetaData';

/**
 * @description This component displays the footer section of a community page.
 * It dynamically fetches and renders official links and social media links from custom metadata.
 * It also includes responsive design logic to handle different screen sizes.
 */
export default class Ham_FooterCmp extends LightningElement {
    
    @track officialLinks = [];
    @track socialMediaLinks = [];
    @track error;

    /**
     * @description Custom labels used in the component.
     */
    label = {
        address: Address,
        addressLink: AddressLink,
        phone: Phone,
        phoneLink: `tel:${Phone}`,
        copyright: Copyright
    };

    /**
     * @description Public properties for static resources.
     */
    resource = {
        hamIcons: HAM_ICONS
    };

    @track screenWidth = window.innerWidth;


    /**
     * @description Lifecycle hook to register an event listener for window resize events.
     * This is crucial for responsive design based on screen width.
     */
    connectedCallback() {
        // Add event listener for window resize
        window.addEventListener('resize', this.handleResize.bind(this));
    }

    /**
     * @description Lifecycle hook to clean up event listeners when the component is removed from the DOM.
     * This prevents memory leaks.
     */
    disconnectedCallback() {
        // Remove event listener when component is removed from DOM
        window.removeEventListener('resize', this.handleResize.bind(this));
    }

    /**
     * @description Updates the tracked screenWidth property whenever the browser window is resized.
     * This triggers a re-evaluation of the `isDesktopView` and `isMobileView` getters.
     */
    handleResize() {
        this.screenWidth = window.innerWidth;
    }

    /**
     * @description Getter to determine if the current view is a desktop view based on a breakpoint.
     * @returns {boolean} True if the screen width is 769px or more.
     */
    get isDesktopView() {
        // Define your desktop breakpoint (e.g., 769px or more)
        return this.screenWidth >= 769;
    }

    /**
     * @description Getter to determine if the current view is a mobile view.
     * @returns {boolean} True if the screen width is less than 769px.
     */
    get isMobileView() {
        return this.screenWidth < 769;
    }

    /**
     * @description Wire service to fetch footer navigation metadata from a server-side Apex method.
     * It handles the response, segregates the data, and stores it in tracked properties.
     * @param {Object} wiredFooterItems The object containing data and error from the Apex call.
     */
    @wire(getHCFooterMetaData)
    wiredFooterItems({ error, data }) {
        if (data) {
            this.officialLinks = [];
            this.socialMediaLinks = [];
            this.address = [];
            this.phone = [];

            // Segregate and map the retrieved custom metadata records into a more usable format.
            data.forEach(mdtRecord  => {
                const item = {
                    id: mdtRecord.Id,
                    label: mdtRecord.HAM_Display_Label__c,
                    url: mdtRecord.HAM_Redirect_Link__c,
                    orderValue: mdtRecord.HAM_Order__c,
                    displayIcon: mdtRecord.HAM_Display_Icon__c,
                    type: mdtRecord.HAM_Level_2__c,
                    displayImage: this.resource.hamIcons +'/'+ mdtRecord.HAM_Display_Image__c
                };

                if (item.type === 'HC Official Links') {
                    this.officialLinks.push(item);
                } else if (item.type === 'Social Media') {
                    this.socialMediaLinks.push(item);
                }
            });

            // Re-sort to ensure correct order within each group
            this.officialLinks.sort((a, b) => a.orderValue - b.orderValue);
            this.socialMediaLinks.sort((a, b) => a.orderValue - b.orderValue);

            this.error = undefined;
        } else if (error) {
            this.error = 'Error fetching footer items: ' + JSON.stringify(error);
            this.footerItems = [];
            console.error('Error fetching footer items: ', JSON.stringify(error));
        }
    }
}