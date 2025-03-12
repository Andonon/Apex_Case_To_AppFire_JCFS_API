/*
*********************************************************
Apex Class Name    : Case_Escalation_AppFire_API_Mock
Created Date       : March 11, 2025
@description       : Mock Class for Case_Escalation_AppFire_API_Tests
@author            : Troy Center, MCG Health
Modification Log:
Ver   Date         Author                   Case            Modification    
1.0   06/28/2024   troy.center@mcg.com      00391891        Initial Version
*********************************************************
*/
public with sharing class Case_Escalation_AppFire_API_Mock implements HttpCalloutMock {
    public HTTPResponse respond(HTTPRequest req) {
        HttpResponse response = new HttpResponse();
        response.setStatusCode(200);
        return response;
    }
}