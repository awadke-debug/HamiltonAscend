import { LightningElement, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

import getEventsByUser from '@salesforce/apex/HamItineraryController.getEventsByUser';
import TripQuickCreateModal from 'c/tripQuickCreateModal';

const COLUMNS = [
    { label: 'Name', type: 'customName', typeAttributes: { tripTitle: { fieldName: 'tripTitle' }, tripId: { fieldName: 'tripId' } }},
    { label: 'Start Date', fieldName: 'tripStartDateTime' },
    { label: 'End Date', fieldName: 'tripEndtDateTime' },
    { label: 'Location', fieldName: 'address' },
    { label: 'Description', fieldName: 'description' },
    // { type: 'button-icon', initialWidth: 75, label: 'Edit',
    //     typeAttributes: { iconName: 'utility:edit', name: 'edit', variant: 'border-filled', title: 'Edit' } }
];

function getTripPlannerNavigationConfig(tripId) {
    return {
        type: 'standard__navItemPage',
        attributes: {
            apiName: 'Digital_Trip_Planner'
        },
        state: {
            c__tripId: tripId
        }
    };
}

export default class TripUpcomingMeetings extends NavigationMixin(LightningElement)  {

    columns = COLUMNS;

    @track
    data = [];

    displaySpinner = true;

    @wire(getEventsByUser)
    wiredEventsByUser({data, error}) {
        if (data) {
            this.data = data;
        } else if (error) {
            console.error('error', JSON.stringify(error));
        }

        this.displaySpinner = false;
    }

    handleRowAction(event) {
        const recId = event.detail.row.Id;
        const actionName = event.detail.action.name;
    }

    handleClickName(event) {
        console.log(event.detail.message, event.detail.tripId);

        this[NavigationMixin.Navigate](getTripPlannerNavigationConfig(event.detail.tripId));

    }

    handleClickNewTrip(event) {
        TripQuickCreateModal.open({
            size: 'small',
        }).then(result => {
            if (!result?.hasOwnProperty('tripId') || !result?.hasOwnProperty('confirmResult')) {
                return;    
            }
            
            const { tripId, confirmResult } = result;
            console.log('tripId', tripId, confirmResult);

            if (confirmResult) {
                this[NavigationMixin.Navigate](getTripPlannerNavigationConfig(tripId));
            }
        })
    }

}