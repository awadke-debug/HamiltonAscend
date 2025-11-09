import { LightningElement, wire, track, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import getConstituentsByFilters from '@salesforce/apex/MapFinderController.getConstituentsByFilters';
import isMarketingUser from '@salesforce/apex/MapFinderController.isMarketingUser';
import isCampaignMemberFieldValid from '@salesforce/apex/MapFinderController.isCampaignMemberFieldValid';
import isValidContactField from '@salesforce/apex/MapFinderController.isValidContactField';

import mapPagination from './mapPagination.html';
import mapSearchResultTable from './mapSearchResultTable.html';

const EVEN_COLOR = '#F9F9F9';
const ODD_COLOR = '#ffffff';
const SELECTED_COLOR = '#02C7E9';

function getCellStyle(idx, selectedIdx, currentIdx) {
    let background = EVEN_COLOR;
    if (idx == selectedIdx && selectedIdx != currentIdx) {
        background = SELECTED_COLOR;
    } else {
        if (idx % 2 != 0) {
            background = ODD_COLOR;
        }
    }

    return `background-color: ${background}; padding: 0.5rem; display: table-cell; display: flex; align-items: center; border-bottom: 1px solid #DDDDDD; cursor: pointer;`;
}

export default class MapFinderConstituentTable extends LightningElement {
    @api mapInstance;
    @api showTable;
    @api showAddToCampaignBtn;
    @api isSchedulable;
    @api contactIdField;
    @api showExportResultBtn;

    @track
    contacts;
    @track
    contactAllColumns;

    offset = 0;
    pageSize = 10;

    @api sortBy;
    @api sortDirection = 'ASC';

    @api
    totalSize = 0;
    totalPages = 0;
    pageNum = 1;

    filters;
    originPoint;
    radius;
    filterAugmentation;

    @api
    hidePageNav = false;
    displaySpinner = false;

    @track
    _tableColumns;
    @api get tableColumns() {
        return this._tableColumns;
    }
    set tableColumns(value) {
        if (!value) {
            return;
        }
        
        this._tableColumns = value.map((item, idx) => {
            if(idx === 0) {
                this.sortBy = item.fullFieldName;
            }

            return {
                ...item,
                isSortByThisField: this.sortBy.includes(item.fullFieldName)
            }
        });
    }

    selectedIdx;

    @api
    idsToExport = [];
    @api
    idsToExclude = [];
    @api
    isAllSelected = false;

    @wire(isMarketingUser)
    _isMarktingUser;

    @wire(isCampaignMemberFieldValid, { mapInstance: '$mapInstance' })
    _validCampaignMemberField;

    render() {
        return this.showTable ? mapSearchResultTable : mapPagination;
    }

    handleRowSelect(event) {
        const selectedIdx = event.currentTarget.getAttribute('data-idx');

        this.contacts.forEach((item, idx) => {
            item.style = getCellStyle(idx, selectedIdx, this.selectedIdx);
        });

        this.selectedIdx = selectedIdx == this.selectedIdx ? null : selectedIdx;

        this.dispatchEvent(new CustomEvent('rowselect', {
            detail:
                { idx: selectedIdx, unselect: !this.selectedIdx }
        }));
    }

    @api
    async searchConstituents(filters, originPoint, radius, isNewSearch, filterAugmentation) {
            this.filters = isNewSearch ? filters : (filters || this.filters);
            this.originPoint = isNewSearch ? originPoint : (originPoint || this.originPoint);
            this.radius = isNewSearch ? radius : (radius || this.radius);
            this.filterAugmentation = isNewSearch ? filterAugmentation : (filterAugmentation || this.filterAugmentation);
    
            if ((!this.filters || this.filters.length === 0) 
                    && (!this.originPoint?.Latitude || !this.originPoint?.Longitude || !this.radius)
                    && (!this.filterAugmentation || Object.keys(this.filterAugmentation).length === 0)) {
                
                this.contacts = [];
                return;
            }
    
            if (isNewSearch) {
                this.idsToExclude = [];
                this.idsToExport = [];
                this.isAllSelected = false;
                this.offset = 0;
                this.pageNum = 1;
            }
    
            this.displaySpinner = true;
    
            const result = await getConstituentsByFilters({
                mapInstance: this.mapInstance,
                filterWrapper: {
                    advanceFilterParams: this.filters,
                    latitude: this.originPoint?.Latitude,
                    longitude: this.originPoint?.Longitude,
                    radius: this.radius,
                    filterAugmentation: this.filterAugmentation ? JSON.stringify(this.filterAugmentation) : '',
                },
                offset: this.offset,
                pageSize: this.pageSize,
                sortBy: this.sortBy,
                sortDirection: this.sortDirection
            });
    
            this.totalSize = result.totalSize;
            this.totalPages = Math.ceil(this.totalSize / this.pageSize);
    
            this.contactAllColumns = result.constituents;
    
            this.contacts = this.contactAllColumns.map((filteredItem, idx) => {
                let contactItem = {};
                contactItem.style = getCellStyle(idx);
    
                this._tableColumns.forEach(col => {
                    contactItem[col.fieldName] = col.lookupApiName ? filteredItem[col.lookupApiName][col.fieldName] : filteredItem[col.fieldName];
                })
    
                return {
                    ...contactItem,
                    checked: this.idsToExport.includes(filteredItem['Id']) || (this.isAllSelected && !this.idsToExclude.includes(filteredItem['Id']))
                }
            });
    
            this.displaySpinner = false;
    
            return this.contactAllColumns;
    }

    handleScheduleMeeting(event) {
        const selectedIdx = event.currentTarget.getAttribute('data-idx');
        const contactId = this.contactAllColumns[selectedIdx][this.contactIdField];

        isValidContactField({ contactId: contactId })
            .then(isValidContact => {
                if (!isValidContact) {
                    this.dispatchEvent(new ShowToastEvent({
                        title: 'Unable to schedule meeting',
                        message: `Field "${this.contactIdField}" is not a valid Contact field.`,
                        variant: 'error'
                    }));
                    return;
                }

                this.dispatchEvent(new CustomEvent('schedulemeeting', { detail: contactId }));
            });

    }

    @api
    resetTblHighlight() {
        this.contacts.forEach((item, idx) => {
            item.style = getCellStyle(idx);
        });

        this.selectedIdx = null;
    }

    async handleSort(event) {
        this.sortBy = event.currentTarget.getAttribute('data-fieldname');

        this.sortDirection = this.sortDirection === 'ASC' ? 'DESC' : 'ASC';

        this._tableColumns.forEach(col => {
            col.isSortByThisField = this.sortBy.includes(col.fieldName);
        });

        this.dispatchEvent(new CustomEvent('search'));

        const result = await this.searchConstituents();

        this.dispatchEvent(new CustomEvent('pagechange', {
            detail: result
        }));

    }

    async handleNextPage(event) {
        if (this.pageNum < this.totalPages) {
            this.pageNum++;
            this.offset = (this.pageNum - 1) * this.pageSize;

            this.dispatchEvent(new CustomEvent('search'));

            const result = await this.searchConstituents();

            this.dispatchEvent(new CustomEvent('pagechange', {
                detail: result
            }));
        }

    }

    async handlePreviousPage(event) {
        if (this.pageNum > 1) {
            this.pageNum--;
            this.offset = (this.pageNum - 1) * this.pageSize;
            this.dispatchEvent(new CustomEvent('search'));

            const result = await this.searchConstituents();

            this.dispatchEvent(new CustomEvent('pagechange', {
                detail: result
            }));
        }
    }

    async handlePageSizeChange(event) {
        let sizeChanged = false;
        if (event.target.label === 'more' && this.pageSize < this.totalSize) {
            this.pageSize += 5;
            sizeChanged = true;
        } else if (event.target.label === 'less' && this.pageSize > 10){
            this.pageSize -= 5;
            sizeChanged = true;
        }

        if (!sizeChanged) {
            return;
        }

        this.dispatchEvent(new CustomEvent('search'));

        const result = await this.searchConstituents();

        this.dispatchEvent(new CustomEvent('pagechange', {
            detail: result
        }));
        
    }

    handleClickExport(event) {
        this.dispatchEvent(new CustomEvent('clickexport'));
    }

    handleAddToCampaign(event) {
        this.dispatchEvent(new CustomEvent('clickaddtocampaign'));
    }

    handleIncludeRow(event) {
        const checked = event.target.checked;
        const selectedIdx = event.currentTarget.getAttribute('data-idx');
        const id = this.contactAllColumns[selectedIdx].Id;

        this.contacts[selectedIdx].checked = checked;
        if (checked) {
            this.idsToExport.push(id);
            this.idsToExclude = this.idsToExclude.filter(item => id !== item);

        } else {
            this.idsToExclude.push(id);
            this.idsToExport = this.idsToExport.filter(item => id !== item);
        }


        if (this.idsToExclude.length === this.totalSize) {
            this.isAllSelected = false;
        }

        this.dispatchEvent(new CustomEvent('checkrow', {
            detail: {
                idsToExport: this.idsToExport,
            }
        }));

    }

    @api
    unselectRow(id) {
        console.log('unselectRow', id);

        this.contactAllColumns.forEach((item, idx) => {
            console.log(item.Id);
            if (item.Id === id) {
                this.contacts[idx].checked = false;
            }
        });

        this.idsToExport = this.idsToExport.filter(item => item !== id);
    }

    handleIncludeAll(event) {
        this.isAllSelected = !this.isAllSelected;
        this.contacts.forEach((item, idx) => {
            item.checked = this.isAllSelected;
        });

        this.idsToExport = [];
        if (this.isAllSelected) {
            this.idsToExclude = [];
        }

        this.dispatchEvent(new CustomEvent('selectall', {
            detail: this.isAllSelected
        }));
    }

    get disableAddToCampaign() {
        return (this.idsToExport.length === 0 && (!this.isAllSelected || this.isAllSelected && this.idsToExclude.length === this.totalSize)) || !this._isMarktingUser.data;
    }

    get isMarketingUser() {
        if (!this._isMarktingUser) {
            return false;
        }
        return this._isMarktingUser.data;
    }

    get displayAddToCampaignBtn() {
        if (!this._validCampaignMemberField) {
            return false;
        }
        return this._validCampaignMemberField.data && this.showAddToCampaignBtn;
    }

    get displayTable() {
        return this.contacts && this.contacts.length > 0;
    }

    get disableExport() {
        return this.idsToExport.length === 0 && (!this.isAllSelected || this.isAllSelected && this.idsToExclude.length === this.totalSize);
    }

    get displayExportResultBtn() {
        return this.showExportResultBtn;
    }

    get resultCoverageInfo() {
        let endRange = this.pageNum * this.pageSize;
        if (this.pageNum === this.totalPages) {
            endRange = this.totalSize;
        }
        return `Results: ${this.offset + 1}-${endRange} of ${this.totalSize}`;
    }

    get resultPageInfo() {
        return `Page ${this.pageNum} of ${this.totalPages}`;
    }

    get displayPagination() {
        return this.totalPages > 1;
    }

    get isAscending() {
        return this.sortDirection === 'ASC';
    }

    get tableStyle() {
        return this._tableColumns ? `display: grid; grid-template-columns: min-content repeat(${this._tableColumns.length}, 1fr)${this.isSchedulable ? ' min-content':''}; background: #ffffff; padding: 0.75rem; margin-top:1rem;` : '';
    }

    get noResultsDivStyle() {
        return `grid-column: 1 / -1; display: flex; justify-content: center; align-items: center;`
    }

    get constituentSelected() {
        const selectedCount = this.isAllSelected ? this.totalSize - this.idsToExclude.length : this.idsToExport.length;
        return `${selectedCount} constituent(s) selected to be exported.`;
    }

    get disableSort() {
        return this.idsToExport.length > 0 || (this.isAllSelected && this.idsToExclude.length < this.totalSize);
    }
}