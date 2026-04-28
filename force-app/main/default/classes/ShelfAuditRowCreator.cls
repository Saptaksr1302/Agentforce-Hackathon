// This class is responsible for creating Shelf_Number_Audit__c records based on the JSON response from the LLM. It takes the JSON input, parses it, and creates child records linked to the parent Shelf_Audit__c record for the number of shelves and product counts as specified in the JSON.

public class ShelfAuditRowCreator {

    public class Request {
        @InvocableVariable(required=true)
        public String jsonResponse;

        @InvocableVariable(required=true)
        public Id shelfAuditId;
    }

    public class Result {
        @InvocableVariable
        public Integer recordsCreated;

        @InvocableVariable
        public String message;
    }

    @InvocableMethod(
        label='Create Shelf Number Audit Records'
        description='Parses shelf audit JSON and creates Shelf_Number_Audit__c records linked to Shelf_Audit__c'
    )
    public static List<Result> createShelfNumberAuditRecords(List<Request> requests) {
        List<Result> results = new List<Result>();

        List<Shelf_Number_Audit__c> recordsToInsert = new List<Shelf_Number_Audit__c>();
        Integer totalCreated = 0;

        for (Request req : requests) {
            if (req == null) {
                continue;
            }

            if (req.shelfAuditId == null) {
                throw new AuraHandledException('Shelf Audit Id is required.');
            }

            Map<String, Object> data = parseJson(req.jsonResponse);
            List<Object> shelves = (List<Object>) data.get('shelves');

            if (shelves == null) {
                Result noDataResult = new Result();
                noDataResult.recordsCreated = 0;
                noDataResult.message = 'No shelves found in JSON.';
                results.add(noDataResult);
                continue;
            }

            Integer createdForThisRequest = 0;

            for (Object shelfObj : shelves) {
                Map<String, Object> shelfMap = (Map<String, Object>) shelfObj;

                Shelf_Number_Audit__c childRecord = new Shelf_Number_Audit__c();
                childRecord.Shelf_Audit__c = req.shelfAuditId;
                childRecord.Shelf_Number__c = toInteger(shelfMap.get('shelfNumber'));
                childRecord.Total_Product_Count__c = toInteger(shelfMap.get('totalProductCount'));
                childRecord.ABC_Product_Count__c = toInteger(shelfMap.get('ABCProduct'));
                childRecord.Competitor_Product_Count__c = toInteger(shelfMap.get('CompetitorProduct'));

                recordsToInsert.add(childRecord);
                createdForThisRequest++;
            }

            totalCreated += createdForThisRequest;

            Result res = new Result();
            res.recordsCreated = createdForThisRequest;
            res.message = createdForThisRequest + ' Shelf_Number_Audit__c record(s) prepared for insert.';
            results.add(res);
        }

        if (!recordsToInsert.isEmpty()) {
            insert recordsToInsert;
        }

        return results;
    }

    private static Map<String, Object> parseJson(String rawJson) {
        String cleanJson = sanitizeJson(rawJson);
        return (Map<String, Object>) JSON.deserializeUntyped(cleanJson);
    }

    private static String sanitizeJson(String input) {
        if (String.isBlank(input)) {
            throw new AuraHandledException('JSON input is blank.');
        }

        String cleaned = input.trim();
        cleaned = cleaned.replace('```json', '');
        cleaned = cleaned.replace('```', '');
        cleaned = cleaned.trim();

        Integer startIdx = cleaned.indexOf('{');
        Integer endIdx = cleaned.lastIndexOf('}');

        if (startIdx == -1 || endIdx == -1 || endIdx <= startIdx) {
            throw new AuraHandledException('Invalid JSON input.');
        }

        return cleaned.substring(startIdx, endIdx + 1);
    }

    private static Integer toInteger(Object value) {
        if (value == null) return null;
        if (value instanceof Integer) return (Integer) value;
        if (value instanceof Long) return Integer.valueOf(String.valueOf(value));
        if (value instanceof Decimal) return ((Decimal) value).intValue();
        return Integer.valueOf(String.valueOf(value));
    }
}