import getAllProperties from '@salesforce/apex/MapFinderController.getAllProperties';

export function fileNameDatePart() {
    const now = new Date();
    const year = now.getFullYear();
    const month = (now.getMonth() + 1).toString().padStart(2, '0');
    const day = now.getDate().toString().padStart(2, '0');
    const hours = now.getHours().toString().padStart(2, '0');
    const minutes = now.getMinutes().toString().padStart(2, '0');
    const seconds = now.getSeconds().toString().padStart(2, '0');

    return `${year}${month}${day}_${hours}${minutes}${seconds}`;
}

export function extractProp(curr) {
    let lookup;
    let prop;
    if (curr.includes('.')) {
        lookup = curr.split('.')[0];
        prop = curr.split('.')[1];
    } else {
        prop = curr;
    }

    return [lookup, prop];
}

export async function buildCsvHeader(selectedCols, mapInstance) {
    const allColumns = await getAllProperties({ mapInstance: mapInstance });
    
    return selectedCols.reduce((acc, curr, idx) => {
        const [lookup, prop] = extractProp(curr);

        return `${acc}${idx === 0 ? '' : ','} ${lookup ? allColumns.find(col => col.lookupApiName == lookup && col.fieldName == prop).label : allColumns.find(col => col.fieldName == prop).label}`
    }, '');
}

export function buildCsvContent(contactsForExport, selectedCols) {
    let csvContent = '';
    contactsForExport.map(contact => {
        const contactRow = selectedCols.reduce((acc, curr, idx) => {

            const [lookup, prop] = extractProp(curr);

            return `${acc}${idx === 0 ? '' : ','} ${lookup ? contact[lookup][prop] : contact[prop]}`
        }, '');

        return `${contactRow}\n`

    }).forEach(contactRow => {
        csvContent += contactRow;
    });

    return csvContent;
}

export async function buildXlsHeader(selectedCols, mapInstance) {
    const allColumns = await getAllProperties({ mapInstance: mapInstance });
    let header = '<tr>';
    header += selectedCols.reduce((acc, curr, idx) => {
        const [lookup, prop] = extractProp(curr);

        return `${acc}${idx === 0 ? '<th>' : '</th><th>'}${lookup ? allColumns.find(col => col.lookupApiName == lookup && col.fieldName == prop).label : allColumns.find(col => col.fieldName == prop).label}`
    }, '');

    return `${header}</th></tr>`;
}

export function buildXlsContent(contactsForExport, selectedCols) {
    let csvContent = '';
    contactsForExport.map(contact => {
        const contactRow = selectedCols.reduce((acc, curr, idx) => {

            const [lookup, prop] = extractProp(curr);

            return `${acc}${idx === 0 ? '<td>' : '</td><td>'}${lookup ? contact[lookup][prop] : contact[prop]}`
        }, '');

        return `${contactRow}</td>`

    }).forEach(contactRow => {
        csvContent += `<tr>${contactRow}</tr>`;
    });

    return csvContent;
}