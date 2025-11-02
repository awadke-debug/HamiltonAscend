import { LightningElement, api, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { FlowNavigationFinishEvent } from 'lightning/flowSupport';
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation';
import { refreshApex } from '@salesforce/apex';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';

import CONTACT_NAME_FIELD from '@salesforce/schema/Contact.Name';
import CONTACT_OBJECT from '@salesforce/schema/Contact';

import getContactsBriefing from '@salesforce/apex/DigitalBriefingPdfController.getContactsBriefing';
import saveBriefing from '@salesforce/apex/DigitalBriefingPdfController.saveBriefing';
import getBaseUrl from '@salesforce/apex/DigitalBriefingPdfController.getBaseUrl';
import generatePdf from '@salesforce/apex/DigitalBriefingPdfController.generatePdf';

export default class DigitalBriefingPdf extends NavigationMixin(LightningElement) {
    @api recordId;
    @api heightInRem = 40;
    @api briefingDetail;
    @api briefingType;
    @api briefingId;

    contactsBriefings;
    contactsBriefingOptions;
    
    isLoading = false;
    isDefaultEmail = true;
    showInfoMessage = true;
    alternateEmail;

    @wire(getRecord, { recordId: '$recordId', fields: [CONTACT_NAME_FIELD] })
    contact;

    @wire(getBaseUrl)
    wiredBasedUrl;

    connected;
    generateUrlOnConnected;

    currentPageReference;
    @wire(CurrentPageReference)
    setCurrentPageReference(currentPageReference) {
        this.currentPageReference = currentPageReference;

        if (this.connected) {
            this.refreshPageOnStateChange();
        } else {
            this.generateUrlOnConnected = true;
        }
    }

    connectedCallback() {
        this.connected = true;

        if (this.generateUrlOnConnected) {
            this.refreshPageOnStateChange();
        }
    }

    async refreshPageOnStateChange() {
        const recordIdFromCurrState = this.currentPageReference.state.c__recordId;
        if (recordIdFromCurrState !== this.recordId) {
            this.recordId = recordIdFromCurrState;

            this.isDefaultEmail = true;
            this.showInfoMessage = true;
            this.alternateEmail = null;

            this.contactsBriefings = null;
            this.contactsBriefingOptions = null;
            this.briefingDetail = '';
            this.briefingId = null;
            this.briefingType = null;

            await refreshApex(this.contact);
            await refreshApex(this.wiredContactsBriefingResult)
                // .then(() => {
                //         console.log('setCurrentPageReference', JSON.stringify(this.currentPageReference.state), this.recordId);
                // });
        }
    }

    wiredContactsBriefingResult;

    @wire(getContactsBriefing, { contactId: '$recordId' })
    wiredContactsBriefing(result) {
        this.wiredContactsBriefingResult = result;
        const { error, data} = result;
        if(data) {
            this.contactsBriefings = data;

            if (data.length == 0) {
                 const evt = new ShowToastEvent({
                    title: 'No Briefing',
                    message: 'Constituent has no briefing',
                    variant: 'warning'
                });
                this.dispatchEvent(evt);
                return;
            }

            this.contactsBriefingOptions = data.map(d => ({
                label: d.HAM_Briefing_Type__c,
                value: d.Id
            }));
            
            this.briefingDetail = data[0].HAM_Briefing_Details__c;
            this.briefingId = data[0].Id;
            this.briefingType = data[0].HAM_Briefing_Type__c;

        } else if(error) {

        }
    }

    async handleSaveBriefing() {
        try {
            
            this.isLoading = true;
    
            const ifrmEle = this.template.querySelector('iframe');
            if (ifrmEle) {
                ifrmEle.src = '';
            }
            
            await saveBriefing({ briefingId: this.briefingId, detail: this.briefingDetail });

            if (ifrmEle) {
                ifrmEle.src = `${this.wiredBasedUrl.data}/apex/digitalBriefingPdf?contactId=${this.recordId}`
            }
        } catch (error) {
            console.log('error', JSON.stringify(error));
            
        }

        this.isLoading = false;
    }

    handleGeneratePdf() {
        this.isLoading = true;

        generatePdf({ contactId: this.recordId })
            .then(result => {
                if (result === 'success') {
                    const evt = new ShowToastEvent({
                        title: 'PDF generated',
                        message: 'PDF generated',
                        variant: 'success'
                    });
                    this.dispatchEvent(evt);
                } else {
                    const evt = new ShowToastEvent({
                        title: 'Error',
                        message: 'Failed to generate PDF',
                        variant: 'error'
                    });
                    this.dispatchEvent(evt);
                }

            }).catch(error => {
                console.error('error', error);
                const evt = new ShowToastEvent({
                    title: 'Error',
                    message: error.body.message,
                    variant: 'error'
                });
                this.dispatchEvent(evt);
            }).finally(() => {
                this.isLoading = false;
            });
    }

    handleTypeChange(event) {
        this.briefingId = event.detail.value;
        const selectedBriefing = this.contactsBriefings.find(cb => cb.Id == this.briefingId);
        this.briefingType = selectedBriefing.HAM_Briefing_Type__c;
        this.briefingDetail = selectedBriefing.HAM_Briefing_Details__c;
    }

    handleBriefingDetailChange(event) {
        this.briefingDetail = event.target.value;
    }

    handleDefaultEmailChange(event) {
        this.isDefaultEmail = event.target.checked;
        if (this.isDefaultEmail) {
            this.alternateEmail = null;
        }
    }

    handleAlternateEmailChange(event) {
        this.alternateEmail = event.target.value;
    }

    handleCloseInforMessage() {
        this.showInfoMessage = false;
    }

    navigateToContactRecord(event) {
        this[NavigationMixin.Navigate]({
            type: "standard__recordPage",
            attributes: {
                recordId: this.recordId,
                objectApiName: "Contact",
                actionName: "view",
            },
        });
    }

    get contactName() {
        return `<< ${getFieldValue(this.contact.data, CONTACT_NAME_FIELD)}`;
    }

    get url(){
        if (!this.wiredBasedUrl?.data || !this.wiredContactsBriefingResult || this.wiredContactsBriefingResult.error) {
            return null;
        }
        return `${this.wiredBasedUrl.data}/apex/digitalBriefingPdf?contactId=${this.recordId}`
    }

    get pdfHeight() {
        // return 'height: ' + this.heightInRem + 'rem; width: 100%';
        return 'height: 100vh; width: 95vw;';
    }

    get disableGeneratePdf() {
        return !this.briefingId;
    }

    get disableRichTextEditor() {
        return !this.briefingId;
    }

    get displayEmailInput() {
        return !this.isDefaultEmail;
    }

}