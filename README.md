# Case Escalation AppFire API - Apex Class Summary

This Apex class manages the integration between Salesforce Cases and Jira through the AppFire API. It handles two main operations:

1. **Creating new Jira issues** when Salesforce cases are escalated to SEAD
2. **Updating existing Jira issues** when associated Salesforce cases are modified

## Key Functionality

- Retrieves configuration from custom metadata (Case_Jira_AppFire_Setting__mdt)
- Determines if the integration is enabled and if sandbox execution is allowed
- Filters cases that need to be created or updated in Jira based on specific criteria
- Prevents duplicate submissions by tracking when cases have been sent to Jira
- Handles different API methods based on configuration settings

## Case Creation Criteria
Cases are created in Jira when:
- "Escalate to SEAD" is changed to true
- Case is not closed
- Product field is populated
- No existing Jira ID
- Case hasn't been processed before
- Case has Technical Support record type
- Priority is Level 1-3
- Environment is production OR sandbox sending is allowed

## Technical Implementation
- Uses JCFS.API methods for Jira integration
- Implements safeguards against batch and future context execution
- Includes test coverage accommodations
- Updates cases with timestamps to prevent duplicate processing

The class was created on March 11, 2025, by Troy Center at MCG Health, based on AppFire documentation.

## Case_Escalation_AppFire_API_Tests - Apex Test Class Summary
This test class provides comprehensive test coverage for the Case_Escalation_AppFire_API class with 100% code coverage. It was created on March 11, 2025, by Troy Center at MCG Health.

### Test Structure
The class contains:

A @TestSetup method that creates test Account and Contact records
Seven test methods that validate different scenarios for the AppFire API integration

### Test Methods
* test_MCG_TSS_Case_1:
Tests creation of a Jira issue when a Technical Support case is escalated to SEAD
Verifies proper timestamp field population based on environment and settings

* test_MCG_NonTSS_Case_1: 
Tests that non-Technical Support cases (Training Help Desk) don't trigger Jira creation
Confirms the timestamp field remains null

* testCreateCaseInJira: 
Tests the core functionality of creating a case in Jira
Validates timestamp field population based on environment settings

* testUpdateCaseInJira: 
Tests updating an existing case that already has a Jira ID
Focuses on code execution without errors

* testNoJiraForClosedCases: 
Verifies that closed cases don't trigger Jira creation
Confirms timestamp field remains null

* testNoJiraForLowPriorityCases: 
Tests that low priority cases (Level 4) don't trigger Jira creation
Confirms timestamp field remains null

* testNoJiraForWrongRecordType: 
Verifies cases with incorrect record types don't trigger Jira creation
Confirms timestamp field remains null

* testBulkCaseProcessing: 
Tests bulk processing of 200 cases
Validates proper handling of multiple records
Verifies timestamp field population based on environment settings

### Testing Approach
The tests cover all key scenarios:
* Different case record types
* Various priority levels
* Closed vs. open cases
* Cases with and without existing Jira IDs
* Bulk processing capabilities
* Environment-specific behavior (sandbox vs. production)
* Custom metadata settings impact
* Each test includes appropriate assertions to validate the expected behavior based on the configuration settings and environment context.

## Getting Started
Before you can install, some Salesforce configuration is needed. 

### Case Fields to create
* Add a field on Case Jira_Id__c. This is a field that is updated by the AppFire connection.
* Setup AppFire to update the Case Jira_Id__c field as it's related "ID".
* Add a field on Case, Date/Time, "Jira AppFire Create Apex Ran", Jira_AppFire_Create_Apex_Ran__c. This will be used to prevent duplicate calls to the JCFS tool, and to track the date/time we made that call.

### Custom Metadata Record "Config"
* Salesforce | Setup | Custom Metadata Settings
* Add a new entry.
* Name: ["Config"]
* ProjectId: [ProjectId from your Jira]
* IssueId: [IssueId from your Jira]
* Allow Sandbox to Send: [True]
* JCFS API Apex Enabled: [True]
* JCFS API Use Advanced API: [True] 

### Dependencies

* VSCode with the Salesforce CLI
* Salesforce Dev Environment

### Installing

* This code requires an installed package from AppFire, the Salesforce to Jira Connector. https://appfire.com/products/connector-for-salesforce-and-jira
* You may want to merge this trigger with your triggers. Runs After Update on Case only.
* The Class and Test Class take standard Case Trigger inputs.
* Configuration changes are made with the Custom Metadata Settings. "Case AppFire Jira Setting". You will need to create a record called "Config". 

### Executing program

* Enable the Apex using the Custom Metadata Setting "Case AppFire Jira Setting". Also Enable Allow Sandbox to Send, JCFS API Use Advanced API to True. This allows a sandbox to send messages, and for the messages to use the triggered list of cases in the API calls. See AppFire Documentation.  
* Run Apex Tests and Debug Logs. 

## Help

Any advise for common problems or issues.
Use the Custom Metadata Settings to disable to code until you can fix it. 
Ask me questions? 

## Authors

Contributors names and contact info

Troy Center [@Andonon](https://x.com/troycenter) 

## Version History

* 0.2
    * Initial Complete Version. Trigger, Apex, Test Class, Custom Metadata. 
    * See [commit change]() or See [release history]()
* 0.1
    * Initial Release for support from AppFire. 

## License

This project is licensed under the MIT License - see the LICENSE.md file for details

## Acknowledgments

Inspiration, code snippets, etc.
* [awesome-readme](https://github.com/matiassingers/awesome-readme)
