/*
*********************************************************
Apex Class Name    : Case_Escalation_AppFire_API_Tests
Created Date       : March 11, 2025
@description       : Test Class for Case_Escalation_AppFire_API
@author            : Troy Center, MCG Health
Modification Log:
Ver   Date         Author                   Case            Modification    
1.0   06/28/2024   troy.center@mcg.com      00391891        Initial Version
*********************************************************
*/
@istest
private class Case_Escalation_AppFire_API_Tests {
    @isTest 
    private static void caseAfterInsertTest() {
        Test.setMock(HttpCalloutMock.class, new Case_Escalation_AppFire_API_Mock());
        Case c = new Case();
        Test.startTest();
        insert c;
        Test.stopTest();
    }
    @isTest 
    private static void caseAfterUpdateTest() {
        Test.setMock(HttpCalloutMock.class, new Case_Escalation_AppFire_API_Mock());
        Case c = new Case();
        insert c;
        Test.startTest();
        update c;
        Test.stopTest();
    }

    @isTest  
    private static void test_MCG_TSS_Case_1(){
        Account newAccount = new Account(); 
        newAccount.Name = 'Test Account'; 
        insert newAccount; 

        Contact newContact = new Contact(); 
        newContact.FirstName = 'Testy'; 
        newContact.LastName = 'Testerson'; 
        newContact.AccountId = newAccount.Id; 
        insert newContact; 

        Id idTSSRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Technical_Support').getRecordTypeId();

        Case newCase = new Case(); 
        newCase.ContactId = newContact.Id; 
        newCase.AccountId = newAccount.Id; 
        newCase.Subject = 'Test Case'; 
        newCase.Product__c = 'CareWebQI'; 
        newCase.RecordTypeId = idTSSRecordTypeId; 
        newCase.Status = 'New'; 
        insert newCase; 

        Case caseToUpdateBEFORE = [SELECT Id, Escalate_to_SEAD__c FROM Case WHERE Id = :newCase.Id];
        caseToUpdateBEFORE.Escalate_to_SEAD__c = true; 

        Test.startTest(); 
        update caseToUpdateBEFORE; 
        Test.stopTest(); 

        Case caseToUpdateAFTER = [SELECT Id, Escalate_to_SEAD__c FROM Case WHERE Id = :newCase.Id];
        System.assertEquals(true, caseToUpdateAFTER.Escalate_to_SEAD__c, 'Actual ::: '+caseToUpdateAFTER.Escalate_to_SEAD__c);
    }
}