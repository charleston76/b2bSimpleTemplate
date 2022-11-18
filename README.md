
https://developer.salesforce.com/blogs/2019/11/content-delivery-api-to-extend-or-integrate-content
https://developer.salesforce.com/blogs/2019/11/use-the-cms-app-to-create-content

Get the content workspace I need
SELECT Id, Name, Description FROM ManagedContentSpace

With that ID get managed content existing
SELECT Id, ContentKey, AuthoredManagedContentSpaceId FROM ManagedContent WHERE AuthoredManagedContentSpaceId = '0Zu8b0000011G7XCAU'

Exemplo MCZOGM2UFPKJAQJJEWE4AH63CCPY
ID 20Y8b000000ksodEAA

List<String> haveValue = new List<String>{
'title','NameField'};
String communityId = '0DB8b00000112jDGAQ';
String contentType = '';
String managedContentIds_str = '20Y8b000000ksodEAA';
String topicNames_str = '';
String language = '';
//List<ConnectApi.ManagedContentVersion> lstReturn = ManagedContentControllerForLex.getMContent(contentType, managedContentIds_str, topicNames_str, language);
List<ConnectApi.ManagedContentVersion> lstReturn = ManagedContentControllerForLex.getMContent(contentType, managedContentIds_str, topicNames_str, language);

for (ConnectApi.ManagedContentVersion rowVersion : lstReturn){
    system.debug('rowVersion ' + rowVersion);
    system.debug('rowVersion.contentKey ' + rowVersion.contentKey);
    system.debug('rowVersion.title ' + rowVersion.title);
    system.debug('rowVersion.managedContentId ' + rowVersion.managedContentId);

	Map<String, ConnectApi.ManagedContentNodeValue> mapNodes = rowVersion.contentNodes;
    //system.debug('mapNodes ' + mapNodes);
    for (String keySet : mapNodes.keyset()){
        //system.debug('keySet ' + keySet);
            
        system.debug('mapNodes.get(keySet) ' + mapNodes.get(keySet));
        ConnectApi.ManagedContentNodeValue singleValue =  mapNodes.get(keySet);
        //system.debug('haveValue.contains(keySet) ' + haveValue.contains(keySet));
        if (! haveValue.contains(keySet)){
        	system.debug('singleValue ' + singleValue);
            //ConnectApi.ManagedContentTextNodeValue value = (ConnectApi.ManagedContentTextNodeValue) singleValue;
            ConnectApi.ManagedContentMediaSourceNodeValue value = (ConnectApi.ManagedContentMediaSourceNodeValue) singleValue;
            system.debug('value.url ' + value.url);
            //system.debug('singleValue.nodeType ' + singleValue.nodeType);
            //system.debug('singleValue.value ' + singleValue.value);
        } 

    }
}


You need to create the CMS workspace manually
    Add CMS Workspace and let the search enable (on that cms channel, click on Edit in ddl button, click Search > "Enable Search" )
    Will possible to do that /services/data/v54.0/connect/cms/delivery/channels/0ap8b0000011GJCAA2/contents/search?queryTerm=ss

https://developer.salesforce.com/docs/atlas.en-us.apexref.meta/apexref/apex_classes_connect_api.htm

sfdx force:data:tree:import -f scripts/json/productMedia.json 


Probably I can use it
    https://developer.salesforce.com/docs/atlas.en-us.chatterapi.meta/chatterapi/connect_resources_cms_contents.htm

Import the media to looks pretty
    https://help.salesforce.com/s/articleView?id=sf.cms_import_content_json.htm&type=5

# Well, here we are!

This repository is supposed to help with some necessary procedures to easily create a B2B scratch, developer, sandbox or even a production organization environment, of course, respecting some necessary steps, licenses and configurations to achieve that.


Please, take a look on this **video demo** (better in playback speed 1.5)!

