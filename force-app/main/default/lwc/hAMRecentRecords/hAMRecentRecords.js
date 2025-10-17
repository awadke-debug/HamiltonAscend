import { LightningElement, track, wire } from 'lwc';
import recentRecords from '@salesforce/apex/HAMJediSearchController.searchRecentRecords';
import { refreshApex } from '@salesforce/apex';

export default class HAMRecentRecords extends LightningElement {
    @track records = [];
    @track error;
    @track activeSection = '';

    wiredResult; // store the wired response for refresh

    columns = [
        {
            label: 'Name',
            fieldName: 'recordLink',
            type: 'url',
            sortable: true,
            typeAttributes: {
                label: { fieldName: 'HAM_Name_w_Suffix__c' },
                target: '_blank'
            }
        },
        { label: 'Donor Id', fieldName: 'ucinn_ascendv2__Donor_ID__c', type: 'text', sortable: true }
    ];

    autoRefreshTimer;

    @wire(recentRecords)
    wiredApexResult(result) {
        this.wiredResult = result; // store for refresh
        const { data, error } = result;
        if (data) {
            // map and enhance data with record link
            this.records = data.map(row => ({
                ...row,
                recordLink: `/lightning/n/JEDI_Overview?c__recordId=${row.Id}`
            }));
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.records = [];
        }
    }

    connectedCallback() {
        // Auto-refresh every 20 minutes (1200000 ms)
        this.autoRefreshTimer = setInterval(() => {
            refreshApex(this.wiredResult);
        }, 1200000);
    }

    disconnectedCallback() {
        // Stop timer when component is destroyed
        clearInterval(this.autoRefreshTimer);
    }

    handleSectionToggle(event) {
        const openedSections = event.detail.openSections;

        if (openedSections.includes('RecentProspects')) {
            this.activeSection = 'RecentProspects'; // open it
        } else {
            this.activeSection = ''; // close it
        }
    }

    
}