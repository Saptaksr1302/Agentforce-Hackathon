import { LightningElement, wire, track } from 'lwc';
import getRetailStores from '@salesforce/apex/PlanogramController.getRetailStores';
import getLocations from '@salesforce/apex/PlanogramController.getLocations';
import replaceOldFiles from '@salesforce/apex/PlanogramController.replaceOldFiles';

import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class PlanogramDashboard extends LightningElement {

    @track storeOptions = [];
    @track locationOptions = [];

    selectedStore;
    selectedLocation;

    acceptedFormats = ['.jpg', '.jpeg', '.png'];

    get isLocationDisabled() {
        return !this.selectedStore;
    }

    // Fetch Retail Stores
    @wire(getRetailStores)
    wiredStores({ data, error }) {
        if (data) {
            console.log(data);
            this.storeOptions = data.map(store => ({
                label: store.Name,
                value: store.Id
            }));
        }
        if(error){
            console.error(error);
        }
    }

    // Store Change
    handleStoreChange(event) {
        this.selectedStore = event.detail.value;
        this.selectedLocation = null;
        this.locationOptions = [];
        this.fetchLocations();
    }

    // Fetch In-Store Locations
    fetchLocations() {
        getLocations({ storeId: this.selectedStore })
            .then(result => {
                console.log(result);
                this.locationOptions = result.map(loc => ({
                    label: loc.Name,
                    value: loc.Id
                }));
            })
            .catch(error => {
                console.error(error);
            });
    }

    // Location Change
    handleLocationChange(event) {
        this.selectedLocation = event.detail.value;
    }

    // Upload Planogram File
    handleUploadFinished(event) {

        const uploadedFiles = event.detail.files;
        const newFileIds = uploadedFiles.map(file => file.documentId);

        replaceOldFiles({
            recordId: this.selectedLocation,
            newContentDocumentIds: newFileIds
        })
        .then((oldFilesDeleted) => {

            let message = 'Planogram uploaded successfully';

            if (oldFilesDeleted) {
                message += '. Attached old files removed';
            }

            this.showToast(
                'Success',
                message,
                'success'
            );

        })
        .catch(error => {
            console.log(error);
            this.showToast(
                'Error',
                'File uploaded but cleanup failed',
                'error'
            );
        });
    }

    // Toast helper
    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title,
                message,
                variant
            })
        );
    }
}