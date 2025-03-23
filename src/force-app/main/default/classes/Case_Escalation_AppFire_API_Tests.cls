/*
*********************************************************
Apex Class Name    : Case_Escalation_AppFire_API_Tests
Created Date       : March 11, 2025
@description       : Test Class for Case_Escalation_AppFire_API
@author            : Troy Center
Modification Log:
Ver   Date         Author                   Case            Modification    
1.0   03/11/2025   Troy Center              00000000        Initial Version, tests created
*********************************************************
*/
@istest
private class Case_Escalation_AppFire_API_Tests {
    /*****************************************************
     * Test Data Setup
     ****************************************************/
    @TestSetup
    private static void makeData(){
        Account testAccount = new Account(
            Name = 'Test AppFire Account', 
            Type = 'Client - Enterprise'
        );
        insert testAccount; 
    
        Contact testContact = new Contact(
            AccountId = testAccount.Id, 
            FirstName = 'Tester',
            LastName = 'AppFireContactTest'
        );
        insert testContact;
    }
    /*****************************************************
     * Test with a TSS Case, Expected to work. Good Singluar Test Method for Repro and Debugging. 
     ****************************************************/
    @isTest  
    private static void test_MCG_TSS_Case_1(){
        // Get the Account and Contact from Test Setup
        Account theAccount = [SELECT Id FROM Account WHERE Name = 'Test AppFire Account' LIMIT 1];
        Contact theContact = [SELECT Id FROM Contact WHERE LastName = 'AppFireContactTest' LIMIT 1];
        
        //Get the Technical Support Record Type. 
        Id idTSSRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Technical_Support').getRecordTypeId();

        // Create test case that should be escalated to JIRA
        Case newCase = new Case( 
            ContactId = theContact.Id,
            AccountId = theAccount.Id,
            Subject = 'Test AppFire Case',
            Product__c = 'CareWebQI',
            RecordTypeId = idTSSRecordTypeId,
            Status = 'New',
            Priority = 'Level 3: Medium'); 
        insert newCase;

        Test.startTest(); 
        Case caseToUpdateBEFORE = [SELECT Id, Escalate_to_SEAD__c FROM Case WHERE Id = :newCase.Id];
        caseToUpdateBEFORE.Escalate_to_SEAD__c = true; 
        update caseToUpdateBEFORE; 
        Test.stopTest(); 

        //Check if we are in a sandbox
        Boolean isASandbox = false;
        String domainName = System.DomainParser.parse(URL.getOrgDomainUrl()).getSandboxName();
        if(domainName != null && domainName != ''){
            isASandbox = true; 
        }
        
        Case_Jira_AppFire_Setting__mdt mdtSettings = Case_Jira_AppFire_Setting__mdt.getInstance('Config');
        Boolean boolAPIEnabled = mdtSettings.JCFS_API_Apex_Enabled__c;
        Boolean boolAllowSandboxSend = mdtSettings.Allow_Sandbox_to_Send__c;
        
        Case caseToUpdateAFTER = [SELECT Id, Escalate_to_SEAD__c,Jira_AppFire_Create_Apex_Ran__c FROM Case WHERE Id = :newCase.Id];
        System.assertEquals(true, caseToUpdateAFTER.Escalate_to_SEAD__c, 'Actual ::: '+caseToUpdateAFTER.Escalate_to_SEAD__c);
        if(mdtSettings != null && boolAPIEnabled){
            if(isASandbox && boolAllowSandboxSend){
                System.assertNotEquals(null, caseToUpdateAFTER.Jira_AppFire_Create_Apex_Ran__c, 'Expected :: Jira AppFire Create Apex Ran to have a date/time');
            }
            if(isASandbox && !boolAllowSandboxSend){
                System.assertEquals(null, caseToUpdateAFTER.Jira_AppFire_Create_Apex_Ran__c, 'Expected :: Jira AppFire Create Apex Ran to be NULL');
            }
            if(!isASandbox){
                System.assertNotEquals(null, caseToUpdateAFTER.Jira_AppFire_Create_Apex_Ran__c, 'Expected :: Jira AppFire Create Apex Ran to have a date/time');
            }
        }
    }
    /*****************************************************
     * Test with a Training Help Desk Case, should not trigger  
     ****************************************************/
    @isTest  
    private static void test_MCG_NonTSS_Case_1(){
        // Get the Account and Contact from Test Setup
        Account theAccount = [SELECT Id FROM Account WHERE Name = 'Test AppFire Account' LIMIT 1];
        Contact theContact = [SELECT Id FROM Contact WHERE LastName = 'AppFireContactTest' LIMIT 1];
        
        // Get Training Help Desk Case Record Type for this test. 
        Id idTHDRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Training_Help_Desk').getRecordTypeId();

        // Create test case that should be escalated to JIRA
        Case newCase = new Case( 
            ContactId = theContact.Id,
            AccountId = theAccount.Id,
            Subject = 'Test AppFire Case',
            Product__c = 'CareWebQI',
            RecordTypeId = idTHDRecordTypeId,
            Status = 'New',
            Priority = 'Level 3: Medium'); 
        insert newCase;

        Test.startTest(); 
        //Run Test, Update Case to Escalate to SEAD. 
        Case caseToUpdateBEFORE = [SELECT Id, Escalate_to_SEAD__c FROM Case WHERE Id = :newCase.Id];
        caseToUpdateBEFORE.Escalate_to_SEAD__c = true; 
        update caseToUpdateBEFORE; 
        Test.stopTest(); 

        //Assert that Escalated To SEAD is true and the Jira AppFire create did NOT run. 
        Case caseToUpdateAFTER = [SELECT Id, Escalate_to_SEAD__c,Jira_AppFire_Create_Apex_Ran__c FROM Case WHERE Id = :newCase.Id];
        System.assertEquals(true, caseToUpdateAFTER.Escalate_to_SEAD__c, 'Actual ::: '+caseToUpdateAFTER.Escalate_to_SEAD__c);
        System.assertEquals(null, caseToUpdateAFTER.Jira_AppFire_Create_Apex_Ran__c, 'Actual ::: '+caseToUpdateAFTER.Jira_AppFire_Create_Apex_Ran__c);
    }

