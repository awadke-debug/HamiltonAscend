public with sharing class AdvanceFilterParam {
    @AuraEnabled public String fieldName { get; set; }
    @AuraEnabled public String fieldValue { get; set; }
    @AuraEnabled public String operator { get; set; }
    @AuraEnabled public String fieldType { get; set; }
    @AuraEnabled public Boolean isRange { get; set; }
    @AuraEnabled public String lookupFieldApiName { get; set; }

    @AuraEnabled public String fieldLabel { get; set; }
    @AuraEnabled public String owner { get; set; }
    @AuraEnabled public String key { get; set; }

    public AdvanceFilterParam(){}

    public String getFilterItem(Integer i, Map<String, Object> bindVars) {
        String lookupPart = String.isBlank(this.lookupFieldApiName) ? '' : this.lookupFieldApiName + '.';

        if ('MULTIPICKLIST' == this.fieldType) {
            return lookupPart + this.fieldName + ' ' + this.operator + ' (\'' + String.join(this.fieldValue.split(';'), '\',\'') + '\')';
        }

        if (this.isRange != null && this.isRange) {
            String [] values = fieldValue.split('-');
            
            if (values.size() == 2 && !fieldValue.startsWith('-')) {
                return String.format('({0} >= {1} AND {0} <= {2})', new List<Object>{
                    lookupPart + this.fieldName, 
                    values[0], 
                    values[1]});
            } else {
                return String.format('{0} {1} {2}', new List<String>{
                    lookupPart + this.fieldName,
                    fieldValue.startsWith('-') ? ' <= ' : ' >= ',
                    fieldValue.startsWith('-') ? values[1] : values[0]});
            }
        }

        return lookupPart + this.fieldName + ' ' + this.operator + ' :' + buildBindVars(this.fieldValue, Schema.DisplayType.valueOf(fieldType), bindVars, i);
    }

    public static String buildBindVars(String value, Schema.DisplayType fieldType, Map<String , Object> bindVars, Integer j) {
        Object qBind;
        String placeHolder = 'arg' + j;
        if(fieldType == Schema.DisplayType.BOOLEAN) {
            qBind = Boolean.valueOf(value);
        } else if(fieldType == Schema.DisplayType.DATETIME) {
            qBind = DateTime.parse(value);
        } else if(fieldType == Schema.DisplayType.DATE) {
            qBind = Date.parse(value);
        } else if(fieldType == Schema.DisplayType.INTEGER) {
            qBind = Integer.valueOf(value);
        } else if(fieldType == Schema.DisplayType.DOUBLE) {
            qBind = Double.valueOf(value);
        } else if(fieldType == Schema.DisplayType.CURRENCY) {
            qBind = Decimal.valueOf(value);
        } else {
            qBind = value;
        }

        if (qBind != null) {
            bindVars.put(placeHolder, qBind);
        }

        return placeHolder;
    }
}