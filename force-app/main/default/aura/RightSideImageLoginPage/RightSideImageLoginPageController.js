({
    doInit : function(component, event, helper) {
        // Pick URL source
        var bgUrl = '';
        var useStatic = component.get('v.useStatic');
        var urlAttr   = component.get('v.imageUrl');

        if (useStatic === true) {
            // Get the Static Resource path
            bgUrl = $A.get('$Resource.LoginBuildingImage');
        } else if (urlAttr) {
            bgUrl = urlAttr;
        }

        // Build the full style string (avoids mixing literals and expressions in markup)
        if (bgUrl) {
            component.set('v.bgStyle', "background-image:url('" + bgUrl + "')");
        }
    }
})