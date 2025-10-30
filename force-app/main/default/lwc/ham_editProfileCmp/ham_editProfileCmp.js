import { LightningElement,wire,api,track } from 'lwc';

// Importing Apex methods
import getMyPersonalInformation from '@salesforce/apex/HAM_EditProfileController.getMyPersonalInformation'; 
import saveMyPersonalInformation from '@salesforce/apex/HAM_EditProfileController.saveMyPersonalInformation'; 
import deleteProfilePic from '@salesforce/apex/HAM_EditProfileController.deleteProfilePic'; 

// Importing LWC framework modules
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';

// Importing custom labels
import editProfile from '@salesforce/label/c.ham_EditProfile'; 
import newPic from '@salesforce/label/c.ham_NewPic';
import firstName from '@salesforce/label/c.ham_EditProfFirstName'; 
import lastName from '@salesforce/label/c.ham_EditProfLastName';
import jobTitle from '@salesforce/label/c.ham_EditProfJobTitle'; 
import phone from '@salesforce/label/c.ham_EditProfPhone';
import email from '@salesforce/label/c.ham_EditProfEmail';
import linkedinURL from '@salesforce/label/c.ham_EditProfLinkedinURL';
import employer from '@salesforce/label/c.ham_EditProfEmployer';
import addressDetails from '@salesforce/label/c.ham_AddressDetails';
import street from '@salesforce/label/c.ham_EditProfStreet';
import city from '@salesforce/label/c.ham_EditProfCity';
import state from '@salesforce/label/c.ham_EditProfState';
import country from '@salesforce/label/c.ham_EditProfCountry';
import postalCode from '@salesforce/label/c.ham_EditProfPostalCode';
import cancel from '@salesforce/label/c.ham_Cancel';
import save from '@salesforce/label/c.ham_Save';

/**
 * @description A component to display and allow editing of a user's personal and professional information.
 * It handles data fetching, form input, saving changes, and profile picture management.
 */
export default class Ham_editProfileCmp extends LightningElement {
    @api userContactId;
    personalInfo;
    personalUpdatedInfo = {};
    constId = ''; // Constituent Id
    isLoading = false;
    isEditingImage = false;
    uploadedFileName;
    fileToUpload;
    updatedContentDocId;
    @api mainResource;
    @track images = {};

    // Wire property to store the result object for refreshApex
    wiredPersonalInfo;

    /**
     * @description Custom labels used in the component.
     */
    label = {
        editprofile: editProfile,
        newpic: newPic,
        firstname:firstName,
        lastname: lastName,
        jobtitle: jobTitle,
        phone: phone,
        email: email,
        linkedinurl: linkedinURL,
        employer: employer,
        addressdetails: addressDetails,
        street: street,
        city: city,
        state: state,
        country: country,
        postalcode: postalCode,
        cancel: cancel,
        save: save
    }

    /**
     * @description Lifecycle hook that runs when the component is inserted into the DOM.
     * Initializes image paths.
     */
    connectedCallback() {
        this.images = {
            cameraImage: this.mainResource + '/camera.png'
        };
    }

