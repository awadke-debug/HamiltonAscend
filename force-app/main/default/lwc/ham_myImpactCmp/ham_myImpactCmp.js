import { LightningElement, track, api, wire} from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

// Importing static resources
import HAM_BADGES from '@salesforce/resourceUrl/HAM_Badges';

// Importing Apex methods
import getContactAndPhilanthropyData from '@salesforce/apex/HAM_MyImpactController.getContactAndPhilanthropyData'; 
import getMyServiceAffinitiesData from '@salesforce/apex/HAM_MyImpactController.getMyServiceAffinitiesData';
import getPhilanthropyDetails from '@salesforce/apex/HAM_MyImpactController.getPhilanthropyDetails';

// Importing custom labels
import MyConnections from '@salesforce/label/c.ham_MyConnection';
import MakeAGift from '@salesforce/label/c.ham_MakeAGift';  
import MakeAGiftLink from '@salesforce/label/c.ham_MakeAGiftLink';
import Facebook from '@salesforce/label/c.ham_Facebook';
import Major from '@salesforce/label/c.ham_Major';
import Minor from '@salesforce/label/c.ham_Minor';
import NumberOfYearsGiving from '@salesforce/label/c.ham_NumberOfYearsGiving';
import MyHamiltonDegree from '@salesforce/label/c.ham_MyHamiltonDegree';
import CurrentFiscalYearGiving from '@salesforce/label/c.ham_CurrentFiscalYearGiving';
import LifetimeImpact from '@salesforce/label/c.ham_LifetimeImpact';
import BecauseHamiltonFund from '@salesforce/label/c.ham_BecauseHamiltonFund';
import DeeperDiveIntoMyPhilanthrophy from '@salesforce/label/c.ham_DeeperDiveIntoMyPhilanthrophy';
import MyService from '@salesforce/label/c.ham_myService';
import MyAffinities from '@salesforce/label/c.ham_myAffinities';
import MyContactToVolunteer from '@salesforce/label/c.ham_myContactToVolunteer';
import MyCapusContact from '@salesforce/label/c.ham_myCampusContact';
import MyPhilanthrophyHighlights from '@salesforce/label/c.ham_myPhilanthropyHighlights';
import MyPhilanthropy from '@salesforce/label/c.ham_myPhilanthropy';
import TaxReceiptContent from '@salesforce/label/c.ham_taxReceiptContent';
import DonationHistoryContent from '@salesforce/label/c.ham_donationHistoryContent';
import TaxReceipt from '@salesforce/label/c.ham_taxReceipt';
import DonationHistory from '@salesforce/label/c.ham_donationHistory';
import MyLinkedinProfile from '@salesforce/label/c.ham_MyLinkedinProfile';
import BoardOfTrusteeLable from '@salesforce/label/c.ham_boardOfTrusteeLabel';
import BoardOfTrusteeLink from '@salesforce/label/c.ham_boardOfTrusteeLink';

/**
 * @description A comprehensive component to display a user's "My Impact" page.
 * It fetches and processes various data points related to the user's contact information,
 * degrees, philanthropy, service, and affinities.
 */
export default class Ham_myImpactCmp extends LightningElement {
    // Public properties to receive data from a parent component
    @api mainResource;
    @api userContactId;

    @track contact = {};
    @track majorMinor ={};
    @track facebookUrl;
    @track campusContact = {};
    @track myConnect = [];
    @track personalSection = [];
    @track hcBadges = [];
    @track philanthropySections = [];
    @track philanthropyDetailSections = [];
    @track myServices = [];
    @track myAffinities = [];
    @track philanthropyDataTables = [];
    @track loading = false;
    @track error; // For error handling within this component

    /**
     * @description Consolidated custom label object for easy access and passing to children.
     */
    label = {
        myconnections: MyConnections,
        myhamiltondegree: MyHamiltonDegree,
        numberofyearsgiving: NumberOfYearsGiving,
        currentfiscalyeargiving: CurrentFiscalYearGiving,
        lifetimeimpact: LifetimeImpact,
        becausehamiltonfund: BecauseHamiltonFund,
        deeperdiveintomyphilanthropy: DeeperDiveIntoMyPhilanthrophy,
        makeagift: MakeAGift,
        makeagiftlink: MakeAGiftLink,
        facebook: Facebook,
        major: Major,
        minor:Minor,
        myService: MyService,
        myAffinities: MyAffinities,
        myContactToVolunteer: MyContactToVolunteer,
        mycampuscontact: MyCapusContact,
        myphilanthropyhiglights: MyPhilanthrophyHighlights,
        myphilanthropy: MyPhilanthropy,
        taxreceiptcontent: TaxReceiptContent,
        donationhistorycontent: DonationHistoryContent,
        taxreceipt: TaxReceipt,
        donationhistory: DonationHistory,
        mylinkedinprofile: MyLinkedinProfile,
        boardOfTruteeLabel: BoardOfTrusteeLable,
        boardOfTruteeLink: BoardOfTrusteeLink
    };

    /**
     * @description Static resources object for image URLs.
     */
    resource = {
        hcbadges: HAM_BADGES
    };

