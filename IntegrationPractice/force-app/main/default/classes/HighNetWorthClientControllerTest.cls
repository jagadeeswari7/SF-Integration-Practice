@IsTest
public class HighNetWorthClientControllerTest {
    private static User testUser;
    @TestSetup
    static void setupTestData() {
        Profile profile = [SELECT Id FROM Profile WHERE Name='Standard User'];
        User user = new User(Alias = 'TestUser', Email='testuser99@example.com', 
            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = profile.Id, 
            TimeZoneSidKey='America/Los_Angeles', UserName= System.now().milliSecond()+'testuser99@example.com');
        insert user;
        // Mock a PermissionSet with the custom permission
        PermissionSet customPermissionSet = new PermissionSet(
            Name = 'My_Custom_Permission',
            Label = 'My Custom Permission'
        );
        insert customPermissionSet;
        SetupEntityAccess setupEntityAccess = new SetupEntityAccess(
            ParentId = customPermissionSet.Id,
            SetupEntityId = [SELECT Id FROM CustomPermission WHERE DeveloperName = 'hasHighNetWorthClientPermission'][0].Id
        );
        insert setupEntityAccess;
        System.runAs(user) {
            // Create a test Account
            Account testAccount = new Account(Name = 'Test Account');
            insert testAccount;

            // Create non-closed Opportunities for the test Account
            List<Opportunity> opportunities = new List<Opportunity>{
                new Opportunity(Name = 'Opportunity 1', AccountId = testAccount.Id, Amount = 500000, StageName = 'Prospecting', CloseDate = Date.today().addMonths(1)),
                new Opportunity(Name = 'Opportunity 2', AccountId = testAccount.Id, Amount = 600000, StageName = 'Qualification', CloseDate = Date.today().addMonths(1))
            };
            insert opportunities;

            // Create a closed Opportunity (should be ignored in calculation)
            Opportunity closedOpportunity = new Opportunity(Name = 'Closed Opportunity', AccountId = testAccount.Id, Amount = 300000, StageName = 'Closed Won', CloseDate = Date.today().addMonths(-1));
            insert closedOpportunity;
        }
    }

    @IsTest
    static void testDetermineRecordAccessWithHighNetWorth() {
        Test.startTest();
        testUser = [SELECT Id from User WHERE LastName = 'Testing' LIMIT 1];
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        PermissionSet permissionSet = [SELECT Id from PermissionSet WHERE Name = 'My_Custom_Permission' LIMIT 1];
        PermissionSetAssignment psa = new PermissionSetAssignment(
                AssigneeId = testUser.Id,
                PermissionSetId = permissionSet.Id
            );
        insert psa;
        System.runAs(testUser) {
            // Assign the Permission Set with the custom permission to the User
            Map<String, Object> accessData = HighNetWorthClientController.determineRecordAccess(testAccount.Id);

            // Verify the access data results
            System.assertEquals(true, accessData.get('hasRecordAccess'), 'User should have record access.');
            System.assertEquals('edit', accessData.get('mode'), 'User should have edit access for a high net worth account with permission.');
            System.assert(accessData.containsKey('message') == false, 'There should be no error message.');
        }
        Test.stopTest();
    }

    @IsTest
    static void testDetermineRecordAccessWithoutHighNetWorthPermission() {
        Test.startTest();
        testUser = [SELECT Id from User WHERE LastName = 'Testing' LIMIT 1];
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
        System.runAs(testUser) {
            Map<String, Object> accessData = HighNetWorthClientController.determineRecordAccess(testAccount.Id);

            // Verify the access data results
            System.assertEquals(true, accessData.get('hasRecordAccess'), 'User should have record access.');
            System.assertEquals('readonly', accessData.get('mode'), 'User should have readonly access for a high net worth account without permission.');
            System.assert(accessData.containsKey('message') == false, 'There should be no error message.');
        }
        Test.stopTest();
    }

    @IsTest
    static void testDetermineRecordAccessWithoutHighNetWorthPermissionForNormalRecords() {
        Test.startTest();
        testUser = [SELECT Id from User WHERE LastName = 'Testing' LIMIT 1];
        System.runAs(testUser) {
            Account testAccount = new Account(Name = 'Non High Net Worth Account');
            insert testAccount;
            Map<String, Object> accessData = HighNetWorthClientController.determineRecordAccess(testAccount.Id);

            // Verify the access data results
            System.assertEquals(true, accessData.get('hasRecordAccess'), 'User should have record access.');
            System.assertEquals('edit', accessData.get('mode'), 'User should have readonly access for a high net worth account without permission.');
            System.assert(accessData.containsKey('message') == false, 'There should be no error message.');
        }
        Test.stopTest();
    }

    @IsTest
    static void testDetermineRecordAccessInsufficientPrivileges() {
        Test.startTest();
        testUser = [SELECT Id from User WHERE LastName = 'Testing' LIMIT 1];
        Account nonAccessibleAccount = new Account(Name = 'Non-Accessible Account');
        insert nonAccessibleAccount;
        System.runAs(testUser) {
            Map<String, Object> accessData = HighNetWorthClientController.determineRecordAccess(nonAccessibleAccount.Id);
            // Verify that access is denied with an appropriate message
            System.assertEquals(false, accessData.get('hasRecordAccess'), 'User should not have record access.');
            System.assertEquals('Insufficient privileges to open the page; please contact the administrator.', accessData.get('message'), 'User should not have privileges.');
        }
        Test.stopTest();
    }
}
