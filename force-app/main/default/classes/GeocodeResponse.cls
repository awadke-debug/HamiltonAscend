public class GeocodeResponse{
	public list<results> results{get;set;}
	public String status{get;set;}
	public class viewport{
		public southwest southwest{get;set;}
		public northeast northeast{get;set;}
	}
	public class southwest{
		public Decimal lng{get;set;}
		public Decimal lat{get;set;}
	}
	public class results{
		public list<navigation_points> navigation_points{get;set;}
		public String place_id{get;set;}
		public geometry geometry{get;set;}
		public plus_code plus_code{get;set;}
		public String formatted_address{get;set;}
		public list<String> types{get;set;}
		public list<address_components> address_components{get;set;}
	}
	public class plus_code{
		public String compound_code{get;set;}
		public String global_code{get;set;}
	}
	public class northeast{
		public Decimal lng{get;set;}
		public Decimal lat{get;set;}
	}
	public class navigation_points{
		public location location{get;set;}
	}
	public class location{
		public Decimal longitude{get;set;}
		public Decimal latitude{get;set;}
		public Decimal lng{get;set;}
		public Decimal lat{get;set;}
		public String lngStr{get;set;}
		public String latStr{get;set;}
	}
	public class geometry{
		public viewport viewport{get;set;}
		public String location_type{get;set;}
		public location location{get;set;}
	}
	public class address_components{
		public list<String> types{get;set;}
		public String short_name{get;set;}
		public String long_name{get;set;}
	}

    public static GeocodeResponse parse(String jsonStr){
		GeocodeResponse res = (GeocodeResponse) System.JSON.deserialize(jsonStr, GeocodeResponse.class);

		Map<String, Object> geoCodeMap = (Map<String, Object>) JSON.deserializeUntyped (jsonStr);
		List<Object> results = (List<Object>) geoCodeMap.get('results');
		Map<String, Object> resultMap = (Map<String, Object>) JSON.deserializeUntyped (JSON.serialize(results[0]));
		Map<String, Object> geoMap = (Map<String, Object>) JSON.deserializeUntyped (JSON.serialize(resultMap.get('geometry')));
		Map<String, Object> coordMap = (Map<String, Object>) JSON.deserializeUntyped (JSON.serialize(geoMap.get('location')));

		res.results[0].geometry.location.latStr = String.valueOf(coordMap.get('lat'));
		res.results[0].geometry.location.lngStr = String.valueOf(coordMap.get('lng'));
		System.debug(res.results[0].geometry);
		System.debug(res.results[0].geometry.location);

		return res;
	}

    /*
    static testMethod void testParse() {
		String json=		'{"results":[{"address_components":[{"long_name":"1600","short_name":"1600","types":["street_number"]},{"long_name":"Amphitheatre Parkway","short_name":"Amphitheatre Pkwy","types":["route"]},{"long_name":"Mountain View","short_name":"Mountain View","types":["locality","political"]},{"long_name":"Santa Clara County","short_name":"Santa Clara County","types":["administrative_area_level_2","political"]},{"long_name":"California","short_name":"CA","types":["administrative_area_level_1","political"]},{"long_name":"United States","short_name":"US","types":["country","political"]},{"long_name":"94043","short_name":"94043","types":["postal_code"]},{"long_name":"1351","short_name":"1351","types":["postal_code_suffix"]}],"formatted_address":"1600 Amphitheatre Pkwy, Mountain View, CA 94043, USA","geometry":{"location":{"lat":37.4220094,"lng":-122.0847516},"location_type":"ROOFTOP","viewport":{"northeast":{"lat":37.4233580302915,"lng":-122.0827769697085},"southwest":{"lat":37.4206600697085,"lng":-122.0854749302915}}},"navigation_points":[{"location":{"latitude":37.4209982,"longitude":-122.082964}},{"location":{"latitude":37.4211397,"longitude":-122.0852956}},{"location":{"latitude":37.4229215,"longitude":-122.0834223}},{"location":{"latitude":37.4230178,"longitude":-122.0850192}}],"place_id":"ChIJ09H2YwK6j4ARoF7qfCBxhB8","plus_code":{"compound_code":"CWC8+R3 Mountain View, CA","global_code":"849VCWC8+R3"},"types":["street_address"]}],"status":"OK"}';
		GeocodeResponse obj = parse(json);
		System.assert(obj != null);
	}
    */
}