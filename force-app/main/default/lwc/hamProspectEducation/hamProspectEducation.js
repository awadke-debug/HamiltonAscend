import { LightningElement, api, track, wire } from 'lwc';
import searchProspectEducation from '@salesforce/apex/HAMProspectOverviewApexController.searchProspectEducation';
import { CurrentPageReference } from 'lightning/navigation';

export default class HamProspectEducation extends LightningElement {
     @api contactEducationWrapper; 
     @api recordId;
     @track loading = false; // Spinner control
     @track educationDetails; 
     @track awards; 
     @track activeStudentSectionBio = 'Student Summary';

     @track awardColumns = [
        {
            label: 'Name',
            fieldName: 'nameLink',
            type: 'url',
            typeAttributes: {
                label: { fieldName: 'Name' },
                target: '_blank'
            }
        },
        {
            label: 'Designation Name',
            fieldName: 'designationLink',
            type: 'url',
            typeAttributes: {
                label: { fieldName: 'designationName' }, 
                target: '_blank'
            }
        },
        {
            label: 'Type',
            fieldName: 'ucinn_ascendv2__Type__c',
            type: 'text'
        },
        {
            label: 'Fiscal Year',
            fieldName: 'ucinn_ascendv2__Fiscal_Year__c',
            type: 'text'
        }
    ];

    @wire(CurrentPageReference)
        getStateParameters(currentPageReference) {
            
            if (currentPageReference?.state?.c__recordId) {
                this.recordId = currentPageReference.state.c__recordId;
                
    
                this.loading = true; // Start spinner
                searchProspectEducation({ contactId: this.recordId })
                    .then(result => {
                       
                        this.contactEducationWrapper = result;
                        this.educationDetails = result.hamiltonDegree;
                        this.awards = result.awards;
                        
                        if(this.awards){
                           this.awards = this.awards.map(row => {
                                console.log('Row -----'+JSON.stringify(row));
                                if(row.ucinn_ascendv2__Designation__c){
                                    let designationRecord = row.ucinn_ascendv2__Designation__r;
                                    if(designationRecord.ucinn_ascendv2__Designation_Name__c){
                                        return {
                                            ...row,
                                            nameLink: '/' + row.Id,
                                            designationLink: '/' + row.ucinn_ascendv2__Designation__c,
                                            designationName: row.ucinn_ascendv2__Designation__r?.ucinn_ascendv2__Designation_Name__c                              
                                        };
                                    }else{
                                        return {
                                            ...row,
                                            nameLink: '/' + row.Id,
                                            designationLink: '/' + row.ucinn_ascendv2__Designation__c,
                                            designationName: row.ucinn_ascendv2__Designation__r?.ucinn_ascendv2__Fund_Name__c                             
                                        };
                                    }
                                }
                            });
                        }
                    })
                    .catch(error => {
                        console.error('Error fetching Prospect:', error);
                    })
                    .finally(() => {
                        this.loading = false; // Stop spinner
                    });
            }
        }
        
        handleStudentSectionToggle(event) {
        
        const openedSections = event.detail.openSections;
        
        if (Array.isArray(openedSections)) {
            this.activeStudentSectionBio = openedSections.includes('Student Summary') ? 'Student Summary' : '';
        } else {
            this.activeStudentSectionBio = openedSections === 'Student Summary' ? 'Student Summary' : '';
        }
 
    }
}