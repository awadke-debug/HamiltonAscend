/**
 * Auto Generated and Deployed by the Declarative Lookup Rollup Summaries Tool package (dlrs)
 **/
@IsTest
private class dlrs_ContactTest
{
    @IsTest(SeeAllData=true)
    private static void testTrigger()
    {
        // Force the dlrs_ucinn_ascendv2_Hard_and_Sa0tTrigger to be invoked, fails the test if org config or other Apex code prevents this.
        dlrs.RollupService.testHandler(new Contact());
    }
}