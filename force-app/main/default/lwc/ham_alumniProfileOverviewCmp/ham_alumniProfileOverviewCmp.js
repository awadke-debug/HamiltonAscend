import { LightningElement,api,track, wire } from 'lwc';
// Importing Apex method to get alumni overview data
import getAlumniOverview from '@salesforce/apex/HAM_AlumniProfileOverviewController.getAlumniOverview';

// Importing custom labels for static text in the component
import linkedinProfile from '@salesforce/label/c.ham_LinkedinProfile'; 
import makeAConnection from '@salesforce/label/c.ham_MakeAConnection';

/**
 * @description A component that displays a detailed profile overview of a single alumni contact.
 * It fetches dynamic data from Apex and structures it for display in the UI.
 */
export default class Ham_alumniProfileOverviewCmp extends LightningElement {
    @api mainResource;
    @track images = {};
    @api contactId;
    @track overviewData = {};
    @track contactDetail = {};

    /**
     * @description Custom labels used in the component.
     */
    label = {
        linkedinprofile: linkedinProfile,
        makeaconnection: makeAConnection
    };

    /**
     * @description Wire service to call the Apex method imperatively and get profile data.
     * The method is re-evaluated whenever the `contactId` property changes.
     *
     * @param {Object} error - An error object if the call fails.
     * @param {Array} data - The list of AlumniProfileOverviewCard wrapper objects.
     */
    @wire(getAlumniOverview, { contactId: '$contactId' })
    wiredAlumniOverview({ error, data }) {
        if (data) {
            this.overviewData = data[0];

            // Split the full name and year from the contactName field
            const {name, year} = this.splitNameAndYear(data[0].contactName);

            // Populate the contactDetail object for easy access in the template
            this.contactDetail = {
                name: name,
                year: year,
                email: data[0].contactEmail,
                linkedIn: data[0].contactlinkedIn,
                profilePictureUrl: data[0].profilePictureUrl
            };
        } else if (error) {
            console.error('Error fetching profile data: ', error);
        }
    }

    /**
     * @description Lifecycle hook that runs when the component is inserted into the DOM.
     * It initializes the image paths.
     */
    connectedCallback() {
        this.images = {
            linkedInImage: this.mainResource + '/linkedin.png',
            mailImage: this.mainResource + '/email.png',
            makeConnectionImage: this.mainResource + '/person.png'
        };
    }

    /**
     * @description Handles the click event for the modal's close button.
     * It dispatches a custom event to a parent component to request the modal to close.
     */
    closeModal() {
        this.dispatchEvent(new CustomEvent('close'));
        document.body.style.overflow = '';
    }

    /**
     * @description Splits a full name string, which may include a class year, into separate name and year parts.
     * For example, "John Doe '2020" becomes { name: "John Doe", year: "'2020" }.
     * @param {string} fullName The full name string, e.g., "Aron Ain '13".
     * @returns {Object} An object containing the separated 'name' and 'year' strings.
     */
    splitNameAndYear(fullName) {
        const parts = fullName.split(" '");
        let name = parts[0];
        let year = '';

        if (parts.length > 1) {
            year = "'" + parts.slice(1).join(" '");
        }
        return {
            name: name.trim(),
            year: year.trim()
        };
    }

    /**
     * @description Computes the CSS class for the LinkedIn button based on the presence of a URL.
     * It checks if the `contactDetail.linkedIn` property has a non-empty, non-whitespace value.
     * This getter ensures the button has the correct styling.
     * @returns {string} The CSS class string to apply to the LinkedIn button element.
     */
    get linkedInClass() {
        return this.contactDetail.linkedIn ? "linkedin-button slds-button" : "linkedin-button-disabled slds-button";
    }
}