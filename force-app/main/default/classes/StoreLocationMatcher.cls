// This class provides an Invocable method to match a store and location based on user input. It takes two string inputs (which can be in any order) and attempts to find a matching RetailStore and InStoreLocation. The matching logic includes normalization of input, partial and exact matching.

public class StoreLocationMatcher {

    public class Input {
        @InvocableVariable(required=true)
        public String inputOne;

        @InvocableVariable(required=true)
        public String inputTwo;
    }

    public class Output {
        @InvocableVariable
        public Id storeId;

        @InvocableVariable
        public Id locationId;

        @InvocableVariable
        public String status;

        @InvocableVariable
        public String message;
    }

    @InvocableMethod
    public static List<Output> matchStoreLocation(List<Input> inputs) {
        List<Output> results = new List<Output>();

        for (Input inp : inputs) {
            Output out = new Output();

            try {
                // inputOne as Store and inputTwo as Location
                MatchResult firstTry = tryMatch(inp.inputOne, inp.inputTwo);

                // inputTwo as Store and inputOne as Location
                MatchResult secondTry = tryMatch(inp.inputTwo, inp.inputOne);

                MatchResult finalResult;

                if (firstTry.success) {
                    finalResult = firstTry;
                } else if (secondTry.success) {
                    finalResult = secondTry;
                } else {
                    finalResult = handleBetterFailure(firstTry, secondTry);
                }

                if (finalResult.success) {
                    out.storeId = finalResult.storeId;
                    out.locationId = finalResult.locationId;
                    out.status = 'SUCCESS';
                    out.message = 'Store and location successfully matched';
                } else {
                    out.status = 'ERROR';
                    out.message = finalResult.message;
                }

            } catch (Exception e) {
                out.status = 'ERROR';
                out.message = e.getMessage();
            }

            results.add(out);
        }

        return results;
    }

    // Helper class
    private class MatchResult {
        public Boolean success = false;
        public Id storeId;
        public Id locationId;
        public String message;
        public Integer score = 0; // Used to decide better failure message
    }

