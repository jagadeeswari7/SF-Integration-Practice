public with sharing class HighNetWorthClientController {
    @TestVisible
    private static final Decimal HIGH_NET_WORTH_THRESHOLD = 1000000;

    /**
     * @description Determines if the given account qualifies as a High Net Worth Client
     * based on the sum of the amounts from all non-closed opportunities.
     * 
     * @param accountId The ID of the account to check.
     * @return Boolean True if the total amount of non-closed opportunities 
     *                 for the account meets or exceeds the high net worth threshold, otherwise false.
     */
    private static Boolean isHighNetWorthClient(Id accountId) {
        // Aggregate query to calculate the sum of non-closed opportunities
        AggregateResult result = [
            SELECT SUM(Amount) totalAmount
            FROM Opportunity 
            WHERE AccountId = :accountId AND IsClosed = false
            WITH USER_MODE
        ];

        // Return true if the total amount exceeds the threshold, false otherwise
        if (result != null && result.get('totalAmount') != null) {
            Decimal totalAmount = (Decimal) result.get('totalAmount');
            return totalAmount >= HIGH_NET_WORTH_THRESHOLD;
        }
        return false;
    }

    /**
     * @description Determines the record access and display mode for a given record.
     * 
     * @param recordId The ID of the record to check.
     * @return Map<String, Object> A map containing access data with keys:
     *         - 'hasRecordAccess': Boolean indicating if the user has access to the record.
     *         - 'message': A message indicating the reason for access or error.
     *         - 'mode': The display mode (edit, readonly, view).
     */
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> determineRecordAccess(Id recordId) {
        Map<String, Object> accessData = new Map<String, Object>();

        try {
            // Query to check if the current user has access to the record
            UserRecordAccess access = [
                SELECT RecordId, HasReadAccess, HasEditAccess
                FROM UserRecordAccess 
                WHERE UserId = :UserInfo.getUserId() 
                AND RecordId = :recordId 
                WITH USER_MODE
                LIMIT 1
            ];

            // If no read access, return insufficient access message
            if (!access.HasReadAccess) {
                accessData.put('hasRecordAccess', false);
                accessData.put('message', 'Insufficient privileges to open the page; please contact the administrator.');
                return accessData;
            }

            // Check High Net Worth Client permission and if the account qualifies
            Boolean hasHighNetWorthPermission = FeatureManagement.checkPermission('hasHighNetWorthClientPermission');
            Boolean isHighNetWorthAccount = false;

            // Check if the record is of type Account
            if (recordId.getSObjectType() == Account.SObjectType) {
                isHighNetWorthAccount = isHighNetWorthClient(recordId);
            }

            // Set access data
            accessData.put('hasRecordAccess', true);
            accessData.put('mode', determineDisplayMode(access.HasEditAccess, hasHighNetWorthPermission, isHighNetWorthAccount));
        } catch (Exception e) {
            // Handle errors, log the exception and return a failure response
            accessData.put('hasRecordAccess', false);
            accessData.put('message', 'Error determining access: ' + e.getMessage());
        }

        return accessData;
    }

    /**
     * @description Determines the appropriate display mode based on user access and permissions.
     * 
     * @param hasEditAccess Boolean indicating if the user has edit access.
     * @param hasHighNetWorthPermission Boolean indicating if the user has the High Net Worth Client permission.
     * @param isHighNetWorthAccount Boolean indicating if the account qualifies as High Net Worth.
     * @return String The display mode ('edit', 'readonly', or 'view').
     */
    private static String determineDisplayMode(Boolean hasEditAccess, Boolean hasHighNetWorthPermission, Boolean isHighNetWorthAccount) {
        // If it's a High Net Worth account, display edit or readonly based on permission
        if (isHighNetWorthAccount) {
            return hasHighNetWorthPermission ? 'edit' : 'readonly';
        }
        // For other accounts, allow edit or view depending on the user's access level
        return hasEditAccess ? 'edit' : 'view';
    }
}
