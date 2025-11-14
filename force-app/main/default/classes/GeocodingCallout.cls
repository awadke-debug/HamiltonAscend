public with sharing class GeocodingCallout {
    public static final String NAME_CRED = 'callout:Geocoding_API_Named_Cred';

    public GeocodingCallout() {

    }

    public GeocodeResponse getCoordinates(String addressParam) {
        String encodedAddress = EncodingUtil.urlEncode(addressParam, 'UTF-8');
        HttpRequest req = new HttpRequest();
        req.setEndpoint(NAME_CRED + '?address='+ encodedAddress + '&components=country:US&key=' + getApiKey());
        req.setMethod('GET');

        Http http = new Http();
        HTTPResponse res = http.send(req);
        System.debug(res.getBody());

        String jsonStr = res.getBody();

        GeocodeResponse geoRes = GeocodeResponse.parse(jsonStr);
        try {
            GeocodeResponse.results result = geoRes.results[0];

        } catch (ListException lex) {
            System.debug('@@ListException message: ' + lex.getMessage());
            return null;
        } catch (Exception ex) {
            System.debug('@@Exception message: ' + ex.getMessage());
            return null;
        }

        return geoRes;
    }

    private static String getApiKey() {
        Google_Map_API_Key__c googleKey = Google_Map_API_Key__c.getOrgDefaults();
        return googleKey.Key__c;
    }
}