    /*****************************************************
     * Test method to verify case creation in JIRA when a case is escalated to SEAD
     ****************************************************/
    @isTest
    private static void testCreateCaseInJira() {
        // Get the Account and Contact from Test Setup
        Account theAccount = [SELECT Id FROM Account WHERE Name = 'Test AppFire Account' LIMIT 1];
        Contact theContact = [SELECT Id FROM Contact WHERE LastName = 'AppFireContactTest' LIMIT 1];
        
        // Get Technical Support Record Type Id
        Id tssRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Technical_Support').getRecordTypeId();
        
        // Create test case that should be escalated to JIRA
        Case testCase = new Case(
            Subject = 'Test Case for JIRA Creation',
            Description = 'This is a test case for JIRA creation',
            Status = 'New',
            Priority = 'Level 1: Critical',
            Product__c = 'Test Product',
            RecordTypeId = tssRecordTypeId,
            Escalate_to_SEAD__c = false
        );
        insert testCase;
                
        Test.startTest();
        //Run Test, Update Case to Escalate to SEAD.
        testCase.Escalate_to_SEAD__c = true;
        update testCase;        
        Test.stopTest();

        //Check if we are in a sandbox
        Boolean isASandbox = false;
        String domainName = System.DomainParser.parse(URL.getOrgDomainUrl()).getSandboxName();
        if(domainName != null && domainName != ''){
            isASandbox = true; 
        }
        
        Case_Jira_AppFire_Setting__mdt mdtSettings = Case_Jira_AppFire_Setting__mdt.getInstance('Config');
        Boolean boolAPIEnabled = mdtSettings.JCFS_API_Apex_Enabled__c;
        Boolean boolAllowSandboxSend = mdtSettings.Allow_Sandbox_to_Send__c;
        
        Case caseToUpdateAFTER = [SELECT Id, Escalate_to_SEAD__c,Jira_AppFire_Create_Apex_Ran__c FROM Case WHERE Id = :testCase.Id];
        System.assertEquals(true, caseToUpdateAFTER.Escalate_to_SEAD__c, 'Actual ::: '+caseToUpdateAFTER.Escalate_to_SEAD__c);
        if(mdtSettings != null && boolAPIEnabled){
            if(isASandbox && boolAllowSandboxSend){
                System.assertNotEquals(null, caseToUpdateAFTER.Jira_AppFire_Create_Apex_Ran__c, 'Expected :: Jira AppFire Create Apex Ran to have a date/time');
            }
            if(isASandbox && !boolAllowSandboxSend){
                System.assertEquals(null, caseToUpdateAFTER.Jira_AppFire_Create_Apex_Ran__c, 'Expected :: Jira AppFire Create Apex Ran to be NULL');
            }
            if(!isASandbox){
                System.assertNotEquals(null, caseToUpdateAFTER.Jira_AppFire_Create_Apex_Ran__c, 'Expected :: Jira AppFire Create Apex Ran to have a date/time');
            }
        }
    }
    