[![Execution example](images/b2bSimpleTemplate.png)](https://youtu.be/NchUIRcGwAU)


Probably you may think: **from where they got those ideas?**

So simple:
1. [B2B Commerce on Lightning Experience Set Up Guide](https://resources.docs.salesforce.com/latest/latest/en-us/sfdc/pdf/b2b_standalone_setup.pdf)  a free official salesforce material;
1. [Github b2b-commerce-on-lightning-quickstart](https://github.com/forcedotcom/b2b-commerce-on-lightning-quickstart), another oficial free material provided by salesforce;
1. [Github MultiLevelNavigationMenus](https://github.com/SalesforceLabs/MultiLevelNavigationMenus), guess what? More free salesforce material;
1. Generic ideas gathered meanwhile working in different projects around the world

**Spoiler alert**: That multiLevel navigation is not implemented on this version yet... but it is very cool, take a look there.


To use this guidance, we are expecting that you are comfortable with:
* [Salesforce DX](https://trailhead.salesforce.com/content/learn/projects/quick-start-salesforce-dx) ;
* [Salesforce CLI features](https://developer.salesforce.com/tools/sfdxcli), and;
* [Scratch Orgs](https://developer.salesforce.com/docs/atlas.en-us.sfdx_dev.meta/sfdx_dev/sfdx_dev_scratch_orgs.htm)
* [Git CLI](https://git-scm.com/book/en/v2/Getting-Started-The-Command-Line) (ok, we will not use it here, but it will help you to know).

## First things first: Local environment

In your workstation, you need to have at least the following softwares installed:

* Salesforce CLI
* Salesforce [SFDX Commerce Plugin](https://github.com/forcedotcom/sfdx-1commerce-plugin)
* Visual Studio Code with the pluggins below:
    * GitLens;
    * Salesforce Extension Pack;
    * Salesforce CLI Integration;
    * Salesforce Package.xml Generator Extension for VS Code (over again, we'll not use it here, but it will help you to know);

## Setup

The scripts will be executed in the "bash terminal".

All deployments and configurations will be applied in your local **default organization**.
To get sure about which is yours, please run the command below:

    sfdx force:org:list --all
    
![Org List](images/sfdx-org-list.png "sfdx force:org:list")

* The "D" sign shows your devHub org;
* The "U" sign shows your *local default organization* (in that one the things will be implemented);

So, with that explained, let's get down to business!

You use the things here in the following ways:
1. [Scratch orgs with devHub already enabled](#scratch-orgs-with-devHub-already-enabled);
1. [Scratch org configuration](#scratch-org-configuration) if you need do that step by step to have that;
1. [Other org types](#other-org-types) do more, get more;


### Scratch orgs with devHub already enabled

If you already are working with scratch orgs and have all configured and defined in your main org (develop, production, etc), you just need to run the command below:

* ./scripts/bash/createScratchDigitalExpSetupStore.sh [YOUR_SCRATCH_NAME_HERE] [YOUR_SHOP_NAME_HERE]
* Example:
    ```
    ./scripts/bash/createScratchDigitalExpSetupStore.sh tmpNew Shop
    ```
    
That will do all the configuration needed to achieve:
* Create the scratch org;
* Create the digital experience;
* Create the store front (with sample products, buyer group, entitlement policy, etc);

### Scratch org configuration


To work with Scratch orgs, we supposed that, you need to to the steps below:
1. [Enable Dev Hub Features in Your Org](https://help.salesforce.com/s/articleView?id=sf.sfdx_setup_enable_devhub.htm&type=5) (it could be trail, develop or even a productive one).
1. Authorize that Devhub org (please, see the **All Organizations** under "[Authorize the organization](#authorize-the-organization) - Example to authorize set a devhubuser" section);
1. Create your scratch org based on the project file
    * sfdx force:org:create -f config/project-scratch-def.json -a [YOUR_ALIAS_HERE] -d 1
    * That will create the scratch org with a lot of features enable, please take a look on [that project file](config/project-scratch-def.json) to get familiar
    * The "-d" parameter, tells the amount of days that you want your scratch organization last
    * Example:
        ```
        sfdx force:org:create -f config/project-scratch-def.json -a tmpB2b -d 1
        ```
    * Set that as you default organization:
        ```
        sfdx force:config:set defaultusername=tmpB2b
        ```
1. Deploy the things with the script (please see the [Scripting deploying](#All-org-script-deploy) under "Deploying the additional settings" section);
    * ./scripts/bash/createDigitalExpSetupStore.sh [YOUR_SHOP_NAME_HERE]
    * Example:
    ```
    ./scripts/bash/createDigitalExpSetupStore.sh Shop
    ```

### Other org types

Well, as I told before, we still working on that... 
Coming soon new updates, stay tuned

### All Organizations

* #### Authorize the organization
    * You can do that pressing the "ctrl + shift + p" keys in VSCode, or;
    * Use the commands below:
        * Example to authorize set a devhubuser:
        * sfdx force:auth:web:login -a [YOUR_ALIAS_HERE] --setdefaultdevhubusername --setdefaultusername 
            ```
            sfdx force:auth:web:login -a b2bSimplesSampe --setdefaultdevhubusername --setdefaultusername 
            ```
        * You also can set the default devhubuser after the authorization, like that:
            ```
            sfdx force:config:set defaultdevhubusername=[YOUR_ALIAS_HERE OR USER_NAME_HERE]
            ```
        * Example to authorize a sandbox org:
            ```
            sfdx auth:web:login -a [YOUR_ALIAS_HERE] -s -r https://test.salesforce.com
            ```        
        * Example to authorize a trial, develop or production org:
            ```
            sfdx auth:web:login -a tmpOrg -s 
            ```        
        * If you do not want to set that org as your default to the project, just suppress the parameter "-s"

* #### Deploying the additional settings
    * This configuration is automatically applied through the **"createDigitalExpSetupStore.sh"** script file
    * Some things like Currency, Order, Order management, etc,  needs to be enable with metadata changes, to do that, we have created the [manifest/package-01additionalSettings.xml](manifest/package-01additionalSettings.xml) file.

        Please, feel free to uncomment the necessary setting you may need in your deployment.
    * With the things do you need, you can deploy into you environment with the following commands:
        1. rm -rf Deploy (To clean the deployment folder);
        1. sfdx force:source:convert -r force-app/ -d Deploy -x MANIFEST_FILE.xml (To convert the source in metadata);
        1. sfdx force:mdapi:deploy -d Deploy/ -w -1 (To deploy the things there);
        1. Example
            ```
            rm -rf Deploy
            sfdx force:source:convert -r force-app/ -d Deploy -x manifest/package-01additionalSettings.xml
            sfdx force:mdapi:deploy -d Deploy/ -w -1 
            ```        

