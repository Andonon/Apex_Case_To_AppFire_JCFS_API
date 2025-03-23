/*
*********************************************************
Apex Class Name    : CaseTrigger
@date              : 03/21/2025
@description       : This is the main Case Trigger for the Case Object. 
@author            : Troy Center
Modification Log:
Ver   Date              Author              Case Number         Modification
1.0   03/21/2025        Troy Center         00000000            Initial Version
*********************************************************
*/
trigger CaseTrigger on Case (after update) {

    Boolean isAfterUpdate = (trigger.isUpdate && trigger.isAfter);

    if(isAfterUpdate){
        Case_Escalation_AppFire_API sendCaseEscalationAppFireAPI = new Case_Escalation_AppFire_API(Trigger.new, Trigger.oldMap);
    }
}