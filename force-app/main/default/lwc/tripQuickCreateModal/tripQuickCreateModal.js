import LightningModal from 'lightning/modal';

export default class TripQuickCreateModal extends LightningModal {

    handledTripCreated(event) {
        this.close(event.detail);
    }
}