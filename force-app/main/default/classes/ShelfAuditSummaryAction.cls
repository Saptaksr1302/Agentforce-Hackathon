// This class is designed to parse the JSON response from the LLM for the shelf audit summary and return structured data that can be used in a Flow. It takes the raw JSON response as input, sanitizes it, and extracts key metrics such as total shelves, shelf share for ABC products, shelf share for competitors, and overall notes.

public class ShelfAuditSummaryAction {

    public class Request {
        @InvocableVariable(required=true)
        public String jsonResponse;
    }

    public class Response {
        @InvocableVariable
        public Integer totalShelves;

        @InvocableVariable
        public Decimal shelfShareABC;

        @InvocableVariable
        public Decimal shelfShareCompetitor;

        @InvocableVariable
        public String overallNotes;
    }

    @InvocableMethod(label='Parse Shelf Audit Summary'
                     description='Parses prompt response JSON and returns shelf audit summary for Flow')
    public static List<Response> parseSummary(List<Request> requests) {
        List<Response> results = new List<Response>();

        for (Request req : requests) {
            Map<String, Object> data = parseJson(req.jsonResponse);

            Response res = new Response();
            res.totalShelves = toInteger(data.get('totalShelves'));
            res.shelfShareABC = toDecimal(data.get('ShelfShareABC'));
            res.shelfShareCompetitor = toDecimal(data.get('ShelfShareCompetitor'));
            res.overallNotes = (String) data.get('overallNotes');

            results.add(res);
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

    private static Decimal toDecimal(Object value) {
        if (value == null) return null;
        if (value instanceof Decimal) return (Decimal) value;
        return Decimal.valueOf(String.valueOf(value));
    }
}