    /**
     * @description Wire service to fetch personal information for the current user's contact record.
     * The result is stored to allow for refreshing the data after a save operation.
     * @param {Object} result The wired result object containing data or error.
     */
    @wire(getMyPersonalInformation, { currentUserContactId: '$userContactId' })
    wiredGetMyPersonalInformation(result) {
        this.wiredPersonalInfo = result;
        const { error, data } = result;

        this.isLoading = true;
        if (data) {                     
            this.personalInfo = JSON.parse(JSON.stringify(data)); 
            this.constId = data.constId; // Setting Contact Id
            this.error = undefined; 
            this.isLoading = false;
        
        } else if (error) {
            console.error('Error fetching contact data:', error);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'An unexpected error occurred while fetching data.',
                    variant: 'error',
                    mode: 'sticky'
                })
            );
        }
    }

    /**
     * @description Handles changes in the input fields and updates the `personalUpdatedInfo` object.
     * It supports both direct fields and nested address fields.
     * @param {Event} event The change event from an input element.
     */
    handleChange(event) {
        let currentField = event.target.dataset.name;
        let currentValue = event.target.value;
        if (currentField.startsWith('addressInfo')) {
            // Create a new copy of the nested addressInfo object
            const newAddressInfo = { ...this.personalUpdatedInfo.addressInfo };
            
            // Split the field name to get the nested property
            const addressField = currentField.split('.');
            
            // Update the property on the new object
            newAddressInfo[addressField[1]] = currentValue;

            // Create a new copy of the main object and update the nested object reference
            this.personalUpdatedInfo = { ...this.personalUpdatedInfo,
                [addressField[0]]: newAddressInfo
            };
        } else {
            // For top-level properties, create a new object and update the property
            this.personalUpdatedInfo = { ...this.personalUpdatedInfo,
                [currentField]: currentValue
            };

            //Updating the phoneNo and email properties so that the made chage is visible on UI for these two fields
            if(this.personalUpdatedInfo.phoneNo){
                this.personalInfo.phoneNo = this.personalUpdatedInfo.phoneNo; 
            }
            if(this.personalUpdatedInfo.email){
                this.personalInfo.email = this.personalUpdatedInfo.email;
            }
        }
    }

    /**
     * @description Handles the save button click. It calls the Apex method to save the updated
     * personal information and handles the response, showing a toast message and refreshing data.
     */
    handleSave() {
        this.isLoading = true;
        Promise.resolve().then(() => {
            saveMyPersonalInformation({
                personalInfoResp: JSON.stringify(this.personalUpdatedInfo),
                currentUserContactId: this.constId, // Pass Contact Id
                contentDocId: this.updatedContentDocId // Pass Content Document Id
            }).then(response => { 
                    if(response === 'Success') { 
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: 'Success',
                                message: 'Your personal information has been updated successfully.',
                                variant: 'success',
                                mode: 'dismissable'
                            })
                        );
                        this.dispatchEvent(new CustomEvent('close'));                        
                        // Refresh the wired data
                        return refreshApex(this.wiredPersonalInfo)
                            .then(() => {
                            })
                            .catch(error => {
                                console.error('Error refreshing wired data:', error);
                            });
                    }
                    else {
                        //Custom error messages for phoneNo and email fields
                        let errorMessage;  
                        if(response.includes('ucinn_ascendv2__Phone_Number__c')){
                            errorMessage = this.personalUpdatedInfo.phoneNo+' is not valid. Please enter 10 to 13 digits number without any special characters  like (),-etc.';
                        }else if(response.includes('ucinn_ascendv2__Email_Address__c')){
                            errorMessage = this.personalUpdatedInfo.email+' is not valid. Please enter a valid email address';
                        }else{
                            errorMessage = 'An error occurred while saving your information. '+response;
                        }
                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: 'Error',
                                message: errorMessage,
                                variant: 'error',
                                mode: 'sticky'
                            })
                        );
                    }
                })
                .catch(error => {
                    this.isLoading = false;
                    console.error('Error saving personal information:', error);
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error',
                            message: 'An unexpected error occurred while saving your information.',
                            variant: 'error',
                            mode: 'sticky'
                        })
                    );
                })
            .finally(() => {
                this.isLoading = false;
            });
        });
    }

    /**
     * @description Handles the cancel button click. If a new image was uploaded, it first deletes it,
     * then dispatches a 'close' event.
     */
    handleCancel() {
        this.isLoading = true;
        if(this.updatedContentDocId != null) {
            this.deleteProfPic(); // Call method to delete existing content doc
            this.isLoading = false;
            this.dispatchEvent(new CustomEvent('close'));
        }
        else {
            this.isLoading = false;
            this.dispatchEvent(new CustomEvent('close'));
        }
    }

    /**
     * @description Handles the click on the camera icon, which reveals the file upload input.
     */
    handleCameraClick() {
       this.isEditingImage = true;
    }

     /**
     * @description Handles the completion of the file upload event from <lightning-file-upload>.
     * The file is uploaded to Salesforce as a ContentDocument/ContentVersion
     * and linked to the Contact record.
     * @param {Event} event The uploadfinished event containing details of uploaded files.
     */
    handleUploadFinished(event) {
        this.isLoading = true;
        const uploadedFiles = event.detail.files;

        // Check if an existing ContentDocument needs to be deleted (cleaning up previous attempts)
        if (this.updatedContentDocId) {
            this.deleteProfPic(); // Delete the previously staged file
        }

        if (uploadedFiles.length > 0) {
            // The file is uploaded, we just need to grab the ContentDocumentId 
            // of the newly created file.
            const newContentDocId = uploadedFiles[0].documentId;

            // Store the new ContentDocumentId so it can be associated with the Contact on Save
            this.updatedContentDocId = newContentDocId;
            this.uploadedFileName = uploadedFiles[0].name;

            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'New profile picture is ready to save.',
                    variant: 'success',
                }),
            );
        }

        // Hide the file uploader interface
        this.isEditingImage = false;
        this.isLoading = false;
    }

    /**
     * @description Calls an Apex method to delete the newly uploaded profile picture.
     * This is used during the cancel operation to clean up.
     */
    deleteProfPic() {
        this.isLoading = true;
        //delete the existing content doc using apex call
        deleteProfilePic({ contentDocId: this.updatedContentDocId}) 
            .then(response => {
                if(response === 'Success') { 
                    this.isLoading = false;
                }
                else {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error',
                            message: 'Your uploaded image has been not been deleted.',
                            variant: 'error',
                            mode: 'sticky'
                        })
                    );
                    this.isLoading = false;
                }
            })
            .catch(error => {
                console.error('Error in deletion of uploaded image:', error);
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'An unexpected error occurred while saving your information.',
                        variant: 'error',
                        mode: 'sticky'
                    })
                );
                this.isLoading = false;
            }
        );
    }
}