public class ContactCurrentChaptersUtility {
	@InvocableMethod(label='Build and Update Current Chapters String on Constituent')
    public static void updateCurrentChapterOnContact(List<ucinn_ascendv2__Address_Relation__c> addressRelations){
        Set<Id> contactIds = new Set<Id>();
        for(ucinn_ascendv2__Address_Relation__c ar : addressRelations){
            if(ar.ucinn_ascendv2__Contact__c != null){
            	contactIds.add(ar.ucinn_ascendv2__Contact__c);
            }
        }
        
        updateContacts(contactIds);
    }

    public static void updateContacts(Set<Id> contactIds){
        List<ucinn_ascendv2__Address_Relation__c> relatedARs = [
            SELECT Id, ucinn_ascendv2__Contact__c, HAM_Chapter__r.Name, HAM_Chapter__r.HAM_Chapter_Code__c
            FROM ucinn_ascendv2__Address_Relation__c
            WHERE HAM_Chapter__c != ''
            	AND ucinn_ascendv2__Status__c = 'Current'
            	AND ucinn_ascendv2__Contact__c IN :contactIds
            ORDER BY HAM_Chapter__r.Name ASC
        ];

        Map<Id, String> contactIdChapterCodeStringMap = new Map<Id, String>();

        for(ucinn_ascendv2__Address_Relation__c ar : relatedARs){
            String chapterNameCode = ar.HAM_Chapter__r.Name + ' - ' + ar.HAM_Chapter__r.HAM_Chapter_Code__c;
            
            if(contactIdChapterCodeStringMap.get(ar.ucinn_ascendv2__Contact__c) != null){
                String chapterCodeString = contactIdChapterCodeStringMap.get(ar.ucinn_ascendv2__Contact__c);

                if(!contactIdChapterCodeStringMap.get(ar.ucinn_ascendv2__Contact__c).contains(chapterNameCode)){
                    chapterCodeString += ', ' + chapterNameCode;
                    contactIdChapterCodeStringMap.put(ar.ucinn_ascendv2__Contact__c, chapterCodeString);
                }
            }
            else{
                contactIdChapterCodeStringMap.put(ar.ucinn_ascendv2__Contact__c, chapterNameCode);
            }

            contactIds.remove(ar.ucinn_ascendv2__Contact__c);
        }
        
        List<Contact> processedCons = new List<Contact>();
        if(contactIdChapterCodeStringMap.keySet() != null){
            for(Id contactId : contactIdChapterCodeStringMap.keySet()){
                Contact updatedCon = new Contact(
                    Id = contactId,
                    HAM_Current_Chapters__c = contactIdChapterCodeStringMap.get(contactId)
                );
            
                processedCons.add(updatedCon);
            }
        }

        if(contactIds.size() > 0){
            for(Id contactId : contactIds){
                Contact updatedContact = new Contact(
                    Id = contactId,
                    HAM_Current_Chapters__c	= ''
                );

                processedCons.add(updatedContact);
            }
        }
        
        update processedCons;
        
        Results response = new Results();
        response.updatedContacts = processedCons;
    }

    public class Results{
        @InvocableVariable(label='Updated Contacts Output')
        public List<Contact> updatedContacts;
    }
}