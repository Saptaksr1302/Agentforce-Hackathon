// This class handles the processing of uploaded planogram images for in-store locations. It listens for new ContentDocumentLink records, extracts the relevant ContentVersion details, creates Image records, and updates the associated InStoreLocation records with the new PlanogramId.

public class InStorePlanogramHandler {
    public static void handleFileUpload(List<ContentDocumentLink> newLinks) {
        if (newLinks == null || newLinks.isEmpty()) {
            return;
        }

        List<Image> imagesToInsert = new List<Image>();
        List<InStoreLocation> locationsToUpdate = new List<InStoreLocation>();

        for (ContentDocumentLink cdl : newLinks) {
            if (cdl.LinkedEntityId == null || cdl.ContentDocumentId == null) {
                continue;
            }

            Schema.SObjectType linkedType = cdl.LinkedEntityId.getSObjectType();
            if (linkedType != InStoreLocation.SObjectType) {
                continue; 
            }

            Id locationId = cdl.LinkedEntityId;
            Id documentId = cdl.ContentDocumentId;

            List<ContentVersion> versions = [
                SELECT Id, Title, FileExtension, FileType, ContentDocumentId,
                       ContentSize, PathOnClient
                FROM ContentVersion
                WHERE ContentDocumentId = :documentId
                AND IsLatest = true
                LIMIT 1
            ];

            if (versions.isEmpty()) {
                continue;
            }

            ContentVersion cv = versions[0];

            String cleanName = cv.Title != null
                ? cv.Title.replaceAll('[^a-zA-Z0-9\\s_-]', '').trim()
                : null;

            if (String.isBlank(cleanName)) {
                cleanName = 'Image_' + System.now().format('yyyyMMdd_HHmmss');
            }

            Image img = new Image();
            img.Name = cleanName.left(80);
            img.ContentDocumentId = cv.ContentDocumentId;
            img.IsActive = true;

            imagesToInsert.add(img);
        }

        if (!imagesToInsert.isEmpty()) {
            insert imagesToInsert;
            Integer idx = 0;
            for (ContentDocumentLink cdl : newLinks) {
                if (cdl.LinkedEntityId == null || cdl.ContentDocumentId == null) {
                    continue;
                }
                if (cdl.LinkedEntityId.getSObjectType() != InStoreLocation.SObjectType) {
                    continue;
                }
                if (idx >= imagesToInsert.size()) {
                    break;
                }

                locationsToUpdate.add(new InStoreLocation(
                    Id = cdl.LinkedEntityId,
                    PlanogramId = imagesToInsert[idx].Id
                ));
                idx++;
            }

            if (!locationsToUpdate.isEmpty()) {
                update locationsToUpdate;
            }
        }
    }
}