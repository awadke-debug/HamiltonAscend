import { LightningElement, api } from 'lwc';
import { loadScript } from 'lightning/platformResourceLoader'
import namespaceUtils from '@salesforce/resourceUrl/ucinn_ascendv2__AscendNamespaceUtils';

export default class Ham_RelationshipMapWrapper extends LightningElement {
    @api recordId;
    isLoading = true;
    namespace;

    connectedCallback() {
        loadScript(this, namespaceUtils).then(() => {
            this.namespace = _globalUtils.getNamespace();
            setTimeout(() => { this.isLoading = false }, 1000)
        });
    }
}