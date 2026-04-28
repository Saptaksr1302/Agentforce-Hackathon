public class PlanogramController {

    //Fetching retail stores for dropdown
    @AuraEnabled(cacheable=true)
    public static List<RetailStore> getRetailStores() {
        return [SELECT Id, Name FROM RetailStore ORDER BY Name];
    }

    //Fetching in-store locations based on selected retail store
    @AuraEnabled(cacheable=true)
    public static List<InStoreLocation> getLocations(Id storeId) {
        return [
            SELECT Id, Name 
            FROM InStoreLocation 
            WHERE RetailStoreId = :storeId
            ORDER BY Name
        ];
    }

    //Method to replace old files with new ones and delete the old content document and related image records
    @AuraEnabled
    public static Boolean replaceOldFiles(Id recordId, List<Id> newContentDocumentIds) {

        Boolean oldFilesDeleted = false;

        List<ContentDocumentLink> links = [
            SELECT Id, ContentDocumentId
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :recordId
        ];

        List<ContentDocumentLink> linksToDelete = new List<ContentDocumentLink>();
        Set<Id> oldDocIds = new Set<Id>();

        for (ContentDocumentLink link : links) {
            if (!newContentDocumentIds.contains(link.ContentDocumentId)) {
                linksToDelete.add(link);
                oldDocIds.add(link.ContentDocumentId);
            }
        }

        // Delete Image records related to old ContentDocument
        if (!oldDocIds.isEmpty()) {
            List<Image> imagesToDelete = [
                SELECT Id 
                FROM Image 
                WHERE ContentDocumentId IN :oldDocIds
            ];

            if (!imagesToDelete.isEmpty()) {
                Database.delete(imagesToDelete, false);
            }

            //Delete the old contentdocument record
            List<ContentDocument> contentDocumentsToDelete = [
                SELECT Id 
                FROM ContentDocument 
                WHERE Id IN :oldDocIds
            ];
            if (!contentDocumentsToDelete.isEmpty()) {
                Database.delete(contentDocumentsToDelete, false);
            }
        }

        // Delete content document links
        if (!linksToDelete.isEmpty()) {
            Database.delete(linksToDelete, false);
            oldFilesDeleted = true;
        }

        return oldFilesDeleted;
    }

}