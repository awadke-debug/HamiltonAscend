import { LightningElement, track, wire } from 'lwc';
import getConstituentAdvanceFilters from '@salesforce/apex/MapFinderController.getConstituentAdvanceFilters';

export default class MapFinderCmp extends LightningElement {
    addressText;
    selectedRadius;
    showAdvanceFilter = false;
    advanceSearchFilters;

    showMap = false;
    showPins = true;

    @wire(getConstituentAdvanceFilters)
    wiredAdvanceFilters({ data, error }) {
        if (data) {
            this.advanceSearchFilters = data.map(item => {
                return {
                    ...item,
                    style: `grid-row: span ${item.isMultiRow ? item.type == 'number' ? 1 : 3 : 1};`
                }
            });
        }
    }

    handleChange(event) {
        const prop = event.currentTarget.getAttribute('data-prop');
        this[prop] = event.target.value;
        console.log(`${prop} = ${this[prop]}`);
        
    }

    handleToggleChange(event) {
        const prop = event.currentTarget.getAttribute('data-prop');
        this[prop] = !this[prop];
        console.log(`${prop} = ${this[prop]}`);
    }

    handleOnFilterMenu(event) {

    }

    get advanceFilterdisabled() {
        return !this.advanceSearchFilters || this.advanceSearchFilters.length === 0;
    }

    get disableShowPinsBtn() {
        return !this.showMap
    }

    get radius() {
        return [
            {
                label: '--None--',
                value: null
            },
            {
                label: '1 Miles',
                value: '1'
            },
            {
                label: '5 Miles',
                value: '5'
            },
            {
                label: '10 Miles',
                value: '10'
            },
            {
                label: '25 Miles',
                value: '25'
            },
            {
                label: '50 Miles',
                value: '50'
            },
            {
                label: '4K Miles',
                value: '4000'
            }
        ];
    }
}