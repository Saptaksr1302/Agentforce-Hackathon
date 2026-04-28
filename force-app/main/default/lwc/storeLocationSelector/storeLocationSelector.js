import { LightningElement, track, api } from 'lwc';
import getStoresWithLocations from '@salesforce/apex/StoreLocationAgentAction.getStoresWithLocations';
 
export default class StoreLocationSelector extends LightningElement {
    // Accept stores from parent/CLT when rendered by Agentforce
    @api
    get readOnly(){
        return this._readOnly;
    }
    set readOnly(value){
        this._readOnly = value;
    }
    _readOnly = false;
    _value;
 
    @track locationId;
    @track locationName;
    @track locationdata = [];
    @track showlocationdata = false;
    @track isSelected;
 
    @api
    get value() {
        return this._value;
    }
 
    set value(value) {
        this._value = value;
    }

    get acceptedFormat(){
        return ['.jpeg', '.jpg', '.png'];
    }
 
    connectedCallback() {
        if(this.value){
            this.locationId = this.value?.locationId || '';
            this.locationName = this.value?.locationName || '';
        }
 
        if (this.locationdata.length < 1){
            this.fetchStoreLocationData();
        }
    }
 
    fetchStoreLocationData(){
        getStoresWithLocations().then(result => {
            console.log('Store Location Data:', JSON.stringify(result));
            if(result){
                result.forEach(tempLoc => {
                    let loc = {};
                    Object.assign(loc, tempLoc);
                    loc.isSelected = false;
                    this.locationdata.push(loc);
                })
                if (this.locationdata.length > 0){
                    this.showlocationdata = true;
                }
            }
        }).catch(error => {
            console.error('Error fetching store location data:', error);
        });
    }
 
     handleSelect(event){
            event.stopPropagation();
            this.locationId = event.target.value;
            this.locationdata = this.locationdata.map(loc => {
                if(loc.Id === this.locationId){
                    loc.isSelected = true;
                    this.locationName = loc.Name;
                } else {
                    loc.isSelected = false;
                }
 
                return loc;
            });
 
            const {name, value} = event.target;
            this[name] = value;
            this.newEvent = new CustomEvent("valuechange", {
                detail: {  
                    value:{
                        locationId: this.locationId,
                        locationName: this.locationName
                    }
                }
            });
            this.dispatchEvent(this.newEvent);
        }
}