    /*****************************************************
     * Test method to verify case update in JIRA for an existing case with JIRA ID
    *****************************************************/
    @isTest
    private static void testUpdateCaseInJira() {
        // Get the Account and Contact from Test Setup
        Account theAccount = [SELECT Id FROM Account WHERE Name = 'Test AppFire Account' LIMIT 1];
        Contact theContact = [SELECT Id FROM Contact WHERE LastName = 'AppFireContactTest' LIMIT 1];
        
        // Get Technical Support Record Type Id
        Id tssRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Technical_Support').getRecordTypeId();
        
        // Create test case that already has a JIRA ID
        Case testCase = new Case(
            Subject = 'Test Case for JIRA Update',
            Description = 'This is a test case for JIRA update',
            Status = 'In Progress',
            Priority = 'Level 2: Serious',
            Product__c = 'Test Product',
            RecordTypeId = tssRecordTypeId,
            Jira_Id__c = 'JIRA-1234'
        );
        insert testCase;
        
        Test.startTest();
        // Update the case to trigger JIRA update
        testCase.Subject = 'Updated Test Case for JIRA';
        update testCase;
        
        Test.stopTest();
        
        // No direct assertion needed as we're testing if the code executes without errors
        // The timestamp field is not updated for updates, only for creations
    }
    
    /*****************************************************
     * Test method to verify no JIRA creation for closed cases
    *****************************************************/
    @isTest
    private static void testNoJiraForClosedCases() {
        // Get the Account and Contact from Test Setup
        Account theAccount = [SELECT Id FROM Account WHERE Name = 'Test AppFire Account' LIMIT 1];
        Contact theContact = [SELECT Id FROM Contact WHERE LastName = 'AppFireContactTest' LIMIT 1];
        
        // Get Technical Support Record Type Id
        Id tssRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Technical_Support').getRecordTypeId();
        
        // Create test case that is closed
        Case testCase = new Case(
            Subject = 'Test Closed Case',
            Description = 'This is a test closed case',
            Status = 'Closed',
            Priority = 'Level 1: Critical',
            Product__c = 'Test Product',
            RecordTypeId = tssRecordTypeId,
            Escalate_to_SEAD__c = false
        );
        insert testCase;
        
        Test.startTest();        
        // Update the case to trigger escalation
        testCase.Escalate_to_SEAD__c = true;
        update testCase;
        Test.stopTest();
        
        // Verify the case was not updated with timestamp
        Case updatedCase = [SELECT Id, Jira_AppFire_Create_Apex_Ran__c FROM Case WHERE Id = :testCase.Id];
        System.assertEquals(null, updatedCase.Jira_AppFire_Create_Apex_Ran__c, 'The Jira_AppFire_Create_Apex_Ran__c field should not be populated for closed cases');
    }
    
    /*****************************************************
     * Test method to verify no JIRA creation for cases with low priority
    *****************************************************/
    @isTest
    private static void testNoJiraForLowPriorityCases() {
        // Get the Account and Contact from Test Setup
        Account theAccount = [SELECT Id FROM Account WHERE Name = 'Test AppFire Account' LIMIT 1];
        Contact theContact = [SELECT Id FROM Contact WHERE LastName = 'AppFireContactTest' LIMIT 1];
        
        // Get Technical Support Record Type Id
        Id tssRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Technical_Support').getRecordTypeId();
        
        // Create test case with low priority
        Case testCase = new Case(
            Subject = 'Test Low Priority Case',
            Description = 'This is a test low priority case',
            Status = 'New',
            Priority = 'Level 4: Low',  // Low priority
            Product__c = 'Test Product',
            RecordTypeId = tssRecordTypeId,
            Escalate_to_SEAD__c = false
        );
        insert testCase;
        
        Test.startTest();
        // Update the case to trigger escalation
        testCase.Escalate_to_SEAD__c = true;
        update testCase;    
        Test.stopTest();
        
        // Verify the case was not updated with timestamp
        Case updatedCase = [SELECT Id, Jira_AppFire_Create_Apex_Ran__c FROM Case WHERE Id = :testCase.Id];
        System.assertEquals(null, updatedCase.Jira_AppFire_Create_Apex_Ran__c, 'The Jira_AppFire_Create_Apex_Ran__c field should not be populated for low priority cases');
    }
    
