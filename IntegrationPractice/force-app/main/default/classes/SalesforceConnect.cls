public with sharing class SalesforceConnect {
    public static String getCasesFromOtherSalesforceOrg(String caseId) {
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setMethod('GET');
        request.setEndpoint('callout:SFDC_OrgB/services/apexrest/Cases/'+caseId);
        HttpResponse response = http.send(request);

        if(response.getStatusCode() == 200) {
            System.debug('response::'+response.getBody());
            return response.getBody();
        }
        return null;
    }
}