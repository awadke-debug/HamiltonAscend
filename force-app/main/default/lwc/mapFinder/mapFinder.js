import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import SheetJS from '@salesforce/resourceUrl/SheetJS';
import { loadScript, loadStyle } from 'lightning/platformResourceLoader';
import Id from '@salesforce/user/Id';

import getConstituentAdvanceFilters from '@salesforce/apex/MapFinderController.getConstituentAdvanceFilters';
import getMarkerProperties from '@salesforce/apex/MapFinderController.getMarkerProperties';
import getDataTableProperties from '@salesforce/apex/MapFinderController.getDataTableProperties';
import getMarkerDescriptionProperties from '@salesforce/apex/MapFinderController.getMarkerDescriptionProperties';
import getAddressCoordinates from '@salesforce/apex/MapFinderController.getAddressCoordinates';
import getContactsForExport from '@salesforce/apex/MapFinderController.getContactsForExport';
import saveFilters from '@salesforce/apex/MapFinderController.saveFilters';
import invalidSavedFilters from '@salesforce/apex/MapFinderController.invalidSavedFilters';
import deleteSavedFilters from '@salesforce/apex/MapFinderController.deleteSavedFilters';
import addCampaignMembers from '@salesforce/apex/MapFinderController.addCampaignMembers';
import loadSavedFilterByExternalId from '@salesforce/apex/MapFinderController.loadSavedFilterByExternalId';

import { fileNameDatePart, buildCsvHeader, buildCsvContent, buildXlsHeader, buildXlsContent } from 'c/mapFinderExportUtil';

function extractAddress(item, addressFields) {
    let locationItem = {};

    addressFields.forEach(col => {

        let val = col.lookupApiName ? item[col.lookupApiName][col.fieldName] : item[col.fieldName];

        if (col.locationProperty === 'Latitude' || col.locationProperty === 'Longitude') {
            val = `${val}`;
        }

        locationItem[col.locationProperty] = val;
    });

    return locationItem;
}

function populateMarkers(item, tempMarkers) {
    const locationItem = extractAddress(item, this.addressFields);

    let tempMarker = {
        location: { ...locationItem },
        value: item.Id,
        icon: 'standard:people',
    };

    if (this.mapTitlePropertyLookupObject) {
        tempMarker.title = item[this.mapTitlePropertyLookupObject][this.mapTitleProperty];
    } else {
        tempMarker.title = item[this.mapTitleProperty];
    }

    if (this.markerDescProps) {
        tempMarker.description = this.markerDescProps.reduce((acc, curr, idx) => {
            const { label, lookupApiName, fieldName } = curr;
            return `${acc}${idx === 0 ? '' : '<br/>'}<small><strong>${label}</strong> ${(lookupApiName ? item[lookupApiName][fieldName] : item[fieldName]) || '--'}</small>`
        }, '');
    }

    tempMarkers.push(tempMarker);
}

function getBooleanValue(value) {
    if (typeof value !== 'boolean') {
        return (value === 'true');
    } else {
        return value;
    }
}
export default class MapFinder extends LightningElement {
    @api mapInstance;
    @api showTable;
    @api contactIdField;
    @api mapTitleProperty;
    @api mapTitlePropertyLookupObject;
    @api hidePageNav = false;

    _showAddToCampaignBtn;
    @api get showAddToCampaignBtn() {
        return this._showAddToCampaignBtn;
    }
    set showAddToCampaignBtn(value) {
        this._showAddToCampaignBtn = getBooleanValue(value);
    }

    _isSchedulable;
    @api get isSchedulable() {
        return this._isSchedulable;
    }
    set isSchedulable(value) {
        this._isSchedulable = getBooleanValue(value);
    }

    _showExportResultBtn;
    @api get showExportResultBtn() {
        return this._showExportResultBtn;
    }

    set showExportResultBtn(value) {
        this._showExportResultBtn = getBooleanValue(value);
    }

    @track
    mapMarkers = [];
    listView = 'visible';
    zoomLevel;
    selectedMarkerValue = '';
    center;
    addressFields;
    markerDescProps;
    tableColumns;

    advanceSearchFilters;
    showAdvanceFilter = false;
    selectedRadius;
    filters = [];
    coords = {}
    addressText;

    dataTblCmp;
    addressInputCmp;
    radiusInputCmp;

    showCreateMeeting = false;
    inputVariables = [];

    displaySpinner = false;

    showExportResults = false;
    showAddToCampaign = false;
    showMap = false;
    showPins = true;

    currentUserId = Id;

    _populateMarkers = populateMarkers.bind(this);

