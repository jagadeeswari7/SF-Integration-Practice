// Apex Controller
public with sharing class RecordAccessController {
    
    @AuraEnabled
    public static RecordAccessResponse checkRecordAccess(Id recordId) {
        try {
            // Get current user's permissions
            Boolean hasHighNetWorthPermission = FeatureManagement.checkPermission('High_Net_Worth_Client_Service_Representative');
            
            // Check if user has access to the record
            List<UserRecordAccess> accessCheck = [
                SELECT RecordId, HasReadAccess, HasEditAccess 
                FROM UserRecordAccess 
                WHERE UserId = :UserInfo.getUserId() 
                AND RecordId = :recordId
                LIMIT 1
            ];
            
            if (accessCheck.isEmpty() || !accessCheck[0].HasReadAccess) {
                return new RecordAccessResponse(
                    false,
                    false,
                    'Insufficient privileges to open the page; please contact the administrator.',
                    false
                );
            }
            
            // Check if this is a High Net Worth Client
            Boolean isHighNetWorthClient = false;
            if (recordId.getSObjectType() == Account.SObjectType) {
                isHighNetWorthClient = isHighNetWorthAccount(recordId);
            }
            
            Boolean canEdit = determineEditAccess(
                accessCheck[0].HasEditAccess,
                hasHighNetWorthPermission,
                isHighNetWorthClient
            );
            
            return new RecordAccessResponse(
                true,
                canEdit,
                null,
                isHighNetWorthClient
            );
            
        } catch (Exception e) {
            return new RecordAccessResponse(
                false,
                false,
                'Error: ' + e.getMessage(),
                false
            );
        }
    }
    
    private static Boolean isHighNetWorthAccount(Id accountId) {
        AggregateResult result = [
            SELECT SUM(Amount) totalAmount 
            FROM Opportunity 
            WHERE AccountId = :accountId 
            AND IsClosed = false
            GROUP BY AccountId
            LIMIT 1
        ];
        
        if (result == null) return false;
        
        Decimal totalAmount = (Decimal)result.get('totalAmount');
        return totalAmount != null && totalAmount >= 1000000;
    }
    
    private static Boolean determineEditAccess(
        Boolean hasEditAccess,
        Boolean hasHighNetWorthPermission,
        Boolean isHighNetWorthClient
    ) {
        if (isHighNetWorthClient) {
            return hasHighNetWorthPermission;
        }
        return hasEditAccess;
    }
    
    public class RecordAccessResponse {
        @AuraEnabled public Boolean hasAccess { get; set; }
        @AuraEnabled public Boolean canEdit { get; set; }
        @AuraEnabled public String errorMessage { get; set; }
        @AuraEnabled public Boolean isHighNetWorthClient { get; set; }
        
        public RecordAccessResponse(
            Boolean hasAccess,
            Boolean canEdit,
            String errorMessage,
            Boolean isHighNetWorthClient
        ) {
            this.hasAccess = hasAccess;
            this.canEdit = canEdit;
            this.errorMessage = errorMessage;
            this.isHighNetWorthClient = isHighNetWorthClient;
        }
    }
}