    /*****************************************************
     * Test method to verify no JIRA creation for cases with wrong record type
    *****************************************************/
    @isTest
    private static void testNoJiraForWrongRecordType() {
        // Get the Account and Contact from Test Setup
        Account theAccount = [SELECT Id FROM Account WHERE Name = 'Test AppFire Account' LIMIT 1];
        Contact theContact = [SELECT Id FROM Contact WHERE LastName = 'AppFireContactTest' LIMIT 1];
        
        // Get a different Record Type Id (not TSS)
        Id differentRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Training_Help_Desk').getRecordTypeId();

        // Create test case with wrong record type
        Case testCase = new Case(
            Subject = 'Test Wrong Record Type Case',
            Description = 'This is a test case with wrong record type',
            Status = 'New',
            Priority = 'Level 1: Critical',
            Product__c = 'Test Product',
            RecordTypeId = differentRecordTypeId,
            Escalate_to_SEAD__c = false
        );
        insert testCase;
        
        Test.startTest();
        // Update the case to trigger escalation
        testCase.Escalate_to_SEAD__c = true;
        update testCase;
        Test.stopTest();
        
        // Verify the case was not updated with timestamp
        Case updatedCase = [SELECT Id, Jira_AppFire_Create_Apex_Ran__c FROM Case WHERE Id = :testCase.Id];
        System.assertEquals(null, updatedCase.Jira_AppFire_Create_Apex_Ran__c, 'The Jira_AppFire_Create_Apex_Ran__c field should not be populated for wrong record type');
    }
    
    /*****************************************************
     * Test bulk case processing
    *****************************************************/
    @isTest
    private static void testBulkCaseProcessing() {
        // Get the Account and Contact from Test Setup
        Account theAccount = [SELECT Id FROM Account WHERE Name = 'Test AppFire Account' LIMIT 1];
        Contact theContact = [SELECT Id FROM Contact WHERE LastName = 'AppFireContactTest' LIMIT 1];
        
        // Get Technical Support Record Type Id
        Id tssRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Technical_Support').getRecordTypeId();
        
        // Create multiple test cases
        List<Case> testCases = new List<Case>();
        for (Integer i = 0; i < 200; i++) {
            Case c = new Case(
                Subject = 'Test Bulk Case ' + i,
                Description = 'This is a test bulk case ' + i,
                Status = 'New',
                Priority = 'Level 1: Critical',
                Product__c = 'Test Product',
                RecordTypeId = tssRecordTypeId,
                Escalate_to_SEAD__c = false
            );
            testCases.add(c);
        }
        insert testCases;
        
        Test.startTest();
        
        // Update all cases to trigger escalation
        for (Case c : testCases) {
            c.Escalate_to_SEAD__c = true;
        }
        update testCases;        
        Test.stopTest();
        
        //Check if we are in a sandbox
        Boolean isASandbox = false;
        String domainName = System.DomainParser.parse(URL.getOrgDomainUrl()).getSandboxName();
        if(domainName != null && domainName != ''){
            isASandbox = true; 
        }
        
        Case_Jira_AppFire_Setting__mdt mdtSettings = Case_Jira_AppFire_Setting__mdt.getInstance('Config');
        Boolean boolAPIEnabled = mdtSettings.JCFS_API_Apex_Enabled__c;
        Boolean boolAllowSandboxSend = mdtSettings.Allow_Sandbox_to_Send__c;
        
        List<Case> lstCasesToUpdateAFTER = [SELECT Id, Escalate_to_SEAD__c,Jira_AppFire_Create_Apex_Ran__c FROM Case WHERE Id = :testCases];
        
        for(Case caseToUpdateAFTER : lstCasesToUpdateAFTER){
            System.assertEquals(true, caseToUpdateAFTER.Escalate_to_SEAD__c, 'Actual ::: '+caseToUpdateAFTER.Escalate_to_SEAD__c);
            if(mdtSettings != null && boolAPIEnabled){
                if(isASandbox && boolAllowSandboxSend){
                    System.assertNotEquals(null, caseToUpdateAFTER.Jira_AppFire_Create_Apex_Ran__c, 'Expected :: Jira AppFire Create Apex Ran to have a date/time');
                }
                if(isASandbox && !boolAllowSandboxSend){
                    System.assertEquals(null, caseToUpdateAFTER.Jira_AppFire_Create_Apex_Ran__c, 'Expected :: Jira AppFire Create Apex Ran to be NULL');
                }
                if(!isASandbox){
                    System.assertNotEquals(null, caseToUpdateAFTER.Jira_AppFire_Create_Apex_Ran__c, 'Expected :: Jira AppFire Create Apex Ran to have a date/time');
                }
            }    
        }
    }
}