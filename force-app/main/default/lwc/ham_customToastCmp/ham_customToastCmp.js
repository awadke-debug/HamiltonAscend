import { LightningElement,api } from 'lwc';
export default class Ham_customToastCmp extends LightningElement {
    @api title;
    @api message;
    @api variant 
    @api duration = 10000;
    isMobile = true;
    visible = false;

    connectedCallback() {
        this.visible = true;

        // Auto-close after duration
        setTimeout(() => {
            this.visible = false;
            const closeEvent = new CustomEvent('close');
            this.dispatchEvent(closeEvent);
        }, this.duration);
    }

    get toastClass() {
        return `toast ${this.variant} ${this.isMobile ? 'mobile-toast' : 'desktop-toast'}`;
    }

    handleErrorClose(){
        this.visible = false;

        const closeEvt = new CustomEvent('close');
        this.dispatchEvent(closeEvt);
    }
}