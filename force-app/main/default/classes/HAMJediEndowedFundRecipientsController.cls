public with sharing class HAMJediEndowedFundRecipientsController {

    @AuraEnabled(cacheable=true)
    public static List<FundWithBeneficiaries> getFundsWithBeneficiaries(String contactId) {
        try {
            // Get all Designation Stewardships for the Contact with filters
            List<ucinn_ascendv2__Designation_Stewardship__c> stewardships = [
                SELECT Id,
                       Name,
                       ucinn_ascendv2__Designation__c,
                       ucinn_ascendv2__Designation__r.Name,
                       ucinn_ascendv2__Designation__r.ucinn_ascendv2__Fund_Name__c,
                       ucinn_ascendv2__Status__c,
                       HAM_Reporting_Type__c
                FROM ucinn_ascendv2__Designation_Stewardship__c
                WHERE ucinn_ascendv2__Contact_Stewardee__c = :contactId
                AND ucinn_ascendv2__Status__c = 'Current'
                AND HAM_Reporting_Type__c IN ('Comprehensive', 'Financial Only')
                AND ucinn_ascendv2__Designation__r.RecordTypeId = '012U1000000lheLIAQ'
                AND ucinn_ascendv2__Designation__r.HAM_Fund_Status__c != 'Inactive'
                ORDER BY ucinn_ascendv2__Designation__r.ucinn_ascendv2__Fund_Name__c
            ];

            // Collect all Designation IDs
            Set<Id> designationIds = new Set<Id>();
            for (ucinn_ascendv2__Designation_Stewardship__c stew : stewardships) {
                designationIds.add(stew.ucinn_ascendv2__Designation__c);
            }

            // Get all Beneficiaries for these Designations
            List<ucinn_ascendv2__Designation_Beneficiary__c> allBeneficiaries = [
                SELECT Id,
                       Name,
                       ucinn_ascendv2__Designation__c,
                       HAM_Sort_Fiscal_Year__c,
                       HAM_Award_Session__c,
                       ucinn_ascendv2__Contact__c,
                       ucinn_ascendv2__Contact__r.Name,
                       ucinn_ascendv2__Type__c,
                       HAM_Anonymous__c
                FROM ucinn_ascendv2__Designation_Beneficiary__c
                WHERE ucinn_ascendv2__Designation__c IN :designationIds
                ORDER BY ucinn_ascendv2__Designation__c,
                         HAM_Sort_Fiscal_Year__c DESC NULLS LAST,
                         ucinn_ascendv2__Contact__r.Name ASC,
                         HAM_Award_Session__c ASC NULLS LAST
            ];

            // Group beneficiaries by Designation
            Map<Id, List<ucinn_ascendv2__Designation_Beneficiary__c>> beneficiariesByDesignation = new Map<Id, List<ucinn_ascendv2__Designation_Beneficiary__c>>();
            for (ucinn_ascendv2__Designation_Beneficiary__c ben : allBeneficiaries) {
                if (!beneficiariesByDesignation.containsKey(ben.ucinn_ascendv2__Designation__c)) {
                    beneficiariesByDesignation.put(ben.ucinn_ascendv2__Designation__c, new List<ucinn_ascendv2__Designation_Beneficiary__c>());
                }
                beneficiariesByDesignation.get(ben.ucinn_ascendv2__Designation__c).add(ben);
            }

            // Build response
            List<FundWithBeneficiaries> result = new List<FundWithBeneficiaries>();
            for (ucinn_ascendv2__Designation_Stewardship__c stew : stewardships) {
                FundWithBeneficiaries fund = new FundWithBeneficiaries();
                fund.stewardshipId = stew.Id;
                fund.stewardshipName = stew.Name;
                fund.designationId = stew.ucinn_ascendv2__Designation__c;
                fund.fundName = stew.ucinn_ascendv2__Designation__r.ucinn_ascendv2__Fund_Name__c;
                fund.beneficiaries = beneficiariesByDesignation.containsKey(stew.ucinn_ascendv2__Designation__c)
                    ? beneficiariesByDesignation.get(stew.ucinn_ascendv2__Designation__c)
                    : new List<ucinn_ascendv2__Designation_Beneficiary__c>();
                result.add(fund);
            }

            return result;
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching funds and beneficiaries: ' + e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<FundWithGroupedBeneficiaries> getFundsWithGroupedBeneficiaries(String contactId) {
        try {
            // Get all Designation Stewardships for the Contact with filters
            List<ucinn_ascendv2__Designation_Stewardship__c> stewardships = [
                SELECT Id,
                       Name,
                       ucinn_ascendv2__Designation__c,
                       ucinn_ascendv2__Designation__r.Name,
                       ucinn_ascendv2__Designation__r.ucinn_ascendv2__Fund_Name__c,
                       ucinn_ascendv2__Status__c,
                       HAM_Reporting_Type__c
                FROM ucinn_ascendv2__Designation_Stewardship__c
                WHERE ucinn_ascendv2__Contact_Stewardee__c = :contactId
                AND ucinn_ascendv2__Status__c = 'Current'
                AND HAM_Reporting_Type__c IN ('Comprehensive', 'Financial Only')
                AND ucinn_ascendv2__Designation__r.RecordTypeId = '012U1000000lheLIAQ'
                AND ucinn_ascendv2__Designation__r.HAM_Fund_Status__c != 'Inactive'
                ORDER BY ucinn_ascendv2__Designation__r.ucinn_ascendv2__Fund_Name__c
            ];

            // Collect all Designation IDs
            Set<Id> designationIds = new Set<Id>();
            for (ucinn_ascendv2__Designation_Stewardship__c stew : stewardships) {
                designationIds.add(stew.ucinn_ascendv2__Designation__c);
            }

            // Get all Beneficiaries for these Designations
            List<ucinn_ascendv2__Designation_Beneficiary__c> allBeneficiaries = [
                SELECT Id,
                       Name,
                       ucinn_ascendv2__Designation__c,
                       HAM_Sort_Fiscal_Year__c,
                       HAM_Award_Session__c,
                       ucinn_ascendv2__Contact__c,
                       ucinn_ascendv2__Contact__r.Name,
                       ucinn_ascendv2__Type__c,
                       HAM_Anonymous__c
                FROM ucinn_ascendv2__Designation_Beneficiary__c
                WHERE ucinn_ascendv2__Designation__c IN :designationIds
                ORDER BY ucinn_ascendv2__Designation__c,
                         HAM_Sort_Fiscal_Year__c DESC NULLS LAST,
                         ucinn_ascendv2__Contact__r.Name ASC,
                         HAM_Award_Session__c ASC NULLS LAST
            ];

            // Group beneficiaries by Designation, then by Year + Contact (deduplication)
            Map<Id, List<GroupedBeneficiary>> groupedBeneficiariesByDesignation = new Map<Id, List<GroupedBeneficiary>>();

            for (ucinn_ascendv2__Designation_Beneficiary__c ben : allBeneficiaries) {
                Id designationId = ben.ucinn_ascendv2__Designation__c;

                // Initialize designation list if not exists
                if (!groupedBeneficiariesByDesignation.containsKey(designationId)) {
                    groupedBeneficiariesByDesignation.put(designationId, new List<GroupedBeneficiary>());
                }

                List<GroupedBeneficiary> beneficiariesForDesignation = groupedBeneficiariesByDesignation.get(designationId);

                // Create unique key: Year + Contact
                String groupKey = String.valueOf(ben.HAM_Sort_Fiscal_Year__c) + '_' + ben.ucinn_ascendv2__Contact__c;

                // Find existing group or create new one
                GroupedBeneficiary existingGroup = null;
                for (GroupedBeneficiary gb : beneficiariesForDesignation) {
                    if (gb.groupKey == groupKey) {
                        existingGroup = gb;
                        break;
                    }
                }

                if (existingGroup != null) {
                    // Add semester to existing group
                    if (String.isNotBlank(ben.HAM_Award_Session__c) && !existingGroup.semesters.contains(ben.HAM_Award_Session__c)) {
                        existingGroup.semesters.add(ben.HAM_Award_Session__c);
                    }
                    // Apply OR logic to anonymous: if any is true, set to true
                    if (ben.HAM_Anonymous__c == true) {
                        existingGroup.isAnonymous = true;
                    }
                } else {
                    // Create new group
                    GroupedBeneficiary newGroup = new GroupedBeneficiary();
                    newGroup.groupKey = groupKey;
                    newGroup.Id = ben.Id; // Use first beneficiary ID
                    newGroup.fiscalYear = ben.HAM_Sort_Fiscal_Year__c;
                    newGroup.contactId = ben.ucinn_ascendv2__Contact__c;
                    newGroup.contactName = ben.ucinn_ascendv2__Contact__r.Name;
                    newGroup.semesters = new List<String>();
                    if (String.isNotBlank(ben.HAM_Award_Session__c)) {
                        newGroup.semesters.add(ben.HAM_Award_Session__c);
                    }
                    newGroup.isAnonymous = (ben.HAM_Anonymous__c == true);
                    beneficiariesForDesignation.add(newGroup);
                }
            }

            // Build response
            List<FundWithGroupedBeneficiaries> result = new List<FundWithGroupedBeneficiaries>();
            for (ucinn_ascendv2__Designation_Stewardship__c stew : stewardships) {
                FundWithGroupedBeneficiaries fund = new FundWithGroupedBeneficiaries();
                fund.stewardshipId = stew.Id;
                fund.stewardshipName = stew.Name;
                fund.designationId = stew.ucinn_ascendv2__Designation__c;
                fund.fundName = stew.ucinn_ascendv2__Designation__r.ucinn_ascendv2__Fund_Name__c;
                fund.beneficiaries = groupedBeneficiariesByDesignation.containsKey(stew.ucinn_ascendv2__Designation__c)
                    ? groupedBeneficiariesByDesignation.get(stew.ucinn_ascendv2__Designation__c)
                    : new List<GroupedBeneficiary>();
                result.add(fund);
            }

            return result;
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching funds with grouped beneficiaries: ' + e.getMessage());
        }
    }

    public class FundWithBeneficiaries {
        @AuraEnabled public String stewardshipId;
        @AuraEnabled public String stewardshipName;
        @AuraEnabled public String designationId;
        @AuraEnabled public String fundName;
        @AuraEnabled public List<ucinn_ascendv2__Designation_Beneficiary__c> beneficiaries;
    }

    public class FundWithGroupedBeneficiaries {
        @AuraEnabled public String stewardshipId;
        @AuraEnabled public String stewardshipName;
        @AuraEnabled public String designationId;
        @AuraEnabled public String fundName;
        @AuraEnabled public List<GroupedBeneficiary> beneficiaries;
    }

    public class GroupedBeneficiary {
        @AuraEnabled public String Id;
        @AuraEnabled public String groupKey; // Internal use for grouping
        @AuraEnabled public Decimal fiscalYear;
        @AuraEnabled public String contactId;
        @AuraEnabled public String contactName;
        @AuraEnabled public List<String> semesters;
        @AuraEnabled public Boolean isAnonymous;

        // Computed field for display (comma-separated semesters)
        @AuraEnabled
        public String getSemestersDisplay() {
            if (semesters == null || semesters.isEmpty()) {
                return '';
            }
            return String.join(semesters, ', ');
        }
    }
}