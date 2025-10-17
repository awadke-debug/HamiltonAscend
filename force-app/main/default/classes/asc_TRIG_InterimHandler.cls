global with sharing class asc_TRIG_InterimHandler extends ucinn_ascendv2.ascend_TDTM_Runnable {
    private ucinn_ascendv2.ascend_TDTM_Runnable.DmlWrapper dmlWrapper = new ucinn_ascendv2.ascend_TDTM_Runnable.DmlWrapper();
    //Changed third time
    global override ucinn_ascendv2.ascend_TDTM_Runnable.DmlWrapper run(List<SObject> newList, List<SObject> oldList, ucinn_ascendv2.ascend_TDTM_Runnable.Action triggerAction, Schema.DescribeSObjectResult objResult) {
        List<ucinn_ascendv2__Interim__c> triggerNew = (List<ucinn_ascendv2__Interim__c>)newList;
        List<ucinn_ascendv2__Interim__c> triggerOld = (List<ucinn_ascendv2__Interim__c>)oldList;

        Map<Id, ucinn_ascendv2__Interim__c> triggerOldMap = new Map<Id, ucinn_ascendv2__Interim__c>();
        if (triggerOld != null) {
            for (ucinn_ascendv2__Interim__c eachInt : triggerOld) {
                triggerOldMap.put(eachInt.Id, eachInt);
            }
        }

        if (triggerAction == ucinn_ascendv2.ascend_TDTM_Runnable.Action.BeforeInsert) {
            
        } else if (triggerAction == ucinn_ascendv2.ascend_TDTM_Runnable.Action.AfterInsert) {

        } else if (triggerAction == ucinn_ascendv2.ascend_TDTM_Runnable.Action.BeforeUpdate) {
            
        } else if (triggerAction == ucinn_ascendv2.ascend_TDTM_Runnable.Action.AfterUpdate) {
            
            updateContactNames(triggerNew, triggerOldMap);
            
        }
        return dmlWrapper;
    }
    
    
    // Create contact names after interim is completed.
    private void updateContactNames(List<ucinn_ascendv2__Interim__c> triggerNew, Map<Id, ucinn_ascendv2__Interim__c> triggerOldMap) {
        List<ucinn_ascendv2__Interim__c> interimsToProcess = new List<ucinn_ascendv2__Interim__c>();
        Map<Id, ucinn_ascendv2__Contact_Name__c> contactNamesToUpdate = new Map<Id, ucinn_ascendv2__Contact_Name__c>();
        List<ucinn_ascendv2__Contact_Name__c> contactNamesToInsert = new List<ucinn_ascendv2__Contact_Name__c>();
        Set<Id> contactIds = new Set<Id>();
        Set<String> donorIds = new Set<String>();
        Map<Id, Map<String, ucinn_ascendv2__Contact_Name__c>> contactToNameTypeToNameMap = new Map<Id, Map<String, ucinn_ascendv2__Contact_Name__c>>();
        Map<String, Id> donorToContactIdMap = new Map<String, Id>();

        for(ucinn_ascendv2__Interim__c interim : triggerNew){
            // if theres a new interim or was updated to have its name changed   
            if (interim.ucinn_ascendv2__Status__c == 'Completed'
                && (interim.ucinn_ascendv2__Contact__c != null)
                && interim.ucinn_ascendv2__External_System_ID__c != null              
                && (Trigger.isInsert || (Trigger.IsUpdate && interim.ucinn_ascendv2__Status__c != triggerOldMap.get(interim.Id).ucinn_ascendv2__Status__c ) ) ) {
                if (areNameFieldsPopulated(interim) || areNameFieldsPopulated(interim)) {
                    interimsToProcess.add(interim);

                    // collect contact ids
                    if (interim.ucinn_ascendv2__Contact__c != null) {
                        contactIds.add(interim.ucinn_ascendv2__Contact__c);
                    }
                    
                }
            }
        }

  
        
        List<ucinn_ascendv2__Contact_Name__c> contactNameList = [
            SELECT Id, ucinn_ascendv2__Contact__c, ucinn_ascendv2__First_Name__c, ucinn_ascendv2__Last_Name__c,
                   ucinn_ascendv2__Middle_Name__c, ucinn_ascendv2__Prefix__c, ucinn_ascendv2__Suffix__c, ucinn_ascendv2__Type__c, ucinn_ascendv2__Nickname__c,
                   ucinn_ascendv2__Professional_Designation__c
            FROM ucinn_ascendv2__Contact_Name__c
            WHERE ucinn_ascendv2__Contact__c IN :contactIds
        ];
        
        for (ucinn_ascendv2__Contact_Name__c contactName : contactNameList) {
            if(!contactToNameTypeToNameMap.containsKey(contactName.ucinn_ascendv2__Contact__c)) {
                contactToNameTypeToNameMap.put(contactName.ucinn_ascendv2__Contact__c, new Map<String, ucinn_ascendv2__Contact_Name__c>());
            }
            if (!contactToNameTypeToNameMap.get(contactName.ucinn_ascendv2__Contact__c).containsKey(contactName.ucinn_ascendv2__Type__c)) {
                contactToNameTypeToNameMap.get(contactName.ucinn_ascendv2__Contact__c).put(contactName.ucinn_ascendv2__Type__c, contactName);
            }
        }

        for(ucinn_ascendv2__Interim__c interim : interimsToProcess){
            Id conId = interim.ucinn_ascendv2__Contact__c;
            
            if (String.isNotBlank(interim.ucinn_ascendv2__Donor_ID__c) && interim.ucinn_ascendv2__Contact__c == null && donorToContactIdMap.containsKey(interim.ucinn_ascendv2__Donor_ID__c)) {
                conId = donorToContactIdMap.get(interim.ucinn_ascendv2__Donor_ID__c);
            }
            
            
            //  Preferred Name with Class
            if (interim.HAM_Preferred_Name_First_Name__c != null && interim.HAM_Preferred_Name_Last_Name__c != null) {
                
                ucinn_ascendv2__Contact_Name__c newContactName = new ucinn_ascendv2__Contact_Name__c(
                    ucinn_ascendv2__Contact__c = interim.ucinn_ascendv2__Contact__c,
                    ucinn_ascendv2__Type__c = 'Preferred Name with Class',
                    ucinn_ascendv2__Prefix__c = interim.HAM_Preferred_Name_Prefix__c,
                    ucinn_ascendv2__First_Name__c = interim.HAM_Preferred_Name_First_Name__c,
                    ucinn_ascendv2__Middle_Name__c = interim.HAM_Preferred_Name_Middle_Name__c,
                    ucinn_ascendv2__Last_Name__c = interim.HAM_Preferred_Name_Last_Name__c,
                    ucinn_ascendv2__Suffix__c = interim.HAM_Preferred_Name_Suffix__c,
                    ucinn_ascendv2__Nickname__c = interim.HAM_Preferred_Name_Nickname__c,
                    ucinn_ascendv2__Professional_Designation__c = interim.HAM_Preferred_Name_Pro_Designation__c
                );
                ucinn_ascendv2__Contact_Name__c oldContactName;
                if (contactToNameTypeToNameMap.containsKey(conId)) {
                    oldContactName = contactToNameTypeToNameMap.get(conId).get('Preferred Name with Class');
                }
    
                if (hasNameChanged(newContactName, oldContactName)){
                    if (oldContactName != null) {
                        oldContactName.ucinn_ascendv2__Type__c = 'Former';
                        contactNamesToUpdate.put(oldContactName.Id, oldContactName);
                     }
                     contactNamesToInsert.add(newContactName);
                 }

            }
            
          
            //  Legal
            if (interim.HAM_Legal_Name_First_Name__c!= null && interim.HAM_Legal_Name_Last_Name__c!= null) {
                
                ucinn_ascendv2__Contact_Name__c newContactName = new ucinn_ascendv2__Contact_Name__c(
                    ucinn_ascendv2__Contact__c = interim.ucinn_ascendv2__Contact__c,
                    ucinn_ascendv2__Type__c = 'Legal',
                    ucinn_ascendv2__Prefix__c = interim.HAM_Legal_Name_Prefix__c,
                    ucinn_ascendv2__First_Name__c = interim.HAM_Legal_Name_First_Name__c,
                    ucinn_ascendv2__Middle_Name__c = interim.HAM_Legal_Name_Middle_Name__c,
                    ucinn_ascendv2__Last_Name__c = interim.HAM_Legal_Name_Last_Name__c,
                    ucinn_ascendv2__Suffix__c = interim.HAM_Legal_Name_Suffix__c,
                    ucinn_ascendv2__Nickname__c = interim.HAM_Legal_Name_Nickname__c,
                    ucinn_ascendv2__Professional_Designation__c = interim.HAM_Legal_Name_Pro_Designation__c
                );
                ucinn_ascendv2__Contact_Name__c oldContactName;
                if (contactToNameTypeToNameMap.containsKey(conId)) {
                    oldContactName = contactToNameTypeToNameMap.get(conId).get('Legal');
                }
    
                if (hasNameChanged(newContactName, oldContactName)){
                    if (oldContactName != null) {
                        oldContactName.ucinn_ascendv2__Type__c = 'Former';
                        contactNamesToUpdate.put(oldContactName.Id, oldContactName);
                     }
                     contactNamesToInsert.add(newContactName);
                 }

            }
            
            //  Chosen Name
            if (interim.HAM_Chosen_Name_First_Name__c!= null && interim.HAM_Chosen_Name_Last_Name__c!= null) {
                
                ucinn_ascendv2__Contact_Name__c newContactName = new ucinn_ascendv2__Contact_Name__c(
                    ucinn_ascendv2__Contact__c = interim.ucinn_ascendv2__Contact__c,
                    ucinn_ascendv2__Type__c = 'Chosen Name',
                    ucinn_ascendv2__Prefix__c = interim.HAM_Chosen_Name_Prefix__c,
                    ucinn_ascendv2__First_Name__c = interim.HAM_Chosen_Name_First_Name__c,
                    ucinn_ascendv2__Middle_Name__c = interim.HAM_Chosen_Name_Middle_Name__c,
                    ucinn_ascendv2__Last_Name__c = interim.HAM_Chosen_Name_Last_Name__c,
                    ucinn_ascendv2__Suffix__c = interim.HAM_Chosen_Name_Suffix__c,
                    ucinn_ascendv2__Nickname__c = interim.HAM_Chosen_Name_Nickname__c,
                    ucinn_ascendv2__Professional_Designation__c = interim.HAM_Chosen_Name_Pro_Designation__c
                );
                ucinn_ascendv2__Contact_Name__c oldContactName;
                if (contactToNameTypeToNameMap.containsKey(conId)) {
                    oldContactName = contactToNameTypeToNameMap.get(conId).get('Chosen Name');
                }
    
                if (hasNameChanged(newContactName, oldContactName)){
                    if (oldContactName != null) {
                        oldContactName.ucinn_ascendv2__Type__c = 'Former';
                        contactNamesToUpdate.put(oldContactName.Id, oldContactName);
                     }
                     contactNamesToInsert.add(newContactName);
                 }

            }
            
            //  Birth
            if (interim.HAM_Birth_Name_First_Name__c!= null && interim.HAM_Birth_Name_Last_Name__c!= null) {
                
                ucinn_ascendv2__Contact_Name__c newContactName = new ucinn_ascendv2__Contact_Name__c(
                    ucinn_ascendv2__Contact__c = interim.ucinn_ascendv2__Contact__c,
                    ucinn_ascendv2__Type__c = 'Birth',
                    ucinn_ascendv2__Prefix__c = interim.HAM_Birth_Name_Prefix__c,
                    ucinn_ascendv2__First_Name__c = interim.HAM_Birth_Name_First_Name__c,
                    ucinn_ascendv2__Middle_Name__c = interim.HAM_Birth_Name_Middle_Name__c,
                    ucinn_ascendv2__Last_Name__c = interim.HAM_Birth_Name_Last_Name__c,
                    ucinn_ascendv2__Suffix__c = interim.HAM_Birth_Name_Suffix__c,
                    ucinn_ascendv2__Nickname__c = interim.HAM_Birth_Name_Nickname__c,
                    ucinn_ascendv2__Professional_Designation__c = interim.HAM_Birth_Name_Pro_Designation__c
                );
                ucinn_ascendv2__Contact_Name__c oldContactName;
                if (contactToNameTypeToNameMap.containsKey(conId)) {
                    oldContactName = contactToNameTypeToNameMap.get(conId).get('Birth');
                }
    
                if (hasNameChanged(newContactName, oldContactName)){
                    if (oldContactName != null) {
                        oldContactName.ucinn_ascendv2__Type__c = 'Former';
                        contactNamesToUpdate.put(oldContactName.Id, oldContactName);
                     }
                     contactNamesToInsert.add(newContactName);
                 }

            }
            
            
            
                
            
        }
 
         update contactNamesToUpdate.values();

        insert contactNamesToInsert;
    }
    
    
    
    private Boolean hasNameChanged(ucinn_ascendv2__Contact_Name__c newName, ucinn_ascendv2__Contact_Name__c oldName) {
        if (oldName == null && ( newName.ucinn_ascendv2__First_Name__c != null ||
                                    newName.ucinn_ascendv2__Suffix__c != null ||
                                    newName.ucinn_ascendv2__Middle_Name__c != null ||
                                    newName.ucinn_ascendv2__Prefix__c != null ||
                                    newName.ucinn_ascendv2__Last_Name__c != null ||
                                    newName.ucinn_ascendv2__Professional_Designation__c != null ||
                                    newName.ucinn_ascendv2__Nickname__c != null)) { 
            return true;
        }
/* 20240226 - Updated to only check for first/last name != NULL before looking for other field changes
        if ((newName.ucinn_ascendv2__First_Name__c != null && newName.ucinn_ascendv2__First_Name__c != oldName.ucinn_ascendv2__First_Name__c) ||           
            (newName.ucinn_ascendv2__Middle_Name__c != null && newName.ucinn_ascendv2__Middle_Name__c != oldName.ucinn_ascendv2__Middle_Name__c) ||
            (newName.ucinn_ascendv2__Prefix__c != null && newName.ucinn_ascendv2__Prefix__c != oldName.ucinn_ascendv2__Prefix__c) ||
            (newName.ucinn_ascendv2__Suffix__c != null && newName.ucinn_ascendv2__Suffix__c != oldName.ucinn_ascendv2__Suffix__c)||
            (newName.ucinn_ascendv2__Last_Name__c != null && newName.ucinn_ascendv2__Last_Name__c != oldName.ucinn_ascendv2__Last_Name__c) ||
            (newName.ucinn_ascendv2__Nickname__c!= null && newName.ucinn_ascendv2__Nickname__c!= oldName.ucinn_ascendv2__Nickname__c) ||
            (newName.ucinn_ascendv2__Professional_Designation__c!= null && newName.ucinn_ascendv2__Professional_Designation__c!= oldName.ucinn_ascendv2__Professional_Designation__c) 
           ) 
  */         
        if ((newName.ucinn_ascendv2__First_Name__c != null && newName.ucinn_ascendv2__Last_Name__c != null) &&
            (newName.ucinn_ascendv2__First_Name__c != oldName.ucinn_ascendv2__First_Name__c ||
            newName.ucinn_ascendv2__Middle_Name__c != oldName.ucinn_ascendv2__Middle_Name__c ||
            newName.ucinn_ascendv2__Prefix__c != oldName.ucinn_ascendv2__Prefix__c ||
            newName.ucinn_ascendv2__Suffix__c != oldName.ucinn_ascendv2__Suffix__c ||
            newName.ucinn_ascendv2__Last_Name__c != oldName.ucinn_ascendv2__Last_Name__c ||
            newName.ucinn_ascendv2__Nickname__c!= oldName.ucinn_ascendv2__Nickname__c ||
            newName.ucinn_ascendv2__Professional_Designation__c!= oldName.ucinn_ascendv2__Professional_Designation__c)
        )           
           {
            return true;
        }
        
        return false;
    }
    
    private Boolean areNameFieldsPopulated(ucinn_ascendv2__Interim__c interimRec) {
        if (interimRec.HAM_Preferred_Name_Last_Name__c != null ||
            interimRec.HAM_Legal_Name_Last_Name__c != null ||
            interimRec.HAM_Chosen_Name_Last_Name__c != null ||
            interimRec.HAM_Birth_Name_Last_Name__c != null
           ) {
            return true;
        }
        return false;
    
    }
    
  }