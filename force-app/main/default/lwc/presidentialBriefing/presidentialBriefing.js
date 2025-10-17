import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

export default class PresidentialBriefing extends NavigationMixin(LightningElement) {
    _recordId;

    @api 
    set recordId(value) {
        if (this._recordId !== value) {
            this._recordId = value;

            this[NavigationMixin.Navigate]({
                type: "standard__component",
                attributes: {
                    componentName: "c__digitalBriefingPdfCmp"
                },
                state: {
                    c__recordId: this._recordId
                }
            });

        }
    }

    get recordId() {
        return this._recordId;
    }

}