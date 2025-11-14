import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import deleteEvent from '@salesforce/apex/HamItineraryController.deleteEvent';
import { refreshApex } from '@salesforce/apex';
import sendDigitalTrip from '@salesforce/apex/HamItineraryController.sendDigitalTrip';
import SearchAddressModal from 'c/searchAddressModal';

function validateForms(forms) {
    for (let i = 0; i < forms.length; i++) {
        const frm = forms[i];
        if (!frm.validateForm()) {
            return false;
        }
    }
    return true;
}

function getFormPromises(forms, updateFormsPromises, tripDetailId) {
    for (let i = 0; i < forms.length; i++) {
        updateFormsPromises.push(forms[i].updateForm(tripDetailId));
    }
}

export function extractContactIdsFromMapResult() {
    // only add contacts ids that are not in the meeting yet
    let contactIds = [];
    if (this.selectedRows && this.selectedRows.length > 0) {
        if (this.meetings) {
            contactIds = this.selectedRows.map(item => item.contactId).filter(id => this.meetings.findIndex(m => m.contactId === id) === -1); 
        } else {
            contactIds = this.selectedRows.map(item => item.contactId); 
        }
    } else {
        contactIds = [];
    }

    return contactIds;
}

export function updateMeetingList() {
    // retain meetings that are selected and already exist in DB
    if (!this.meetings) {
        return;
    }
    this.meetings = this.meetings.filter(m => {
        let idx = -1;
        if (this.selectedRows && this.selectedRows.length > 0) {
            idx = this.selectedRows.findIndex(c => c.contactId === m.contactId);
        }
            
        return idx !== -1 || m.id != null
    }); 
}

export function handleRemoveEvent(eventId, formElems, formIdx) {
    
    if (eventId) {
        this.displaySpinner = true;

        deleteEvent({ eventId: eventId })
            .then(async ()=> {
                await refreshApex(this.wiredEventsResult);
            
                this.displaySpinner = false;

                this.dispatchEvent(new ShowToastEvent({
                    title: 'Event deleted',
                    message: 'Event deleted',
                    variant: 'success'
                }));
            });

    } else {
        formElems.splice(formIdx, 1);
        formElems.forEach((item, idx) => {
            item.idx = idx;
        });
    }
}

export function saveTdForm(sendEmail = false) {
    this.displaySpinner = true;
    const tripDetailsCmp = this.refs.tripDetailsForm;
    const stayDetailFormsCmp = this.template.querySelectorAll('c-stay-details[data-display-only="false"]');
    const transportDetailFormsCmp = this.template.querySelectorAll('c-transport-details[data-display-only="false"]');
    const meetingFormComps = this.template.querySelectorAll('c-meeting-item[data-display-only="false"]');

    let updateFormsPromises = [];
    let isValid = true;

    let form = '';
    if (!validateForms(stayDetailFormsCmp)) {
        isValid = false;
        form = 'stay details';
    }

    if (!validateForms(transportDetailFormsCmp)) {
        isValid = false;
        form = 'transport details';
    }

    if (this.currentTab == 'SM') {
        if (!validateForms(meetingFormComps)) {
            isValid = false;
            form = 'meeting details';
        }
    }

    if (!isValid) {
        this.dispatchEvent(new ShowToastEvent({
            title: 'Error',
            message: `Please fill in all required fields on the ${form} form.`,
            variant: 'error',
        }));

        this.displaySpinner = false;

        return;
    }

    let forms = [...stayDetailFormsCmp, ...transportDetailFormsCmp];
    
    if (this.currentTab == 'SM' || this.currentTab == 'PR') {
        forms.push(...meetingFormComps);
    }

    const updateTripPromise = tripDetailsCmp.saveTripDetail();

    let allPromises = [ updateTripPromise ];
    const isNewTrip = !tripDetailsCmp.tripDetailId;

    if (!isNewTrip) {
        getFormPromises(forms, updateFormsPromises, tripDetailsCmp.tripDetailId);

        allPromises = [
            updateTripPromise,
            ...updateFormsPromises, 
        ];
    } 

    const ifrmEle = this.template.querySelector('iframe');
    if (ifrmEle) {
        ifrmEle.src = '';
    }

    Promise.all(
        allPromises
    ).then(async (res) => {
        console.log('trip id', res[0].id);

        if (isNewTrip) {
            getFormPromises(forms, updateFormsPromises, res[0].id);
            
            await Promise.all(updateFormsPromises);
        } 

        if (sendEmail) {
            const emailResult = await sendDigitalTrip({ tripDetailId: res[0].id, subject: this.emailSubject, body: this.emailBody });
            console.log('emailResult', emailResult);

            if (emailResult != 'sent') {
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Email NOT sent',
                    message: 'Email NOT sent',
                    variant: 'error'
                }));
            }
        }

        this.displaySpinner = false;
        tripDetailsCmp.tripDetailChange(res[0].id);

        switch (this.currentTab) {
            case 'TD':
                this.activeTab = 'SC';
                break;
            case 'SM':
                this.activeTab = 'PR';
                this.generateSummary();
                break;
            case 'PR':
                ifrmEle.src =`${this.wiredBasedUrl.data}/apex/hamItineraryPdf?tripDetailId=${res[0].id}`
                break;
            default:
                break;
        }
    
        this.dispatchEvent(new ShowToastEvent({
            title: 'Trip details saved',
            message: 'Trip details saved',
            variant: 'success'
        }));

    }).catch((err) => {
        console.log('error', err.message);
    });

}

