// This apex class is not used anymore in the challenge

public class ShelfAuditRowsAction {

    public class Request {
        @InvocableVariable(required=true)
        public String jsonResponse;
    }

    public class ShelfRow {
        @InvocableVariable
        public Integer shelfNumber;

        @InvocableVariable
        public Integer totalProductCount;

        @InvocableVariable
        public Integer abcProduct;

        @InvocableVariable
        public Integer competitorProduct;
    }

    @InvocableMethod(
        label='Parse Shelf Audit Rows'
        description='Parses shelf audit JSON and returns one row per shelf'
    )
    public static List<ShelfRow> parseShelves(List<Request> requests) {
        List<ShelfRow> results = new List<ShelfRow>();

        for (Request req : requests) {
            Map<String, Object> data = parseJson(req.jsonResponse);
            List<Object> shelves = (List<Object>) data.get('shelves');

            if (shelves == null) continue;

            for (Object shelfObj : shelves) {
                Map<String, Object> shelfMap = (Map<String, Object>) shelfObj;

                ShelfRow row = new ShelfRow();
                row.shelfNumber = toInteger(shelfMap.get('shelfNumber'));
                row.totalProductCount = toInteger(shelfMap.get('totalProductCount'));
                row.abcProduct = toInteger(shelfMap.get('ABCProduct'));
                row.competitorProduct = toInteger(shelfMap.get('CompetitorProduct'));

                results.add(row);
            }
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

        String cleaned = input.trim()
            .replace('```json', '')
            .replace('```', '');

        Integer startIdx = cleaned.indexOf('{');
        Integer endIdx = cleaned.lastIndexOf('}');

        if (startIdx == -1 || endIdx <= startIdx) {
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