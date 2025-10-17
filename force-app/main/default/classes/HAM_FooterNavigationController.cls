/**
* @File Name : HAM_FooterNavigationController.cls
* @Description : This class is used to fetch footer details like footer nav Items, social media Items etc. from custom metadata
* @Author : Cube84 - Sachin
* @Last Modified By : Sachin
* @Last Modified On : July 2, 2025
* @Modification Log :
*==============================================================================
* Ver | Date | Author | Modification
*==============================================================================
* 1.0 | July 2, 2025 | Sachin  | Initial Version
* 1.1 | Sept 04, 2025 |  Sachin |  Done as part of Optimization
**/

public with sharing class HAM_FooterNavigationController {
	
	@AuraEnabled(cacheable=true)
    public static List<HAM_Meta_Data__mdt> getHCFooterMetaData() {
        // Query all HAM_Meta_Data__mdt records
        // Order them by HAM_Level_2__c, HAM_Order__c to ensure correct display order
        return [SELECT Id, DeveloperName, MasterLabel, HAM_Display_Icon__c, HAM_Display_Image__c, HAM_Display_Label__c, HAM_Level_1__c, HAM_Level_2__c, HAM_Order__c, HAM_Redirect_Link__c
                FROM HAM_Meta_Data__mdt WHERE HAM_Level_1__c =:HAM_ConstantsUtil.FOOTER  WITH SECURITY_ENFORCED
                ORDER BY HAM_Level_2__c, HAM_Order__c];
    }

}