export function buildFormElements(events, mapCallBack, formElems) {
    if ((!events || events.length == 0) && formElems !== 'meetings') {
        this[formElems] = [{ idx: 0, tripDetailId: this.tripDetailId }];
    } else {
        this[formElems] = events.map(mapCallBack);
    }
}

export function mapStayToForm(stay, i) {
    return {
        idx: i,
        id: stay.Id,
        stayDetailsName: stay.HAM_Stay_Name__c,
        stayStartDate: stay.StartDateTime,
        stayEndDate: stay.EndDateTime,
        type: 'HAM_Accommodation',
        tripDetailId: stay.WhatId,
        stayAddress: stay.HAM_Address__c,
    }
}

export function mapTranspoToForm(transpo, i) {
    
    return {
        idx: i,
        id: transpo.Id,
        mode: transpo.HAM_Mode__c,
        destinationStreet: transpo.HAM_Destination_Airport__c,
        travelStartDate: transpo.StartDateTime,
        travelEndDate: transpo.EndDateTime,
        type: 'HAM_Transportation',
        tripDetailId: transpo.WhatId,
        sourceAddress: transpo.HAM_Source_Airport__c,
        destinationAddress: transpo.HAM_Destination_Airport__c,
        flightNumber: transpo.HAM_Mode__c == 'Flight' ?  transpo.HAM_Flight_Train_Number__c : '',
        trainNumber: transpo.HAM_Mode__c == 'Train' ?  transpo.HAM_Flight_Train_Number__c : '',
    }
}

export function mapMeetingToForm(meeting, i) {
    return {
        idx: i,
        id: meeting.Id,
        name: meeting.Who.Name,
        contactId: meeting.WhoId || meeting.contactId,
        title: meeting.HAM_Meeting_Title__c,
        status: meeting.HAM_Meeting_Status__c,
        startDate: meeting.StartDateTime,
        endDate: meeting.EndDateTime,
        type: 'HAM_Meeting',
        tripDetailId: meeting.WhatId,
        hamAddress: meeting.HAM_Address__c,
    }



}

export function showSearchAddresModal(formName, propName) {
    
    SearchAddressModal.open({
        size: 'small',
        searchString: this[formName][propName],
    }).then(result => {
        this[formName][propName] = result || this[formName][propName];
        console.log(result);
    });
}