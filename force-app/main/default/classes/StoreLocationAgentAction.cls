// This class is used along with the LWC component to render a store location selector in the agent. It defines the input and output structures for the invocable method that processes the selected store location from the agent chat screen. Additionally, it includes a method to fetch all in-store locations with their associated retail store names for populating the selector. This class is not currently in use.

public class StoreLocationAgentAction {

    @JsonAccess(serializable='always' deserializable='always')
    public class FlowInput {
        @InvocableVariable(description='Selected store location details from the flow screen')
        public InStoreLocationDetails locationDetails;
    }
 
    public class InStoreLocationDetails{
 
        @InvocableVariable(label='Selected Store Location Name')
        public String locationName;
 
        @InvocableVariable(label='Selected Store Location Id')
        public String locationId;
    }
    @JsonAccess(serializable='always' deserializable='always')
    public class FlowOutput {
        @InvocableVariable(label='Message to display after processing the selected store location')
        public String message;
    }
 
    @InvocableMethod(label='Store Location Selector Action' description='Render store/location selector and return selected location Id')
    public static List<FlowOutput> invokeAction(List<FlowInput> inputs) {
        List<FlowOutput> outputs = new List<FlowOutput>();
        if(inputs != null && inputs.size() > 0) {
            FlowInput firstInput = inputs[0];
            InStoreLocationDetails locationDetails = firstInput.locationDetails;
            FlowOutput fo = new FlowOutput();
            fo.message = 'Successfully received input for In-Store Location';
            outputs.add(fo);
        }
        return outputs;
    }
    @AuraEnabled(cacheable=false)
    public static List<InStoreLocation> getStoresWithLocations() {
        List<InStoreLocation> locations = [
            SELECT Id, Name, RetailStoreId, RetailStore.Name
            FROM InStoreLocation
            WHERE RetailStoreId != null
        ];
        return locations;
    }
 
}