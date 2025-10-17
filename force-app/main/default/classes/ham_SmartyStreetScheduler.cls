global class ham_SmartyStreetScheduler implements Schedulable {
    global Map<String, Set<String>> usParam;
    global Map<String, Set<String>> internationalParam;
    global Integer batchSize;
    global String whereClause= '';
    /*******************************************************************************************************
     * @description Execute schedule context.
     * @param sc Parameter type of a schedulable context.
     * @return N/A.
     */
    global void execute(SchedulableContext sc) {
        ucinn_ascendv2.ascend_UTIL_RunBatch.ascend_ADDR_VerifyAddrSmartyStreetsBatch(whereClause, usParam,internationalParam, batchSize);
    }
}