public with sharing class DigitalBriefingPdfPreviewerController {
    public DigitalBriefingPdfPreviewerController() {

    }

    public PageReference previewDigitalBriefing() {
        // Attachment attachment = new Attachment();
        // attachment.ParentId = '003VG00000cIYxOYAW';
        // attachment.name = 'PDF_'+String.valueof(Datetime.now())+'.pdf';
        // attachment.ContentType = 'application/pdf';

        PageReference pdf = Page.digitalBriefingPdf;
        pdf.setRedirect(true);
        
        // attachment.Body = pdf.getContent();
        // insert attachment;

        ContentVersion cv = new ContentVersion();
        cv.ContentLocation = 'S';
        cv.VersionData = pdf.getContent();
        cv.Title = 'PDF_'+String.valueof(Datetime.now())+'.pdf';
        cv.PathOnClient = 'PDF_'+String.valueof(Datetime.now())+'.pdf';
        cv.IsMajorVersion = true;
        insert cv;

        System.debug('@@cv.ContentDocumentId:: ' + cv.ContentDocumentId);

        // PageReference ret = new PageReference('/servlet/servlet.FileDownload?file=' + attachment.Id);
        PageReference ret = new PageReference('/sfc/servlet.shepherd/document/download/' + [select ContentDocumentId from ContentVersion where Id = :cv.Id].ContentDocumentId);
        // return pdf;]);
        ret.setRedirect(true);
        return ret;
    }
}