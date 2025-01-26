public class RecordAccessResponse {
    @AuraEnabled public Boolean hasAccess { get; set; }
    @AuraEnabled public Boolean canEdit { get; set; }
    @AuraEnabled public Boolean isHighNetWorthClient { get; set; }
    
    public RecordAccessResponse(Boolean hasAccess, Boolean canEdit, Boolean isHighNetWorthClient) {
        this.hasAccess = hasAccess;
        this.canEdit = canEdit;
        this.isHighNetWorthClient = isHighNetWorthClient;
    }
}