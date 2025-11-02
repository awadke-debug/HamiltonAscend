public class HAM_EncryptionUtil {
    @AuraEnabled(cacheable=true)
    public static string EncryptId(string EncryptId){
       return EncodingUtil.urlEncode(EncodingUtil.base64Encode(Blob.valueOf(EncryptId)),'UTF-8');
    }
}