    /**
     * @description Wire service to fetch core contact and philanthropy highlight data.
     * This method is decorated with `@wire` to automatically call the Apex method and handle
     * the returned data or any errors.
     * @param {Object} wiredContactAndPhilanthropyData The object containing the result from the Apex call.
     */
    @wire(getContactAndPhilanthropyData, { currentUserContactId: '$userContactId' })
    wiredContactAndPhilanthropyData({ error, data }) {
        this.loading = true;
        if (data) {
            // Check for a server-side error message
            if (data.error) {
                this.error = data.error;
                console.error('Apex Error:', this.error);
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: this.error,
                        variant: 'error',
                        mode: 'sticky'
                    })
                );
                 this.loading = false;
            } else {  
                try {
                    this.loading = true;
                    this.processContactData(data);
                    this.processPhilanthropyData(data, this.philanthropySections);
                    
                    this.error = undefined; 
                    this.loading = false;
                } catch (processingError) {
                    this.loading = true;
                    this.error = 'Error processing data on client-side: ' + processingError.message;
                    console.error('LWC Processing Error:', processingError);
                     this.loading = false;
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Client-side Processing Error',
                            message: this.error,
                            variant: 'error',
                            mode: 'sticky'
                        })
                    );
                }                
            }
        } else if (error) {
            console.error('Error fetching contact data:', error);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'An unexpected error occurred while fetching data.',
                    variant: 'error',
                    mode: 'sticky'
                })
            );
        }
    }

    /**
     * @description Wire service to fetch detailed philanthropy information.
     * This data is typically used for a "Deeper Dive" section.
     * @param {Object} wiredgetPhilanthropyDetails The object containing the result from the Apex call.
     */
    @wire(getPhilanthropyDetails, { currentUserContactId: '$userContactId' })
    wiredgetPhilanthropyDetails({ error, data }) {
        if (data) {
            try {               
                this.processPhilanthropyData(data, this.philanthropyDetailSections);
                this.philanthropyDataTables = data.philanthropyDataTables;
                this.error = undefined; 
            } catch (processingError) {
                this.error = 'Error processing data on client-side: ' + processingError.message;
                console.error('LWC Processing Error:', processingError);
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Client-side Processing Error',
                        message: this.error,
                        variant: 'error',
                        mode: 'sticky'
                    })
                );
            }            
        }else if (error) {
            console.error('Error fetching philanthropyDetails data:', error);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'An unexpected error occurred while fetching data.',
                    variant: 'error',
                    mode: 'sticky'
                })
            );
        }
    }

    /**
     * @description Wire service to fetch service and affinities data.
     * @param {Object} wiredgetMyServiceAffinitiesData The object containing the result from the Apex call.
     */
    @wire(getMyServiceAffinitiesData, { currentUserContactId: '$userContactId' })
    wiredgetMyServiceAffinitiesData({ error, data }) {
        if (data) {            
            try {
                
                this.myAffinities = [...data.myAffinities];
                this.myAffinities.sort((a, b) => a.order - b.order);
                this.myServices = [...data.myServices];
                this.myServices.sort((a, b) => a.order - b.order);
                this.error = undefined; 
            } catch (processingError) {
                this.error = 'Error processing data on client-side: ' + processingError.message;
                console.error('LWC Processing Error:', processingError);
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Client-side Processing Error',
                        message: this.error,
                        variant: 'error',
                        mode: 'sticky'
                    })
                );
            }            
        }else if (error) {
            console.error('Error fetching contact data:', error);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'An unexpected error occurred while fetching data.',
                    variant: 'error',
                    mode: 'sticky'
                })
            );
        }
    }


    /**
     * @description Processes contact-related data received from Apex and populates component properties.
     * @param {Object} data - The raw data object from the Apex call.
     */
    processContactData(data) {
        if (data.contact) {
            const {name, year} = this.splitNameAndYear(data.contact.name);
            this.contact = {
                id: data.contact.Id,
                name: name,
                year: year,
                userPic: data.contact.userPic,
                linkedin: data.contact.linkedIn
            };
        }

        if (data.degree && Array.isArray(data.degree)) {
            if(data.degree.length){
            const majorsArray = data.degree[0].majors ? data.degree[0].majors : '-'
            const minorsArray = data.degree[0].minors ? data.degree[0].minors : '-'

            let majors = majorsArray.filter(major => major !== null && major !== undefined && major.trim() != '');
            let minors = minorsArray.filter(minor => minor !== null && minor !== undefined && minor.trim() != '');
                
                this.majorMinor = {
                    majors: Array.isArray(majors) && majors.length ? majors.join('; ') : '-',
                    minors: Array.isArray(minors) && minors.length ? minors.join('; ') : '-'
                };
            }else{
                this.majorMinor = {
                    majors: '-',
                    minors: '-'
                };
            }
        }

        if (data.otherInfo && data.otherInfo.facebook) {
            this.facebookUrl = data.otherInfo.facebook;
            if (this.facebookUrl && !this.facebookUrl.startsWith('http://') && !this.facebookUrl.startsWith('https://')){
                this.facebookUrl = 'https://' + this.facebookUrl;
            }
        }

        if (data.campusContact) {
            this.campusContact = {
                name: data.campusContact.name,
                phone: `tel:${data.campusContact.phone}`,
                phoneLabel: data.campusContact.phone,
                email: `mailto:${data.campusContact.email}`,
                emailLabel: data.campusContact.email
            }
        }

        if (data.myConnect && Array.isArray(data.myConnect)) {
            this.myConnect = data.myConnect;
        }

        if (data.bioData && Array.isArray(data.bioData)) {
            this.personalSection = data.bioData.map(item => {
                const displayLabel = item.displayLabel;
                const displayValue = item.displayValue;
                let href = '';
                let isLink = false;
                let target = '_self';

                if (displayValue) {
                    if (displayLabel === 'Phone Number') {
                        href = `tel:${displayValue.replace(/\s+/g, '')}`;
                        isLink = true;
                    } else if (displayLabel === 'Email Address') {
                        href = `mailto:${displayValue}`;
                        isLink = true;
                    } else if (displayLabel === 'Linkedin') {
                        href = displayValue.startsWith('http') ? displayValue : `https://${displayValue}`;
                        isLink = true;
                        target = '_self'; 
                    }
                }
                return {
                    displayLabel: displayLabel,
                    displayOrder: item.displayOrder,
                    displayValue: displayValue,
                    isLink: isLink,
                    href: href,
                    target: target
                };
            }).sort((a, b) => a.displayOrder - b.displayOrder); // Sort by displayOrder
        }
    }

    /**
     * @description Processes philanthropy-related data received from Apex and organizes it into sections.
     * @param {Object} data - The raw data object from the Apex call.
     * @param {Array} targetArray - The tracked array to which the processed data will be added.
     */
    processPhilanthropyData(data, targetArray) {
        if (data.hcBadges && Array.isArray(data.hcBadges)) {
            
            this.hcBadges = data.hcBadges.map(badge => ({
                ...badge,
                imageUrl: this.resource.hcbadges + '/' + badge.imageUrl
            }));
        }

        if (data.philanthropyField && Array.isArray(data.philanthropyField)) {
            const groupedSections = {};
            data.philanthropyField.forEach(field => {
                const sectionName = field.sectionLabel;
                if (!groupedSections[sectionName]) {
                    // Converting section name to a label key format (e.g., "Current Fiscal Year Giving" -> "currentfiscalyeargiving")
                    let labelKey = sectionName.toLowerCase().replace(/[^a-zA-Z0-9]/g, '');
                    let displayTitle = this.label[labelKey] || sectionName; // Use custom label if available, else use original name

                    groupedSections[sectionName] = {
                        name: sectionName,
                        label: displayTitle,
                        fields: [],
                        order: field.order, // This 'order' is for individual fields, not sections
                        sectionOrder: field.sectionOrder, // this is for section sorting
                        isCurrentFiscalYearGiving: (sectionName === 'Current Fiscal Year Giving'),
                        isShowGift: (sectionName === 'Current Fiscal Year Giving' && data.otherInfo?.isGift)
                    };
                }
                groupedSections[sectionName].fields.push({
                    ...field, 
                    value: this.formattedFieldValue(field.value, field.type),
                    fieldLabelCss: field.label === 'Purpose' ? 'field-label full-width' : 'field-label',
                    fieldValueCss: field.label === 'Purpose' ? 'auto-height prupose-input-container' : 'field-value-box'
                });
            });

            targetArray.splice(0, targetArray.length, ...Object.values(groupedSections).map(section => {
                section.fields.sort((a, b) => a.order - b.order); // Sort fields within each section
                return section;
            }).sort((a, b) => {
                return a.sectionOrder - b.sectionOrder; // Sort sections by their order
            }));
        }
    }

    /**
     * @description Splits a full name string, which may include a class year, into separate name and year parts.
     * @param {string} fullName - The full name string, e.g., "Aron Ain '13".
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
     * @description Formats a field value based on its type (e.g., currency).
     * @param {*} fieldvalue - The value to format.
     * @param {string} fieldType - The type of the field (e.g., 'currency', 'text').
     * @returns {string} The formatted value.
     */
    formattedFieldValue(fieldvalue, fieldType) {
        if (fieldvalue === null || fieldvalue === undefined || fieldvalue === '') {
            return '';
        }
        switch (fieldType) {
            case 'currency':
                return new Intl.NumberFormat('en-US', {
                    style: 'currency',
                    currency: 'USD',
                    maximumFractionDigits: 2
                }).format(fieldvalue);
            case 'text':
            default:
                return fieldvalue;
        }
    }
    
    /**
     * @description Scrolls the view to the philanthropy detail section with a smooth animation.
     * This is useful for navigation within a single-page layout.
     */
    handleScrollToPhilanthropy() {
        const philanthropyDetailSection = this.template.querySelector('[data-id="philanthropy-detail-section-id"]');
        if (philanthropyDetailSection) {
            philanthropyDetailSection.scrollIntoView({ behavior: 'smooth', block: 'start' });
        } else {
            console.warn('Target section not found on the page.');
        }
    }
}