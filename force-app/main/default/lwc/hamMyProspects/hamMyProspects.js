import { LightningElement, track, wire } from 'lwc';
import recentRecords from '@salesforce/apex/HamMyProspectController.searchMyProspects';

export default class HAMMyProspects extends LightningElement {
    @track prospectRecords = [];
    @track error;
    @track activeSection = '';


    columns = [
        {
            label: 'Name',
            fieldName: 'recordLink',
            type: 'url',
            typeAttributes: {
                label: { fieldName: 'HAM_Name_w_Suffix__c' },
                target: '_blank'
            },
            sortable: true
        },
        {
            label: 'Preferred Chapter',
            fieldName: 'chapterLink',
            type: 'url',
            typeAttributes: {
                label: { fieldName: 'chapterName' },
                target: '_blank'
            },
            sortable: false
        },
        {
            label: 'Current Chapters',
            fieldName: 'HAM_Current_Chapters__c',
            type: 'text',
            sortable: false
        }
    ];

    @wire(recentRecords)
    wiredApexResult({ data, error }) {
        if (data) {
            console.log('Data received------:', data);
            this.prospectRecords = data.map(row => ({
                ...row,
                recordLink: `/lightning/n/JEDI_Overview?c__recordId=${row.Id}`,
                chapterLink: row.HAM_Preferred_Chapter_Lookup__c
                    ? `/lightning/r/${row.HAM_Preferred_Chapter_Lookup__c}/view`
                    : null,
                chapterName: row.HAM_Preferred_Chapter_Lookup__r?.Name || '—'
            }));
             console.log('Data processed ------:', this.prospectRecords);
            this.error = undefined;
        } else if (error) {
            console.error('Error fetching prospects:', error);
            this.error = error;
            this.prospectRecords = [];
        }
    }

     handleSectionToggle(event) {
        const openedSections = event.detail.openSections;

        if (openedSections.includes('My Prospects')) {
            this.activeSection = 'My Prospects'; // open it
        } else {
            this.activeSection = ''; // close it
        }
    }
    
}