    // Core matching logic
    private static MatchResult tryMatch(String storeInput, String locationInput) {
        MatchResult res = new MatchResult();

        String normalizedStoreInput = normalize(storeInput);
        String normalizedLocationInput = normalize(locationInput);

        if (String.isBlank(normalizedStoreInput) || String.isBlank(normalizedLocationInput)) {
            res.success = false;
            res.message = 'Both inputs are required.';
            res.score = 0;
            return res;
        }

        List<RetailStore> candidateStores = [
            SELECT Id, Name
            FROM RetailStore
            WHERE Name LIKE :('%' + storeInput.trim() + '%')
            OR Name LIKE :('%' + storeInput.replace('-', ' ').trim() + '%')
            OR Name LIKE :('%' + storeInput.replace(' ', '%') + '%')
        ];

        // If no candidates found from SOQL, try fetching broader store set if needed
        if (candidateStores.isEmpty()) {
            res.success = false;
            res.message = 'No store found matching "' + storeInput + '"';
            res.score = 1;
            return res;
        }

        List<RetailStore> exactStoreMatches = new List<RetailStore>();
        List<RetailStore> partialStoreMatches = new List<RetailStore>();

        for (RetailStore storeRec : candidateStores) {
            String normalizedStoreName = normalize(storeRec.Name);

            if (normalizedStoreName == normalizedStoreInput) {
                exactStoreMatches.add(storeRec);
            } else if (
                normalizedStoreName.contains(normalizedStoreInput) ||
                normalizedStoreInput.contains(normalizedStoreName)
            ) {
                partialStoreMatches.add(storeRec);
            }
        }

        List<RetailStore> matchedStores;
        if (!exactStoreMatches.isEmpty()) {
            matchedStores = exactStoreMatches;
        } else {
            matchedStores = partialStoreMatches;
        }

        if (matchedStores.isEmpty()) {
            res.success = false;
            res.message = 'No store found matching "' + storeInput + '"';
            res.score = 1;
            return res;
        }

        if (matchedStores.size() > 1) {
            res.success = false;
            res.message =
                'Multiple stores found: ' +
                String.join(getStoreNames(matchedStores), ', ') +
                '. Please provide the full exact store name.';
            res.score = 2;
            return res;
        }

        RetailStore matchedStore = matchedStores[0];

        //Get all locations under matched store
        List<InStoreLocation> allLocations = [
            SELECT Id, Name, RetailStoreId
            FROM InStoreLocation
            WHERE RetailStoreId = :matchedStore.Id
        ];

        if (allLocations.isEmpty()) {
            res.success = false;
            res.message = 'No in-store locations are linked to store "' + matchedStore.Name + '".';
            res.score = 3;
            return res;
        }

        List<InStoreLocation> exactLocationMatches = new List<InStoreLocation>();
        List<InStoreLocation> partialLocationMatches = new List<InStoreLocation>();

        for (InStoreLocation loc : allLocations) {
            String normalizedLocName = normalize(loc.Name);

            if (normalizedLocName == normalizedLocationInput) {
                exactLocationMatches.add(loc);
            } else if (
                normalizedLocName.contains(normalizedLocationInput) ||
                normalizedLocationInput.contains(normalizedLocName)
            ) {
                partialLocationMatches.add(loc);
            }
        }

        List<InStoreLocation> matchedLocations;
        if (!exactLocationMatches.isEmpty()) {
            matchedLocations = exactLocationMatches;
        } else {
            matchedLocations = partialLocationMatches;
        }

        if (matchedLocations.isEmpty()) {
            res.success = false;
            res.message =
                'No location found in store "' + matchedStore.Name +
                '" matching "' + locationInput + '"';
            res.score = 4;
            return res;
        }

        if (matchedLocations.size() > 1) {
            res.success = false;
            res.message =
                'Multiple locations found in store "' + matchedStore.Name + '": ' +
                String.join(getLocationNames(matchedLocations), ', ') +
                '. Please provide the full exact location name.';
            res.score = 5;
            return res;
        }
        
        // SUCCESS
        res.success = true;
        res.storeId = matchedStore.Id;
        res.locationId = matchedLocations[0].Id;
        res.message = 'Match found';
        res.score = 100;

        return res;
    }

    // Normalize text
    private static String normalize(String input) {
        if (String.isBlank(input)) {
            return '';
        }

        String s = input.toLowerCase().trim();

        // Replace special spaces with regular spaces
        s = s.replace('\u00A0', ' ');
        s = s.replace('\u2007', ' ');
        s = s.replace('\u202F', ' ');

        // Replace punctuation / separators with spaces
        s = s.replace('-', ' ');
        s = s.replace('_', ' ');
        s = s.replace('.', ' ');
        s = s.replace(',', ' ');
        s = s.replace(';', ' ');
        s = s.replace(':', ' ');
        s = s.replace('/', ' ');
        s = s.replace('\\', ' ');
        s = s.replace('(', ' ');
        s = s.replace(')', ' ');
        s = s.replace('[', ' ');
        s = s.replace(']', ' ');
        s = s.replace('{', ' ');
        s = s.replace('}', ' ');
        s = s.replace('|', ' ');
        s = s.replace('&', ' ');
        s = s.replace('!', ' ');
        s = s.replace('?', ' ');
        s = s.replace('"', ' ');
        s = s.replace('\'', ' ');

        // Collapse multiple spaces
        while (s.contains('  ')) {
            s = s.replace('  ', ' ');
        }

        return s.trim();
    }

    // Handle Failure cases
    private static MatchResult handleBetterFailure(MatchResult firstTry, MatchResult secondTry) {
        if (firstTry == null) return secondTry;
        if (secondTry == null) return firstTry;

        if (firstTry.score >= secondTry.score) {
            return firstTry;
        }
        return secondTry;
    }

    // Name helpers
    private static List<String> getStoreNames(List<RetailStore> stores) {
        List<String> names = new List<String>();
        for (RetailStore s : stores) {
            names.add(s.Name);
        }
        return names;
    }

    private static List<String> getLocationNames(List<InStoreLocation> locations) {
        List<String> names = new List<String>();
        for (InStoreLocation loc : locations) {
            names.add(loc.Name);
        }
        return names;
    }
}