    async connectedCallback() {
        try {
            this.displaySpinner = true;

            const [ls, errors, address, radius] = await Promise.all([
                loadScript(this, SheetJS),
                invalidSavedFilters({ mapInstance: this.mapInstance }),
                loadSavedFilterByExternalId({ mapInstance: this.mapInstance, externalId: `address${this.currentUserId}` }),
                loadSavedFilterByExternalId({ mapInstance: this.mapInstance, externalId: `radius${this.currentUserId}` })
            ]);

            this.addressText = address?.Value__c;
            this.selectedRadius = radius?.Value__c;

            this.displaySpinner = false;

            if (errors && errors.length > 0) {

                this.dispatchEvent(new ShowToastEvent({
                    title: 'Saved filter(s) deleted/inactive',
                    message: `Advance Search saved filter(s) [${errors.join()}] deleted/inactive.`,
                    variant: 'warning',
                    mode: 'sticky',
                }));

            }

        } catch (error) {
            console.error('Missing dependency: ' + error);
        }
    }

    renderedCallback() {
        if (!this.dataTblCmp) {
            this.dataTblCmp = this.template.querySelector('c-map-finder-constituent-table');
        }

        if (!this.addressInputCmp) {
            this.addressInputCmp = this.template.querySelector('.address-zip');
        }

        if (!this.radiusInputCmp) {
            this.radiusInputCmp = this.template.querySelector('.radius-select');
        }
    }

    markerDescPropsLoading = true;
    @wire(getMarkerDescriptionProperties, { mapInstance: '$mapInstance' })
    wiredMarkerDescProps(res) {
        const { error, data } = res;
        
        if (data) {
            this.markerDescProps = data;
            this.markerDescPropsLoading = false;
        } else if (error) {
            console.error('error',JSON.stringify(error));
            this.markerDescPropsLoading = false;
        }
    }

    markerPropertiesLoading = true;
    @wire(getMarkerProperties, { mapInstance: '$mapInstance' })
    wiredMarkerProperties(res) {
        const { error, data } = res;
        
        if (data) {
            this.addressFields = data;
            this.markerPropertiesLoading = false;
        } else if (error) {
            console.error('error',JSON.stringify(error));
            this.markerPropertiesLoading = false;
        }
    }

    dataTablePropertiesLoading = true;
    @wire(getDataTableProperties, { mapInstance: '$mapInstance' })
    wiredDataTableProperties(res) {
        const { error, data } = res;
        
        if (data) {
            this.tableColumns = data;
            this.dataTablePropertiesLoading = false;
        } else if (error) {
            console.error('error',JSON.stringify(error));
            this.dataTablePropertiesLoading = false;
        }
    }

    advanceFiltersLoading = true;
    @wire(getConstituentAdvanceFilters, { mapInstance: '$mapInstance' })
    wiredAdvanceFilters(res) {
        const { data, error } = res;
        
        if (data) {
            this.advanceSearchFilters = data.map(item => {
                return {
                    ...item,
                    style: `grid-row: span ${item.isMultiRow ? item.type == 'number' ? 1 : 3 : 1};`
                }
            });
            this.advanceFiltersLoading = false;

        } else if (error) {
            console.error('error',JSON.stringify(error));
            this.advanceFiltersLoading = false;
        }
    }

    async handleSearch(event) {
        this.displaySpinner = true;

        if (!this.validateSearchParams()) {
            this.displaySpinner = false;
            return;
        }

        if (this.addressText && this.addressText.trim().length > 0) {
            this.coords = await getAddressCoordinates({ addressParam: this.addressText });
        } else {
            this.coords = {};
        }

        this.filters = [];
        const filterCmps = this.template.querySelectorAll('c-map-filter-item');
        filterCmps.forEach(filter => {
            if (filter.value && filter.field.improperlyConfigured != true) {
                this.filters.push({
                    fieldName: filter.field.fieldApiName,
                    operator: filter.operator || '=',
                    fieldValue: filter.value,
                    fieldType: filter.field.dataType,
                    isRange: filter.isRange,
                    lookupFieldApiName: filter.field.objectsLookupApiName
                })
            }
        });

        if ((!this.filters || this.filters.length === 0) && (!this.coords?.Latitude || !this.coords?.Longitude || !this.selectedRadius)) {
            this.dispatchEvent(new ShowToastEvent({
                title: "Blank Search",
                message: "Please enter an address and radius to search.",
                variant: "error",
            }));
        }

        this.contacts = await this.dataTblCmp.searchConstituents(this.filters, this.coords, this.selectedRadius, true);

        this.dispatchEvent(new CustomEvent('search', {
            detail: {
                result: this.contacts
            }
        }))

        this.displaySpinner = false;

        this.buildMarkers();

        if (this.coords?.Latitude && this.coords?.Longitude) {
            this.selectedMarkerValue = this.addressText;

            if (this.mapMarkers.length === 1) {
                this.zoomLevel = 18;
            }
        } 

        this.showMap = true;
        this.showPins = true;
    }

