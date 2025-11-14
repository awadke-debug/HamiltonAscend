import LightningDatatable from 'lightning/datatable';

import clickableNameTemplate from './clickableName.html';

export default class TripCustomTable extends LightningDatatable {
    static customTypes = {
        customName: {
            template: clickableNameTemplate,
            standardCellLayout: true,
            typeAttributes: ['tripTitle', 'tripId'],
        }
    }

}