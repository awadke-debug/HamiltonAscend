/**
* @File Name : HAM_MainController.cls
* @Description : Fetches 'My Links' menu items from HAM_Meta_Data__mdt.
* @Author : Cube84 - Sachin
* @Last Modified By : Sachin
* @Last Modified On : July 7, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | July 7, 2025 |  Sachin | Initial Version
* 1.1 | Sept 04, 2025 |  Sachin |  Done as part of Optimization
**/

public with sharing class HAM_MainController {
	
	/**
     * @Description : Fetches 'My Links' menu items from HAM_Meta_Data__mdt.
     * @return List<HAM_Meta_Data__mdt> List of metadata records for 'My Links'.
     */
    @AuraEnabled(cacheable=true)
    public static List<HAM_Meta_Data__mdt> getMyLinksMetaData() {
        List<HAM_Meta_Data__mdt> myLinks = [
            SELECT Id, MasterLabel, HAM_Display_Label__c, HAM_Redirect_Link__c, HAM_Order__c
            FROM HAM_Meta_Data__mdt WHERE HAM_Level_1__c = :HAM_ConstantsUtil.NAVBAR WITH SECURITY_ENFORCED 
            ORDER BY HAM_Order__c];
        return myLinks;
    }

    /**
     * @Description : Fetches Logged in user's Portal Contact Id.
     * @return Data Type: String - Portal Contact Id
     */
    @AuraEnabled(cacheable=true)
    public static string fetchLoggedInUserInfo() {
        Id currentUserId = UserInfo.getUserId();
        System.debug('currentUserId:- '+ currentUserId);
		// Query the User object to get the ContactId
        Id currentUserContactId;
        List<User> usr = [SELECT Id,Email,ContactId FROM User WHERE Id = :currentUserId WITH SECURITY_ENFORCED LIMIT 1];
        if(usr != null && usr[0].ContactId != null) {
            currentUserContactId = usr[0].ContactId;
        }
		else {
            List<User> portalUsr = [Select Id,Name,ContactId FROM User WHERE Email = :usr[0].Email AND ContactId != null AND IsActive = true WITH SECURITY_ENFORCED LIMIT 1];
            currentUserContactId = (portalUsr != null && !portalUsr.isEmpty()) ? portalUsr[0].ContactId : null;
        }
        return currentUserContactId;
    }
}