    async handleClearSearch(event) {
        this.addressText = null;
        this.selectedRadius = null;
        this.filters = [];
        this.coords = {};

        this.resetFilterItemsValues();

        await this.dataTblCmp.searchConstituents(this.filters, this.coords, this.selectedRadius);

        this.mapMarkers = [];
        this.showMap = false;
    }

    handleTogglePin(event) {
        this.showPins = !this.showPins;

        this.selectedMarkerValue = null;

        this.zoomLevel = null;

        if (this.showPins) {
            this.buildMarkers();
            this.zoomLevel = null;

        } else {
            this.mapMarkers = [];
            if (this.coords?.Latitude && this.coords?.Longitude) {
                this.selectedMarkerValue = this.addressText;

                this.mapMarkers = [{ 
                    location: {
                        ...this.coords
                    },
                    value: this.addressText, icon: 'custom:custom64', title: this.addressText, 
                }];
                this.zoomLevel = 18;
            }
        }

        this.dataTblCmp.resetTblHighlight();
    }

    handleRowSelect(event) {
        const { idx, unselect } = event.detail;

        let markerIdx = this.showPins ? idx : 0;

        if (this.coords?.Latitude && this.coords?.Longitude) {
            markerIdx++;
        }

        if (!this.showPins) {
            this.buildMarkers(idx);
        }
        this.selectedMarkerValue = unselect ? null : this.mapMarkers[markerIdx].value;
        this.center = unselect ? null : { location: this.mapMarkers[markerIdx].location };

        if (!unselect) {
            this.zoomLevel = 18;
        } 
    }

    handleCheckRow(event) {
        const { idsToExport } = event.detail;

        try {
            this.dispatchEvent(new CustomEvent('checkrow', {
            detail: {
                rows: idsToExport.map((recId, idx) => {
                    const contact = this.contacts.find(item => item.Id === recId);
                    const address = extractAddress(contact, this.addressFields);

                    return {
                        contactId: contact[this.contactIdField],
                        id: recId,
                        ...address
                    }
                }),
            }
        }));
        } catch (error) {
            console.log(error.message);
            
        }
        

    }

    @api
    handleUncheckRow(id) {
        console.log('handleUncheckRow', id);
        
        this.dataTblCmp.unselectRow(id);
    }

    handleSelectAll(event) {
        this.dispatchEvent(new CustomEvent('selectall', {
            detail: {
                rows: event.detail ? this.contacts.map(con => {
                    return {
                        contactId: con[this.contactIdField],
                        id: con.Id,
                        ...extractAddress(con, this.addressFields)
                    }
                }) : [],
            }
        }));
    }

    handleMarkerSelect(event) {
        const selectedMarker = event.detail.selectedMarkerValue;

        this.selectedMarkerValue = selectedMarker;

        if (!selectedMarker) {
            this.center = {};
            this.zoomLevel = null;
            return;
        }
        
        if (selectedMarker !== this.addressText) {
            this.center = { location: this.mapMarkers.find(mark => mark.value === selectedMarker)?.location };

            this.zoomLevel = 18;
        } else {

            this.center = { location: { ...this.coords } };

            if (this.mapMarkers.length === 1) {
                this.zoomLevel = 18;
            }
        }
    }

    buildMarkers(selectedIdx) {
        let tempMarkers = [];

        if (this.contacts && this.contacts.length > 0) {
            this.contacts.forEach((item, idx) => {
                if ((!isNaN(selectedIdx) && selectedIdx == idx) || isNaN(selectedIdx)) {
                    this._populateMarkers(item, tempMarkers);
                }
            });
        }

        if (this.coords?.Latitude && this.coords?.Longitude) {

            tempMarkers.unshift({
                location: {
                    ...this.coords
                },
                value: this.addressText,
                icon: 'custom:custom64',
                title: this.addressText,
            });
        }

        this.mapMarkers = [...tempMarkers];
    }

    handleScheduleMeeting(event) {
        let tempInputVars = [
            {
                name: 'recordId',
                type: 'String',
                value: event.detail
            }
        ]
        this.inputVariables = [...tempInputVars];

        this.showCreateMeeting = true;
    }

    handleStatusChange(event) {
        if (event.detail.status === 'FINISHED') {
            this.showCreateMeeting = false;
        }
    }

