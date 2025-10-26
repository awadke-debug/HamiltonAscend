import { LightningElement, track, wire } from 'lwc';
import { getRecords } from 'lightning/uiRecordApi';
import { refreshApex } from '@salesforce/apex';
import { CurrentPageReference } from 'lightning/navigation';

import hamiltonLogo from '@salesforce/resourceUrl/HamiltonInstituteLogo';

import getBaseUrl from '@salesforce/apex/HamItineraryController.getBaseUrl';
import getEvents from '@salesforce/apex/HamItineraryController.getEvents';
import sendDigitalTrip from '@salesforce/apex/HamItineraryController.sendDigitalTrip';

import {
    saveTdForm, 
    mapStayToForm, 
    mapTranspoToForm, 
    mapMeetingToForm, 
    handleRemoveEvent, 
    buildFormElements, 
    extractContactIdsFromMapResult, 
    updateMeetingList
} from 'c/tripPlannerUtil';

export default class HamDigitalTripPlanner extends LightningElement {
    _saveTdForm = saveTdForm.bind(this);
    _handleRemoveEvent = handleRemoveEvent.bind(this);
    _buildFormElements = buildFormElements.bind(this);
    _extractContactIdsFromMapResult = extractContactIdsFromMapResult.bind(this);
    _updateMeetingList = updateMeetingList.bind(this);

    tripDetailId;
    displaySpinner = false;
    contactIds = [];
    selectedRows = [];
    currentTab;
    mapResultRows;
    emailSubject;
    emailBody;

    connected;
    generateUrlOnConnected;
    currentPageReference;

    @track recsObj;
    @track activeTab = '';
    @track traveloptions = '';
    @track previewlogo = hamiltonLogo;
    @track meetings;
    @track tripDetails = {};
    @track stayDetailFormElems = [{ idx: 0 }];
    @track stayDetails;
    @track transpoDetailFormElems = [{ idx: 0 }];
    @track transportDetails;

    @wire(getBaseUrl)
    wiredBasedUrl;
    wiredEventsResult;

    @wire(getRecords, { records: '$recsObj' })
    wiredContacts({ error, data }) {
        if (data) {
            let tmpMeetings = data.results.map(con => {
                const mapResultRow = this.selectedRows.find(itm => itm.contactId == con.result.fields.Id.value);

                const { id, contactId, ...address } = mapResultRow;

                console.log('rest', JSON.stringify(address));

                return {
                    name: con.result.fields.Name.value,
                    address: address,
                    mapRowId: id,
                    contactId: contactId,
                }
            });

            if (!data.results || data.results?.length === 0) {
                return;
            }

            if (!this.meetings) {
                this.meetings = [];
            }

            let tmpMeetingHolder = [...this.meetings];
            this.meetings = [...tmpMeetings, ...tmpMeetingHolder]; // combine meetings in DB and new meetings
            
        }
    }
    
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

    refreshPageOnStateChange() {
        const recordIdFromCurrState = this.currentPageReference.state.c__tripId;
        
        if (recordIdFromCurrState !== this.tripDetailId) {
            this.tripDetailId = recordIdFromCurrState;
        }
    }

    handleCheckRow(event) {
        const { rows } = event.detail;
        this.selectedRows = rows;

        this.contactIds = this._extractContactIdsFromMapResult();
        this.buildRecordObjParam();
    }

    handleSelectAll(event){
        const { rows } = event.detail;
        this.selectedRows = rows;

        this.contactIds = rows.map(row => row.contactId);
        this.buildRecordObjParam();
    }

    buildRecordObjParam() {
        this._updateMeetingList();

        if (!this.contactIds || this.contactIds.length == 0) {
            return;
        }

        this.recsObj = [{
            fields: ['Contact.Name', 'Contact.Id'],
            recordIds: this.contactIds
        }];
    }

    @wire(getEvents, { tripDetailId: '$tripDetailId' })
    wiredEvents(result) {
        this.wiredEventsResult = result;
        const { data, error } = result;
        if (data) {
            this.buildFormElements(data);
        } else if (error) {
            console.error('error', JSON.stringify(error));
        }
    }

    buildFormElements(data) {
        const staysTemp = data.filter(item => item.RecordType.DeveloperName == 'HAM_Accommodation');
        const transpoTemp = data.filter(item => item.RecordType.DeveloperName == 'HAM_Transportation');
        const meetingTemp = data.filter(item => item.RecordType.DeveloperName == 'HAM_Meeting');

        this._buildFormElements(staysTemp, mapStayToForm, 'stayDetailFormElems');
        this._buildFormElements(transpoTemp, mapTranspoToForm, 'transpoDetailFormElems');
        this._buildFormElements(meetingTemp, mapMeetingToForm, 'meetings');
    }

    handleTripChange(event) {
        this.tripDetailId = event.detail?.tripDetailId || '';

        refreshApex(this.wiredEventsResult);
    }

    handleAddStayDetails(event) {
        this.stayDetailFormElems.push({ idx: this.stayDetailFormElems.length });
    }

