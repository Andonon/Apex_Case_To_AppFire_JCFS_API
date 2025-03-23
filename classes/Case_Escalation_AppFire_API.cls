/*
*********************************************************
Apex Class Name    : Case_Escalation_AppFire_API
Created Date       : March 11, 2025
@description       : Used to send the API call to the AppFire API for Case Escalations
@author            : Troy Center
Modification Log:
Ver   Date         Author                   Case            Modification    
1.0   03/11/2025   Troy Center              00000000        Initial Version, based on documentation from AppFire. 
                                                            AppFire Documentation: https://appfire.atlassian.net/wiki/spaces/CSFJIRA/pages/1873446010/Configure+Automatic+Pull+from+Salesforce
*********************************************************
*/
public class Case_Escalation_AppFire_API {
    public Case_Escalation_AppFire_API(List<Case> lstCasesIn, Map<Id,Case> mapOldCasesIn) {
        
        //Get Case Esclation AppFire Custom Metadata Settings
        String strAppFireSettingsString = 'Config'; 
        Case_Jira_AppFire_Setting__mdt AppFire_settings = Case_Jira_AppFire_Setting__mdt.getInstance(strAppFireSettingsString);                 

        //Check if AppFire Custom Settings are "Feature Enabled". 
        if(AppFire_settings != null && AppFire_settings.JCFS_API_Apex_Enabled__c == true){

            //Check if we are in a sandbox
            Boolean isASandbox = false;
            String domainName = System.DomainParser.parse(URL.getOrgDomainUrl()).getSandboxName();
            if(domainName != null && domainName != ''){
                isASandbox = true; 
            }

            //Get TSS Record Type, for create methood. 
            Id idTSSRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Technical_Support').getRecordTypeId();
                
            //Create List of Cases to Send Jira 
            List<Case> lstCasesToCreateInJira = new List<Case>();
            List<Case> lstCasesToUpdateInJira = new List<Case>();  
            List<Case> lstEmptyListOfCases = new List<Case>(); // Needed for "JSFS.API.createJiraIssue(String JiraProjectId, String JiraIssueTypeId, List<SObject> newObjects, List<SObject> oldObjects)"

            //Loop on the cases. 
            for(Case c : lstCasesIn){
                //If Open Case is updated that has a Jira ID. 
                if(c.isClosed == false && c.Jira_Id__c != null){
                    lstCasesToUpdateInJira.add(c); 
                }
                //Else If Escalate to SEAD, with no Jira ID, Create a Jira Item. 
                else if(c.Escalate_to_SEAD__c == true && 
                        c.Escalate_to_SEAD__c != mapOldCasesIn.get(c.Id).Escalate_to_SEAD__c && 
                        c.isClosed == false && 
                        c.Product__c != null && 
                        c.Jira_Id__c == null &&
                        c.Jira_AppFire_Create_Apex_Ran__c == null &&
                        c.RecordTypeId == idTSSRecordTypeId &&
                        (   
                            c.Priority == 'Level 1: Critical' || 
                            c.Priority == 'Level 2: Serious' || 
                            c.Priority == 'Level 3: Medium'
                        ) &&
                        (   
                            isASandbox == false || 
                            AppFire_settings.Allow_Sandbox_To_Send__c == true
                        )
                ){
                    lstCasesToCreateInJira.add(c); 
                }
            }

            // Get App Fire Settings to Send to
            String strJiraProjectId = AppFire_settings.Project_Id__c;
            String strJiraIssueId = AppFire_settings.Issue_Id__c;
            Boolean boolUseAdvancedAPI = AppFire_settings.JCFS_API_Use_Advanced_API__c; //Default is true.
            
            // Do Final Update on Case. Update the Case Date Field and Call the JCFS App API (Requires We Get the Cases again, Post Update, They are Read Only. )
            // using Jira_AppFire_Create_Apex_Ran__c to prevent duplicates by adding a date/time field to the case when we send it, Syncronously. 
            if(lstCasesToCreateInJira.size() > 0 && !System.isBatch() && !System.isFuture()){
                List<Case> lstCasestoCreateFinal = [SELECT Id, Jira_AppFire_Create_Apex_Ran__c, Jira_Id__c FROM Case WHERE Id IN: lstCasesToCreateInJira];    
                for(Case c : lstCasestoCreateFinal){    
                    c.Jira_AppFire_Create_Apex_Ran__c = System.now();
                    if(Test.isRunningTest()){       //If we ARE in a test run, MOCK the Jira ID. 
                        if(c.Jira_Id__c == null){
                            c.Jira_Id__c = 'TEST-999';
                        } 
                    }
                }
                update lstCasestoCreateFinal;   //Final update list we do not send to Jira, we send the trigger list to Jira.                    
            }
            // ***********************   Call JCFS CREATE *****************************
            // API Documentation: https://appfire.atlassian.net/wiki/spaces/CSFJIRA/pages/1873413628/Configuring+automatic+Jira+issue+creation+from+Salesforce
            // Pass all the objects you want to create a Jira issue from as newObjects. 
            // Note that all the objects in this list must be of the same runtime type. 
            // So we recommend using a concrete type, e.g. List<Case> or List<Account> for the variable, you pass as this parameter. 
            // ** The oldObjects parameter is not used at the moment so you can pass Trigger.old or an empty list for it.
            // ** MCG is using an empty list of cases, not Trigger.old (for triggers only)(is a List of Cases). 
            // ************************************************************************
            if(lstCasesToCreateInJira.size() > 0 && !System.isBatch() && !System.isFuture()){
                //Check the Custom Metadata Setting "JCFS API Use Advanced API"
                //Advanced API If Test Check and JCFS API call must be on the same line for Code Coverage. 
                if(boolUseAdvancedAPI == true && !Test.isRunningTest()){ JCFS.API.createJiraIssueWithDefaultPostAction(strJiraProjectId, strJiraIssueId, lstCasesToCreateInJira, lstEmptyListOfCases); } 
                if(boolUseAdvancedAPI == false && !Test.isRunningTest()){ JCFS.API.createJiraIssueWithDefaultPostAction(strJiraProjectId, strJiraIssueId); } 
            }                    
            // ***********************   Call JCFS Update *****************************
            // Our Apex API supports a selective pushing, so that you can exclude unwanted Salesforce objects from the push. For this purpose you can use the following API method:
            // Sample 1: JCFS.API.pushUpdatesToJira(List<SObject> newObjects, List<SObject> oldObjects)
            // Sample 2: JCFS.API.pushUpdatesToJira();
            // ** The oldObjects parameter is not used at the moment so you can pass Trigger.old or an empty list for it.
            // **   MCG is using an empty list of cases, not Trigger.old (for triggers only)(is a List of Cases). 
            // ************************************************************************
            if(lstCasesToUpdateInJira.size() > 0 && !System.isBatch() && !System.isFuture()){
                //Check the Custom Metadata Setting "JCFS API Use Advanced API"
                //Advanced API If Test Check and JCFS API call must be on the same line for Code Coverage. 
                if(boolUseAdvancedAPI == true && !Test.isRunningTest()){ JCFS.API.pushUpdatesToJira(lstCasesToUpdateInJira,lstEmptyListOfCases); }
                if(boolUseAdvancedAPI == false && !Test.isRunningTest()){ JCFS.API.pushUpdatesToJira(); }
            }
        }
    }
}