    async handleExportResults(event) {
        const { columns, format, extension } = event.detail;
        this.displaySpinner = true;

        this.showExportResults = false;

        const contactsForExport = await getContactsForExport({
            mapInstance: this.mapInstance,
            fields: columns,
            filterWrapper: {
                advanceFilterParams: this.filters,
                latitude: this.coords?.Latitude,
                longitude: this.coords?.Longitude,
                radius: this.selectedRadius,
                addressRelationIds: this.dataTblCmp.isAllSelected ? this.dataTblCmp.idsToExclude : this.dataTblCmp.idsToExport,
                isExportAll: this.dataTblCmp.isAllSelected },
            sortBy: this.dataTblCmp.sortBy,
            sortDirection: this.dataTblCmp.sortDirection,
        });

        let content = '';
        let element;
        if (extension === 'csv') {
            content = await buildCsvHeader(columns, this.mapInstance);

            content += '\n';
            content += buildCsvContent(contactsForExport, columns);

            element = `${format},` + encodeURI(content);

        } else {

            content = '<table>';
            content += await buildXlsHeader(columns, this.mapInstance);
            content += buildXlsContent(contactsForExport, columns);
            content += '</table>';

            const parser = new DOMParser();
            const doc = parser.parseFromString(content, 'text/html');

            var wb = XLSX.utils.table_to_book(doc.querySelector('table'));
            const excelBuffer = XLSX.write(wb, { bookType: extension, type: 'array' });
            const blob = new Blob([excelBuffer], { type: 'application/octet-stream' });

            element = URL.createObjectURL(blob);
        }

        let downloadElement = document.createElement('a');
        downloadElement.href = element;
        downloadElement.target = '_self';
        downloadElement.download = `Constituents_extract_${fileNameDatePart()}.${extension}`;
        document.body.appendChild(downloadElement);
        downloadElement.click();

        URL.revokeObjectURL(downloadElement.href);

        this.displaySpinner = false;

    }

    handleAddToCampaign(event) {
        this.displaySpinner = true;

        const filterWrapper = { advanceFilterParams: this.filters, latitude: this.coords?.Latitude, longitude: this.coords?.Longitude, radius: this.selectedRadius, addressRelationIds: this.dataTblCmp.isAllSelected ? this.dataTblCmp.idsToExclude : this.dataTblCmp.idsToExport, isExportAll: this.dataTblCmp.isAllSelected };

        addCampaignMembers({
            mapInstance: this.mapInstance,
            filterWrapper: filterWrapper,
            campaignId: event.detail
        }).then(() => {

            this.dispatchEvent(new ShowToastEvent({
                title: 'Members added',
                message: 'Members added',
                variant: 'success'
            }));
        }).catch(error => {
            console.log('Error adding to campaign', error.message);

            this.dispatchEvent(new ShowToastEvent({
                title: 'Error adding to campaign',
                message: 'Error adding to campaign',
                variant: 'error'
            }));
        }).finally(() => {
            this.displaySpinner = false;
        });

        this.showAddToCampaign = false;
    }

    handleOnFilterMenu(event) {
        if (event.detail.value == 'save') {
            this.saveFilter();
        } else if (event.detail.value == 'load') {
            this.displaySpinner = true;
            const filterCmps = this.template.querySelectorAll('c-map-filter-item');
            const promisesCombined = [];

            filterCmps.forEach(filter => {
                promisesCombined.push(filter.loadSavedFilter());
            });

            promisesCombined.push(
                loadSavedFilterByExternalId({ mapInstance: this.mapInstance, externalId: `address${this.currentUserId}` }),
                loadSavedFilterByExternalId({ mapInstance: this.mapInstance, externalId: `radius${this.currentUserId}` }));

            let hasSavedFilters = false;
            Promise.all(promisesCombined).then((results) => {
                for (let i = 0; i < results.length - 2; i++) {
                    const result = results[i];

                    if (!result) {
                        continue;
                    }

                    filterCmps[i].value = result.Value__c;
                    filterCmps[i].operator = result.Operator__c;
                    filterCmps[i].isRange = result.Is_Range__c;
                    filterCmps[i].multipickValue = result.Value__c.split(';');
                    hasSavedFilters = true;
                }

                if (!hasSavedFilters) {
                    hasSavedFilters = results[results.length - 2] && true || results[results.length - 1] && true;
                }
                
                this.addressText = results[results.length - 2]?.Value__c;
                this.selectedRadius = results[results.length - 1]?.Value__c;

                this.displaySpinner = false;

                if (!hasSavedFilters) {
                    this.dispatchEvent(new ShowToastEvent({
                        title: 'No saved filters',
                        message: 'No saved filters',
                        variant: 'info'
                    }));
                }
            });

        } else if (event.detail.value == 'delete') {
            this.deleteUserFilters();
        } else if (event.detail.value == 'clear') {
            this.resetFilterItemsValues();
        }
    }

