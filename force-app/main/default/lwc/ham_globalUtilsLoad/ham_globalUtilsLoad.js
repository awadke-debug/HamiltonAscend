import { LightningElement } from 'lwc';
import { loadScript } from 'lightning/platformResourceLoader'

import namespaceUtils from '@salesforce/resourceUrl/ucinn_ascendv2__AscendNamespaceUtils';

export default class Ham_globalUtilsLoad extends LightningElement {
    isLoading = true;
    namespace;

    connectedCallback() {
        this.initialize();
    }

    initialize = async () => {
        await loadScript(this, namespaceUtils);
        this.isLoading = false;
        this.namespace = _globalUtils.getNamespace();
    }
}