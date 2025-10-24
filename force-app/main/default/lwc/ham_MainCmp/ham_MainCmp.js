import { LightningElement, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';


// Importing custom labels
import myImpact from '@salesforce/label/c.ham_MyImpact';
import alumniDirectory from '@salesforce/label/c.ham_AlumniDirectory';
import makeAGift from '@salesforce/label/c.ham_MakeAGift';
import makeAGiftLink from '@salesforce/label/c.ham_MakeAGiftLink';
import logout from '@salesforce/label/c.ham_LogoutLabel';
import logoutLink from '@salesforce/label/c.ham_LogoutLink';
import editProfile from '@salesforce/label/c.ham_EditProfile';
import manageSubscription from '@salesforce/label/c.ham_ManageSubscription';
import manageSubscriptionLink from '@salesforce/label/c.ham_ManageSubscriptionLink';
import feedback from '@salesforce/label/c.HAM_Feedback';
import feedbackLink from '@salesforce/label/c.HAM_FeedbackLink';

// Importing static resources
import HAM_ICONS from '@salesforce/resourceUrl/HAM_Icons';
import HAM_MALLORY from '@salesforce/resourceUrl/HAM_Mallory';
import HAM_MILLER from '@salesforce/resourceUrl/HAM_Miller';

// Importing Apex methods
import getMyLinksMetaData from '@salesforce/apex/HAM_MainController.getMyLinksMetaData';
import fetchLoggedInUserInfo from '@salesforce/apex/HAM_MainController.fetchLoggedInUserInfo';

/**
 * @description A main component that serves as the top-level container for a community page.
 * It handles navigation, user settings, profile management, and responsive design.
 * @extends {NavigationMixin(LightningElement)}
 */
export default class Ham_MainCmp extends NavigationMixin(LightningElement) {
    @track myLinks = [];
    @track isSettingsOpen = false;
    @track isLinksOpen = false;     // for My Links dropdown
    @track isMobileMenuOpen = false;
    @track isEditProfile = false;
    @track currentUserContactId;

    /**
     * @description Custom labels used in the component.
     */
    label = {
        myimpact: myImpact,
        alumnidirectory: alumniDirectory,
        makeagift: makeAGift,
        makeagiftlink: makeAGiftLink,
        logout: logout,
        logoutlink: logoutLink,
        managesubscription: manageSubscription,
        managesubscriptionlink: manageSubscriptionLink,
        editprofile: editProfile,
        feedback: feedback,
        feedbacklink: feedbackLink
    };

    /**
     * @description Static resource object for image URLs.
     */
    mainResource = {
        hamIcons: HAM_ICONS,
        hamMallory: HAM_MALLORY,
        hamMiller: HAM_MILLER  
    };

    @track activeTab = this.label.myimpact; // Default active tab
    @track screenWidth = window.innerWidth;

    /**
     * @description Object holding image paths for the component's UI.
     */
    images = {
        makeaGiftImage: this.mainResource.hamIcons + '/gift-outline.png', 
        makeaGiftImageMobile: this.mainResource.hamIcons + '/mobile-gift-outline.png', 
        makeaGiftBoxImageMobile: this.mainResource.hamIcons + '/mobile-gift-outline-only-box.png', 
        hamburgerMobile: this.mainResource.hamIcons + '/mobile-hamburger-outline.png', 
        editProfileImage: this.mainResource.hamIcons + '/create-outline-1.png',
        editProfileImageMobile: this.mainResource.hamIcons + '/mobile-settings.png',
        logoutImage: this.mainResource.hamIcons + '/exit-outline.png',
        logoutImageMobile: this.mainResource.hamIcons + '/mobile-logout.png',
        manageSubscriptionImage: this.mainResource.hamIcons + '/mail-unread-outline.png',
        settingsImage: this.mainResource.hamIcons + '/Frame-42.png',
        manageSubscriptionImageMobile: this.mainResource.hamIcons + '/mail-unread-outline-mobile.png'
    };

    /**
     * @description Lifecycle hook that runs when the component is inserted into the DOM.
     * It sets up event listeners for window resize and outside clicks.
     */
    connectedCallback() {
        //  event listener for window resize
        window.addEventListener('resize', this.handleResize.bind(this));
        
    // Add event listener for clicks outside the component
    this._handleOutsideClick = this.handleOutsideClick.bind(this);
    document.addEventListener('click', this._handleOutsideClick);
    }

    /**
     * @description Lifecycle hook that runs when the component is removed from the DOM.
     * It removes event listeners to prevent memory leaks.
     */
    disconnectedCallback() {
        // Remove event listener when component is removed from DOM
        window.removeEventListener('resize', this.handleResize.bind(this));
        
        // remove event listener for clicks outside the component
        document.removeEventListener('click', this._handleOutsideClick);
    }

    /**
     * @description Updates the screen width property on window resize.
     */
    handleResize() {
        this.screenWidth = window.innerWidth;
    }

    /**
     * @description Wire method to fetch 'My Links' from Custom Metadata.
     * It maps the data into a more usable format for the template.
     * @param {Object} wiredMyLinks The wired result object.
     */
    @wire(getMyLinksMetaData)
    wiredMyLinks({ error, data }) {
        if (data) {
            this.myLinks = data.map(item => ({
                id: item.id,
                label: item.HAM_Display_Label__c, 
                value: item.HAM_Redirect_Link__c 
            }));
        } else if (error) {
            console.error('Error fetching My Links metadata:', error);
        }
    }

    /**
     * @description Wire method to fetch the logged-in user's Contact ID.
     * @param {Object} wiredLoggedInUserInfo The wired result object.
     */
    @wire(fetchLoggedInUserInfo)
    wiredLoggedInUserInfo({ error, data }) {
        if (data) {
            this.currentUserContactId = data;
        } else if (error) {
            console.error('<<fetchLoggedInUserInfo Error>>', data);
        }
    }

    /**
     * @description Computed property to apply an 'active' class to the 'My Impact' link.
     * @returns {string} The CSS class string.
     */
    get computedMyImpactClass() {
        return `nav-link ${this.activeTab === this.label.myimpact ? 'active' : ''}`;
    }

    /**
     * @description Computed property to apply an 'active' class to the 'Alumni Directory' link.
     * @returns {string} The CSS class string.
     */
    get computedAlumniDirectoryClass() {
        return `nav-link ${this.activeTab === this.label.alumnidirectory ? 'active' : ''}`;
    }

    /**
     * @description Handles clicks on the main navigation links, updating the active tab.
     * @param {Event} event The click event.
     */
    handleNavLinkClick(event) {
        event.preventDefault(); // Prevent default link behavior (page reload)
        const clickedTabName = event.target.dataset.name;
        if (clickedTabName) {
            this.activeTab = clickedTabName; // Set the clicked tab as active
             
        }
    }

    // Getters for conditional rendering
    get isMyImpactActive() {
        return this.activeTab === this.label.myimpact;
    }

    get isAlumniDirectoryActive() {
        return this.activeTab === this.label.alumnidirectory;
    }

    get isDesktopView() {
        // Define desktop breakpoint (e.g., 769px or more)
        return this.screenWidth >= 950;
    }

    get isMobileView() {
        return this.screenWidth < 950;
    }

     /**
     * @description Handles clicks on the settings icon, toggling the dropdown menu.
     * It also ensures the other dropdown is closed.
     * @param {Event} event The click event.
     */
    handleSettingsClick(event) {
      
        event.stopPropagation();
        this.isSettingsOpen = !this.isSettingsOpen;
        this.isLinksOpen = false; // Close links dropdown if open
    }

    /**
     * @description Handles clicks on the 'My Links' dropdown header, toggling the menu.
     * It also ensures the settings dropdown is closed.
     * @param {Event} event The click event.
     */
    handleLinksClick(event) {
        event.stopPropagation();
        this.isLinksOpen = !this.isLinksOpen;
        this.isSettingsOpen = false; // Close settings dropdown if open
    }

    /**
     * @description Prevents the click event from propagating to the document,
     * which would otherwise close the dropdown.
     * @param {Event} event The click event.
     */
    handleDropdownClick(event) {
        this.isLinksOpen = false;
        event.stopPropagation(); 
    }

    /**
     * @description Handles the blur event on the settings dropdown to close it.
     */
    handleSettingsBlur() { 
        this.isSettingsOpen = false;
    }

    /**
     * @description Global event handler to close dropdowns when a user clicks outside the component.
     * @param {Event} event The document click event.
     */
    handleOutsideClick(event) {
        const clickedInside = this.template.contains(event.target);

        if (!clickedInside) {
            this.isSettingsOpen = false;
            this.isLinksOpen = false;
        }

    }

    /**
     * @description Helper function to build a URL with query parameters.
     * @param {string} baseUrl The base URL without query parameters.
     * @param {Object} params An object of key/value pairs for the query string.
     * @returns {string} The complete URL with encoded query parameters.
     */
    buildUrlWithParams(baseUrl, params) {
        if (!params || Object.keys(params).length === 0) {
            return baseUrl;
        }
        let query = Object.keys(params)
            .map(k => encodeURIComponent(k) + '=' + encodeURIComponent(params[k]))
            .join('&');
        return baseUrl + (query ? '?' + query : '');
    }

    /**
     * @description Navigates to an external URL using NavigationMixin.
     * @param {string} url The URL to navigate to.
     * @param {string} target The target for the navigation ('_blank' for new tab, '_self' for current).
     */
    navigateToExternalLink(url, target) {
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: url
            }
        },
        target === '_self' ? true : false 
        );
    }

    /**
     * @description Handles the Manage Subscription click event, adding parameters to the URL.
     */
    handleManageSubscriptionClick() {
        if (!this.label.managesubscriptionlink) {
            console.error('Manage Subscription Link custom label is missing.');
            return;
        }

        // Define the parameters to pass.
        const urlParams = {
            // Parameter name on the external system: Value from LWC
            lkup_subKey: this.currentUserContactId
        };

        // Construct the full URL with parameters
        const subscriptionCenterUrl = this.buildUrlWithParams(
            this.label.managesubscriptionlink, 
            urlParams
        );

        // Use NavigationMixin to open the external link in a new tab
        this.navigateToExternalLink(subscriptionCenterUrl, '_blank');
    }

    /**
     * @description Handles clicks on items within the settings dropdown menu.
     * It redirects the user or opens the edit profile modal based on the clicked item.
     * @param {Event} event The click event on a menu item.
     */
    handleSettingsMenuClick(event) {
        let eventFrom = event.currentTarget.dataset.name;
        this.isSettingsOpen = false;
        // Conditionally do the redirection using Nav Mixin
        if(eventFrom == 'managesub') {
            this.handleManageSubscriptionClick();
        }
        else if(eventFrom == 'editprof') {
            // Render ham_editProfileCmp component
            this.isEditProfile = true;
            document.body.style.overflow = 'hidden';
        }
        else if(eventFrom == 'logout') {
            window.open(this.label.logoutlink, '_self');
        }
    }

    /**
     * @description Handles the event to close the edit profile modal.
     * It also restores body scrolling.
     */
    handleEditProfileClose() {
        this.isEditProfile = false;
        document.body.style.overflow = '';
    }

    /**
     * @description Toggles the visibility of the mobile menu.
     */
    toggleMobileMenu() {
        this.isMobileMenuOpen = !this.isMobileMenuOpen;
    }

    /**
     * @description Handles clicks on items within the mobile menu.
     * It directs the user to different sections or external links.
     * @param {Event} event The click event.
     */
    handleMobileMenuItemClick(event) {
        
        const clickedItemName = event.target.dataset.name;

        if (clickedItemName === this.label.myimpact || clickedItemName === this.label.alumnidirectory) {
            this.activeTab = clickedItemName; // Update active tab for content display
        } else if (clickedItemName === this.label.editprofile) {
            document.body.style.overflow = 'hidden';
            this.isEditProfile = true;
        } else if (clickedItemName === this.label.logout) {
            window.open(this.label.logoutlink, '_self');
        } else if (clickedItemName === this.label.managesubscription) {
            this.handleManageSubscriptionClick();
        } else {
            const myLinkItem = this.myLinks.find(link => link.value === clickedItemName);
            if (myLinkItem && myLinkItem.value) {
                console.log('Navigating to My Link:', myLinkItem.value);
            }
        }
        this.isMobileMenuOpen = false; // Close the menu after any item click
    }
}