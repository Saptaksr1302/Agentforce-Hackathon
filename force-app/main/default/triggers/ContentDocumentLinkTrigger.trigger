trigger ContentDocumentLinkTrigger on ContentDocumentLink (after insert) {
    InStorePlanogramHandler.handleFileUpload(Trigger.new);
}