    handleRemoveStayDetails(event) {
        const stayId = event.currentTarget.getAttribute('data-stay-detail-id')
        const stayIdx = event.currentTarget.getAttribute('data-stay-detail-idx');

        this._handleRemoveEvent(stayId, this.stayDetailFormElems, stayIdx);
    }

    handleAddTranspo(event) {
        this.transpoDetailFormElems.push({ idx: this.transpoDetailFormElems.length });
    }

    handleRemoveTranspo(event) {
        const transpoId = event.currentTarget.getAttribute('data-transpo-detail-id')
        const transpoIdx = event.currentTarget.getAttribute('data-transpo-detail-idx');

        this._handleRemoveEvent(transpoId, this.transpoDetailFormElems, transpoIdx);
    }

    handleMapSearch(event) {
        const { result } = event.detail;
        this.mapResultRows = result;

        this.selectedRows = [];
        this.contactIds = [];

        this._updateMeetingList();
    }

    handleRemoveMeeting(event) {
        const meetingId = event.currentTarget.getAttribute('data-meeting-detail-id')
        const meetingIdx = event.currentTarget.getAttribute('data-meeting-detail-idx');

        this._handleRemoveEvent(meetingId, this.meetings, meetingIdx);

        const mapFinderCmp = this.template.querySelector('c-map-finder');
        mapFinderCmp.handleUncheckRow(event.currentTarget.getAttribute('data-map-row-id'));

    }

    handleSaveAndNext(event) {
        if (this.currentTab == 'SC') {
            this.activeTab = 'SM';
        } else {
            this._saveTdForm();
        }
    }

    handleSendEmail(event) {
        this._saveTdForm(true);
    }

    handleActiveTab(event) {
        this.currentTab = event.target.value;

        if (this.currentTab !== this.activeTab) {
            this.activeTab = this.currentTab;

            if (this.currentTab == 'PR') {
                this.generateSummary();
            }
        }
    }

    handleEmailSubjectChange(event) {
        this.emailSubject = event.target.value;
    }

    handleEmailBodyChange(event) {
        this.emailBody = event.target.value;
    }

    generateSummary() {
        this.getMeetings();
        this.getTripDetails();
        this.getStayDetails();
        this.getTransportDetails();
    }

    getMeetings() {
        const meetingCmps = this.template.querySelectorAll('c-meeting-item[data-display-only="false"]');

        if (!meetingCmps || meetingCmps.length == 0) {
            return;
        }

        meetingCmps.forEach(meetCmp => {
            this.meetings.forEach(meetItem => {

                if (meetCmp.meeting.id === meetItem.id) {
                    Object.assign(meetItem, meetCmp.meeting);
                }
            });
        });
    }

    getTripDetails() {
        const tripDetailsCmp = this.refs.tripDetailsForm;

        if (tripDetailsCmp) {
            this.tripDetails = { ...tripDetailsCmp.tripDetails };
        }
    }

    getStayDetails() {
        const stayDetailCmps = this.template.querySelectorAll('c-stay-details[data-display-only="false"]');
        this.stayDetails = [];
        stayDetailCmps.forEach(sd => {
            if (sd.stayDetails.stayDetailsName) { // TEST validation ONLY
                this.stayDetails.push({ ...sd.stayDetails });
            }
        });
    }

    getTransportDetails() {
        const transportDetailCmps = this.template.querySelectorAll('c-transport-details[data-display-only="false"]');
        this.transportDetails = [];
        transportDetailCmps.forEach(td => {
            this.transportDetails.push({ ...td.transportDetails });
        });
    }

    get options() {
        return [
            { label: 'Car', value: 'Car' },
            { label: 'Flight', value: 'Flight' },
            { label: 'Train', value: 'Train' },
        ];
    }
    get status() {
        return [
            { label: 'Planned', value: 'Planned' },
            { label: 'Scheduled', value: 'Scheduled' },
            { label: 'Rescheduled', value: 'Rescheduled' },
            { label: 'Cancelled', value: 'Cancelled' },
            { label: 'Attempted not Reachable', value: 'Attempted not Reachable' },
            { label: 'Attempted not available', value: 'Attempted not available' },
        ];
    }

    get url() {
        if (!this.wiredBasedUrl?.data) {
            return null;
        }
        return `${this.wiredBasedUrl.data}/apex/hamItineraryPdf?tripDetailId=${this.tripDetailId}`;
    }

    get pdfHeight() {
        return 'height: 100vh; width: 80vw;';
    }

    get hasMeetingItems() {
        return this.meetings && this.meetings.length > 0;
    }

    get hasStayDetails() {
        return this.stayDetails && this.stayDetails.length > 0;
    }

    get meetingCount() {
        return this.meetings ? this.meetings.length : 0;
    }

    get hasTransportDetails() {
        return this.transportDetails && this.transportDetails.length > 0;
    }

    get disabledSMsaveForLater() {
        return this.meetings.filter(meeting => meeting.meetingId === null || meeting.meetingId === undefined).length === 0;
    }
}