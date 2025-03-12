/*
*********************************************************
Apex Class Name    : Case_Escalation_AppFire_API
Created Date       : March 11, 2025
@description       : Used to send the API call to the AppFire API for Case Escalations
@author            : Troy Center, MCG Health
Modification Log:
Ver   Date         Author                   Case            Modification    
1.0   06/28/2024   troy.center@mcg.com      00391891        Initial Version
*********************************************************
*/
public class Case_Escalation_AppFire_API {
    public Case_Escalation_AppFire_API(List<Case> lstCasesIn, Map<Id,Case> mapOldCasesIn) {

        //Get TSS Record Type
        Id idTSSRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Technical_Support').getRecordTypeId();

        //Create List of Cases to Send Jira. 
        List<Case> lstCasesToCreateInJira = new List<Case>(); 
        List<Case> lstCasesToUpdateInJira = new List<Case>(); 
        List<Case> lstCasesToAssociateWithJira = new List<Case>(); 

        //Get Case Esclation AppFire Custom Metadata Settings
        Case_Escalation_AppFire_Setting__mdt AppFire_settings = Case_Escalation_AppFire_Setting__mdt.getInstance('Config');
        System.Debug('TCTC501 settings.Project_Id__c ::: '+AppFire_settings.Project_Id__c);
        System.Debug('TCTC501 settings.Issue_Id__c ::: '+AppFire_settings.Issue_Id__c);
        System.Debug('TCTC501 settings.Allow_Sandbox_To_Send__c ::: '+AppFire_settings.Allow_Sandbox_To_Send__c);
        
        //Check if we are in a sandbox
        String domainName = System.DomainParser.parse(URL.getOrgDomainUrl()).getSandboxName();
        System.Debug('TCTC502 domainName ::: '+domainName);

        Boolean isASandbox = false; 
        System.Debug('TCTC503 isASandbox ::: '+isASandbox);

        if(domainName != null && domainName != ''){
            isASandbox = true; 
        }

        System.Debug('TCTC503 isASandbox ::: '+isASandbox);

        for(Case c : lstCasesIn){
            System.Debug('TCTC504 c.Escalate_to_SEAD__c ::: '+c.Escalate_to_SEAD__c);
            System.Debug('TCTC504 mapOldCasesIn.get(c.Id).Escalate_to_SEAD__c ::: '+mapOldCasesIn.get(c.Id).Escalate_to_SEAD__c);
            System.Debug('TCTC504 c.isClosed ::: '+c.isClosed);
            System.Debug('TCTC504 c.Product__c ::: '+c.Product__c);
            System.Debug('TCTC504 c.Jira_Id__c ::: '+c.Jira_Id__c);
            System.Debug('TCTC504 idTSSRecordTypeId ::: '+idTSSRecordTypeId);
            System.Debug('TCTC504 c.RecordTypeId ::: '+c.RecordTypeId);
            System.Debug('TCTC504 c.Priority ::: '+c.Priority);
            System.Debug('TCTC504 AppFire_settings.Allow_Sandbox_To_Send__c ::: '+AppFire_settings.Allow_Sandbox_To_Send__c);
            if(
                c.Escalate_to_SEAD__c == true && c.Escalate_to_SEAD__c != mapOldCasesIn.get(c.Id).Escalate_to_SEAD__c && 
                c.isClosed == false && 
                c.Product__c != null && 
                c.Jira_Id__c == null &&
                c.RecordTypeId == idTSSRecordTypeId &&
                (
                    c.Priority == 'Level 1: Critical' || 
                    c.Priority == 'Level 2: Serious' || 
                    c.Priority == 'Level 3: Medium'
                ) && 
                (
                    string.valueOf(c.OwnerId).startsWith('005')      &&
                    (
                        isASandbox == false || 
                        AppFire_settings.Allow_Sandbox_To_Send__c == true
                    )
                )
            ){
                lstCasesToCreateInJira.add(c); 
            }            
        }
        System.Debug('TCTC505 lstCasesToCreateInJira.size() ::: '+lstCasesToCreateInJira.size());
        System.Debug('TCTC505 lstCasesToCreateInJira ::: '+lstCasesToCreateInJira);

        //AppFire does not use oldCases. The oldObjects parameter is not used at the moment so you can pass Trigger.old or an empty list for it.
        List<Case> lstEmptyCaseList = new List<Case>(); 

        if(lstCasesToCreateInJira.size()>0){
            System.Debug('TCTC506 Sending '+lstCasesToCreateInJira.size()+' Cases to Jira for CREATE ISSUE');
            JCFS.API.createJiraIssue('11670', '10001', lstCasesToCreateInJira, lstEmptyCaseList);
            JCFS.API.createJiraIssue('11670', '10001');
            // JCFS.API.createJiraIssueWithDefaultPostAction('11670', '10001', lstCasesToCreateInJira, lstOldCasesIn);
        }

        System.Debug('TCTC507 STARTING UPDATE METHOD ::: '+lstCasesToUpdateInJira);

        for(Case c : lstCasesIn){
            System.Debug('TCTC508 c.Escalate_to_SEAD__c ::: '+c.Escalate_to_SEAD__c);
            System.Debug('TCTC508 mapOldCasesIn.get(c.Id).Escalate_to_SEAD__c ::: '+mapOldCasesIn.get(c.Id).Escalate_to_SEAD__c);
            System.Debug('TCTC508 c.isClosed ::: '+c.isClosed);
            System.Debug('TCTC508 c.Product__c ::: '+c.Product__c);
            System.Debug('TCTC508 c.Jira_Id__c ::: '+c.Jira_Id__c);
            System.Debug('TCTC508 idTSSRecordTypeId ::: '+idTSSRecordTypeId);
            System.Debug('TCTC508 c.RecordTypeId ::: '+c.RecordTypeId);
            System.Debug('TCTC508 c.Priority ::: '+c.Priority);
            System.Debug('TCTC508 AppFire_settings.Allow_Sandbox_To_Send__c ::: '+AppFire_settings.Allow_Sandbox_To_Send__c);
            if(
                c.Escalate_to_SEAD__c == true && 
                (
                    c.Escalate_to_SEAD__c == mapOldCasesIn.get(c.Id).Escalate_to_SEAD__c ||
                    c.Product__c != mapOldCasesIn.get(c.Id).Product__c 
                ) &&
                c.isClosed == false && 
                c.Product__c != null && 
                c.Jira_Id__c != null && c.Jira_Id__c == mapOldCasesIn.get(c.Id).Jira_Id__c &&  
                c.RecordTypeId == idTSSRecordTypeId && 
                (
                    isASandbox == false || 
                    AppFire_settings.Allow_Sandbox_To_Send__c == true
                )
            ){
                lstCasesToUpdateInJira.add(c);
            }
        }

        System.Debug('TCTC509 lstCasesToUpdateInJira.size() ::: '+lstCasesToUpdateInJira.size());
        System.Debug('TCTC509 lstCasesToUpdateInJira ::: '+lstCasesToUpdateInJira);

        if(lstCasesToUpdateInJira.size()>0){
            System.Debug('TCTC510 Sending '+lstCasesToUpdateInJira.size()+' Cases to Jira for UPDATE ISSUE');
            JCFS.API.pushUpdatesToJira(lstCasesToUpdateInJira, lstEmptyCaseList);
            JCFS.API.pushUpdatesToJira();
            
        }

        for(Case c : lstCasesIn){
            System.Debug('TCTC511 c.Escalate_to_SEAD__c ::: '+c.Escalate_to_SEAD__c);
            System.Debug('TCTC511 mapOldCasesIn.get(c.Id).Escalate_to_SEAD__c ::: '+mapOldCasesIn.get(c.Id).Escalate_to_SEAD__c);
            System.Debug('TCTC511 c.isClosed ::: '+c.isClosed);
            System.Debug('TCTC511 c.Product__c ::: '+c.Product__c);
            System.Debug('TCTC511 c.Jira_Id__c ::: '+c.Jira_Id__c);
            System.Debug('TCTC511 idTSSRecordTypeId ::: '+idTSSRecordTypeId);
            System.Debug('TCTC511 c.RecordTypeId ::: '+c.RecordTypeId);
            System.Debug('TCTC511 c.Priority ::: '+c.Priority);
            System.Debug('TCTC511 AppFire_settings.Allow_Sandbox_To_Send__c ::: '+AppFire_settings.Allow_Sandbox_To_Send__c);
            if(
                c.Escalate_to_SEAD__c == true && 
                c.isClosed == false && 
                c.Product__c != null && 
                c.Jira_Id__c != null && c.Jira_Id__c != mapOldCasesIn.get(c.Id).Jira_Id__c &&  
                c.RecordTypeId == idTSSRecordTypeId && 
                (
                    isASandbox == false || 
                    AppFire_settings.Allow_Sandbox_To_Send__c == true
                )
            ){
                lstCasesToAssociateWithJira.add(c);
            }
        }
        if(lstCasesToAssociateWithJira.size() > 0){
            Map<String, List<Case>> casesByJiraId = new Map<String, List<Case>>();
                
            for(Case c : lstCasesToAssociateWithJira){
                // Step 1: Group cases by unique Jira_Id__c
                if (!casesByJiraId.containsKey(c.Jira_Id__c)) {
                    casesByJiraId.put(c.Jira_Id__c, new List<Case>());
                }
                casesByJiraId.get(c.Jira_Id__c).add(c);
            }

            for (String jiraId : casesByJiraId.keySet()) {
                List<Case> casesForApiCall = casesByJiraId.get(jiraId);
                
                // Log or process each list of cases and Jira_Id__c
                System.debug('TCTC512 Jira ID: ' + jiraId);
                System.debug('TCTC512 Cases for this Jira ID: ' + casesForApiCall);
            
                JCFS.API.associateJiraIssueWithDefaultPostActions(jiraId, casesForApiCall);
            }
        }
    }
}