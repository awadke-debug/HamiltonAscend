public with sharing class AdvanceFilterPicklistOptionsDto implements Comparable {
    @AuraEnabled public String label {get; set;}
    @AuraEnabled public String value {get; set;}
    @AuraEnabled public Boolean isRange {get; set;}
    @AuraEnabled public Integer order {get; set;}

    public AdvanceFilterPicklistOptionsDto(String label, String value, Boolean isRange, Integer order) {
        this.label = label;
        this.value = value;
        this.isRange = isRange;
        this.order = order;
    }

    public Integer compareTo(Object compareTo) {
        AdvanceFilterPicklistOptionsDto compareToOpt = (AdvanceFilterPicklistOptionsDto)compareTo;

        if (order == compareToOpt.order) return 0;
        if (order > compareToOpt.order) return 1;
        return -1;
    }

    /*
    public Integer compareTo(Object compareTo) {
        AdvanceFilterPicklistOptionsDto compareToOpt = (AdvanceFilterPicklistOptionsDto)compareTo;

        if (getDecimalValue(value) == null && getDecimalValue(compareToOpt.value) == null) {
            return value.compareTo(compareToOpt.label);
        }

        if (getDecimalValue(value) == null && getDecimalValue(compareToOpt.value) != null) {
            return -1;
        }   

        if (getDecimalValue(value) != null && getDecimalValue(compareToOpt.value) == null) {
            return 1;
        }   

        if (getDecimalValue(value) == getDecimalValue(compareToOpt.value)) return 0;
        if (getDecimalValue(value) > getDecimalValue(compareToOpt.value)) return 1;
        return -1;
    }

    private Decimal getDecimalValue(String input) {
        if (input == null) {
            return 0;
        }

        List<String> inputArr = input.split('-');
        String endRange;
        if (inputArr.size() == 2) {
            endRange = inputArr[1];
        } else {
            endRange = inputArr[0];
        }

        Boolean matches = false;
        if (Pattern.matches('^\\$(?!0\\.00)\\d{1,3}(,\\d{3})*(\\.\\d\\d)?$', endRange) || Pattern.matches('(\\d*-\\d+|\\d+-\\d*)', endRange)) {
            matches = true;
        }

        if (matches) {
            Pattern p = Pattern.compile('[^0-9.-]+');
            String cleanedString = p.matcher(endRange).replaceAll('');
            Decimal currencyDecimal = Decimal.valueOf(cleanedString);
            return currencyDecimal;
        }

        return null;
    }*/
    
}