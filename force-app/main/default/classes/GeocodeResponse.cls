public class GeocodeResponse{
	public list<results> results{get;set;}
	public String status{get;set;}
	public class results{
		public geometry geometry{get;set;}
		public String formatted_address{get;set;}
		public list<address_components> address_components{get;set;}
	}
	public class location{
		public String lngStr{get;set;}
		public String latStr{get;set;}
	}
	public class geometry{
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
		List<Object> addressCmps = (List<Object>)JSON.deserializeUntyped (JSON.serialize(resultMap.get('address_components')));

		res.results[0].geometry.location.latStr = String.valueOf(coordMap.get('lat'));
		res.results[0].geometry.location.lngStr = String.valueOf(coordMap.get('lng'));

		list<address_components> addressComponents = new list<address_components>();
		for (Object addCmp : addressCmps) {
			Map<String, Object> addCmpMap = (Map<String, Object>) JSON.deserializeUntyped (JSON.serialize(addCmp));

			address_components addressComponent = new address_components();
			addressComponent.short_name = String.valueOf(addCmpMap.get('short_name'));
			addressComponent.long_name = String.valueOf(addCmpMap.get('long_name'));
			List<Object> types = (list<Object>) JSON.deserializeUntyped (JSON.serialize(addCmpMap.get('types')));
			addressComponent.types = new list<String>();
			for (Object type : types) {
				addressComponent.types.add(String.valueOf(type));
			}
			addressComponents.add(addressComponent);
		}

		if (addressComponents.size() > 0) {
			res.results[0].address_components = addressComponents;
		}

		return res;
	}
}