    showSpinner() {
        this.displaySpinner = true;
    }

    handlePageChange(event) {
        this.contacts = [...event.detail];
        this.buildMarkers();
        this.showPins = true;
        this.zoomLevel = null;
        this.displaySpinner = false;
    }

    handleZoomChange(event) {
        this.zoomLevel = event.detail.value;
    }

    saveFilter() {
        let filters = [];
        const filterCmps = this.template.querySelectorAll('c-map-filter-item');
        filterCmps.forEach(filter => {
            if (filter.value && filter.field.improperlyConfigured != true) {
                filters.push({
                    owner: this.currentUserId,
                    key: filter.field.key,
                    operator: filter.operator,
                    fieldValue: filter.value,
                    isRange: filter.isRange,
                    fieldLabel: filter.field.label,
                });
            }
        });

        if (this.addressText && this.addressText.trim().length > 0) {
            filters.push({
                owner: this.currentUserId,
                key: 'address',
                operator: '=',
                fieldValue: this.addressText,
                isRange: false,
                fieldLabel: 'Address',
            });
        }

        if (this.selectedRadius) {
            filters.push({
                owner: this.currentUserId,
                key: 'radius',
                operator: '=',
                fieldValue: this.selectedRadius,
                isRange: false,
                fieldLabel: 'Radius',
            });
        }

        if (filters.length > 0) {
            this.displaySpinner = true;
            saveFilters({
                mapInstance: this.mapInstance,
                params: filters
            }).then(() => {
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Filter saved',
                    message: 'Filter saved',
                    variant: 'success'
                }));
            }).catch(error => {
                console.log('Error saving filters', error.message);
            }).finally(() => {
                this.displaySpinner = false;
            });
        } else {
            this.dispatchEvent(new ShowToastEvent({
                title: 'No filter to save',
                message: 'No filter to save',
                variant: 'error'
            }));
        }

    }

    deleteUserFilters() {
        this.displaySpinner = true;
        deleteSavedFilters({ mapInstance: this.mapInstance }).then(() => {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Filters deleted',
                message: 'Filters deleted',
                variant: 'success'
            }));

            this.addressText = null;
            this.selectedRadius = null;

            this.resetFilterItemsValues();
        }).catch(error => {
            console.log('Error deleting filters', error.message);
        }).finally(() => {
            this.displaySpinner = false;
        })
    }

    resetFilterItemsValues() {
        const filterCmps = this.template.querySelectorAll('c-map-filter-item');
        filterCmps.forEach(filter => {
            filter.resetValues();
        });
    }

    validateSearchParams() {
        let isValid = true;
        if ((this.addressText && this.addressText.trim().length > 0) || this.selectedRadius) {
            if (!this.addressText) {
                this.addressInputCmp.setCustomValidity('Address is required when radius is specified.');
                isValid = false;
            } else {
                this.addressInputCmp.setCustomValidity('');
            }

            if (!this.selectedRadius) {
                this.radiusInputCmp.setCustomValidity('Radius is required when address is specified.');
                isValid = false;

            } else {
                this.radiusInputCmp.setCustomValidity('');
            }


        }

        if (isValid) {
            this.addressInputCmp.setCustomValidity('');
            this.radiusInputCmp.setCustomValidity('');
        }

        this.addressInputCmp.reportValidity();
        this.radiusInputCmp.reportValidity();

        return isValid;
    }


    handleCloseExportResults(event) {
        this.showExportResults = false;
    }

    handleShowExportResults(event) {
        this.showExportResults = true;
    }

    handleCloseAddToCampaign(event) {
        this.showAddToCampaign = false;
    }

    handleShowAddToCampaign(event) {
        this.showAddToCampaign = true;
    }

    handleToggleMap(event) {
        this.showMap = !this.showMap;
        if (this.showMap) {
            this.zoomLevel = null;
        }
    }

    handleCloseMeetingModal(event) {
        this.showCreateMeeting = false;
    }

    handleToggleFilter() {
        this.showAdvanceFilter = !this.showAdvanceFilter;
    }

    handleAddressChange(event) {
        this.addressText = event.target.value;
    }

    handleRadiusChange(event) {
        this.selectedRadius = event.target.value;
    }

    get showAddressInputText() {
        return !this.showInputAddress;
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