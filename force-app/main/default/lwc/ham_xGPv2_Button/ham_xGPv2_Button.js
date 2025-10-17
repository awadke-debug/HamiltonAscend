import { LightningElement, api, wire} from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import { CurrentPageReference } from 'lightning/navigation';

export default class HamXGPv2Button extends LightningElement {
    @wire(CurrentPageReference) getStateParameters(currentPageReference) {
        if (currentPageReference) {
            this.recordId = currentPageReference.state.recordId;
        }
    }
    connectedCallback() {
//    let namespace = 'ucinn_ascendv2__';
//    var urlString = "/lightning/n/ucinn_ascendv2__Expedited_Gift_ProcessingV2?ucinn_ascendv2__recordId=" + this.recordId;
    var urlString = "/lightning/n/Expedited_Gift_Processing_v2_HAM1?ucinn_ascendv2__recordId=" + this.recordId;
    window.open(urlString, "_blank"); this.dispatchEvent(new CloseActionScreenEvent());
    }
}