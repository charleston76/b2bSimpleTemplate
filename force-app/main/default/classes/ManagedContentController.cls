public with sharing class ManagedContentController {
    @AuraEnabled
   public static List<ConnectApi.ManagedContentVersion> getMContent(String communityId, String contentType, String managedContentIds_str, String topicNames_str, String language) {
       List<String> contentIds = new List<String>();
       List<String> topicNames = new List<String>();
       try{
           if(managedContentIds_str != null && !String.isEmpty(managedContentIds_str)){
               contentIds = managedContentIds_str.split(',',-1);
           }
          
           for(Integer i=0;i<contentIds.size();i++){
               contentIds.set(i,contentIds.get(i).trim());
           }
           
           if(topicNames_str != null && !String.isEmpty(topicNames_str)){
               topicNames = topicNames_str.split(',',-1); 
           }
           
           for(Integer i=0;i<topicNames.size();i++){
               topicNames.set(i,topicNames.get(i).trim());
           }
           
           language = 'en_US';
           ConnectApi.ManagedContentVersionCollection contentCollection = null;
           contentCollection = ConnectApi.ManagedContent.getManagedContentByTopicsAndIds(communityId, contentIds, topicNames, 0, 25, language, contentType);
           
           return contentCollection.items;
       }
       catch(ConnectApi.ConnectApiException e){
           System.debug('Error Message : '+e);
           ApexPages.addMessages(e);
           List<ConnectApi.ManagedContentVersion> mcvList = new List<ConnectApi.ManagedContentVersion>();
           return mcvList;
       }
   }
}
