# Well, here we are!

This repository is supposed to help with some necessary procedures to easily create a B2B scratch, developer, sandbox or even a production organization environment, of course, respecting some necessary steps to achieve that.

Probably you may think: from where they got those ideas?

So simple:
1. The b2b sample was got from this free salesforce material:
[b2b-commerce-on-lightning-quickstart](https://github.com/forcedotcom/b2b-commerce-on-lightning-quickstart)
1. The multilevel navigation menu was got from this free salesforce material:
[MultiLevelNavigationMenus](https://github.com/SalesforceLabs/MultiLevelNavigationMenus)

<strong>Spoiler alert</strong>: That multiLevel navigation is not implemented on this version yet... but is very cool, take a look there.


To use this guidance, we are expecting that you are comfortable with:
* [Salesforce DX](https://trailhead.salesforce.com/content/learn/projects/quick-start-salesforce-dx) ;
* [Salesforce CLI features](https://developer.salesforce.com/tools/sfdxcli), and;
* [Git CLI](https://git-scm.com/book/en/v2/Getting-Started-The-Command-Line) (ok, we also not will use it here, but it will help you to know).


## First things first: Local environment

In your workstation, you need to have the following softwares installed:

* Salesforce CLI
* Visual Studio Code with the pluggins below:
    * GitLens;
    * Salesforce Extension Pack;
    * Salesforce CLI Integration;
    * Salesforce Package.xml Generator Extension for VS Code (over again, we'll not use it here, but it will help you to know);

## Setup

### Scratch orgs

To work with Scratch orgs, you will need:
1. [Enable Dev Hub Features in Your Org](https://help.salesforce.com/s/articleView?id=sf.sfdx_setup_enable_devhub.htm&type=5) (it could be trail, develop or even a productive one).
1. Authorize that Devhub org (please, see the [All Organizations](#allorg) under "Authorize the organization - Example to authorize set a devhubuser" section);
1. Create your scratch org based on the project file
    * sfdx force:org:create -f config/project-scratch-def.json -a [YOUR_ALIAS_HERE] -d 30
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
1. Deploy the necessary metadada before push (please see the [All Organizations](#allorg) under "Deploying the additional settings" section);
1. Just push you code, and be happy!
    ```
    sfdx force:source:push
    ```


### [All Organizations](#allorg)

* Authorize the organization
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
            sfdx auth:web:login -a [YOUR_ALIAS_HERE] -s 
            ```        
        * If you do not want to set that org as your default to the project, just suppress the parameter "-s"

* Deploying the additional settings
    * Some things like Currency, Order, Order management, etc,  needs to be enable with metadata changes, to do that, we have created the [manifest/package-AdditionalSettings.xml](manifest/package-AdditionalSettings.xml) file.

        Please, feel free to uncomment the necessary setting you may need in your deployment.
    * With the things do you need, you can deploy into you environment with the following commands:
        1. rm -rf Deploy (To clean the deployment folder);
        1. sfdx force:source:convert -r force-app/ -d Deploy -x MANIFEST_FILE.xml (To convert the source in metadata);
        1. sfdx force:mdapi:deploy -u [YOUR_ALIAS_HERE] -d Deploy/ -w -1 (To deploy the things there);
        1. Example
            ```
            rm -rf Deploy
            sfdx force:source:convert -r force-app/ -d Deploy -x manifest/package-AdditionalSettings.xml
            sfdx force:mdapi:deploy -u tmpB2b -d Deploy/ -w -1 
            ```        




<!-- 1. If you haven't already, clone this repository.
1. If you haven't already, create a B2B Commerce org.
    Optional: Use the included [project-scratch-def.json](config/project-scratch-def.json), e.g. `sfdx force:org:create -f ./config/project-scratch-def.json`
1. Push the source code in this repository to the new org, e.g. `sfdx force:source:push -u <org username>`.
1. Grant permissions to the APEX class (do this only once):

    1. Login to the org, e.g., `sfdx force:org:open -u <org username>`.
    1. Go to Setup -> Custom Code -> APEX Classes.
    1. On the B2BGetInfo class, click "Security".
    1. Assign the buyer user profile(s) or other user profiles that will use your components.
    1. Click Save.
    1. Repeat steps iii-v for B2BCartControllerSample class. -->

<!-- ## Usage

1. Create a Commerce store.
1. Go to the Commerce app, and select the store.
1. Open Experience Builder.
1. Go to the Product Detail page.
1. Open the Builder component palette, and add the "B2B Custom Product Details" component to the page.
1. Go to the Category Detail page (repeat the next step for the Search Results page).
1. Open the Builder component palette and add the "B2B Custom Results Layout" component to the page.
1. Publish the store.

## A note on communicating between components in B2B Commerce for Lightning

As of the Winter ’21 release, Lightning Message Service (LMS) isn’t available in B2B Commerce for Lightning. As an alternative method for communication between components, these samples use the [publish-subscribe (pubsub) module](https://developer.salesforce.com/docs/component-library/documentation/en/lwc/lwc.use_message_channel_considerations).
In a pubsub pattern, one component publishes an event while other components subscribe to receive (and handle) the event. Every component that subscribes to the event receives the event.
When LMS is supported in B2B Commerce for Lightning (Safe Harbor), we’ll update these samples to use LMS.

## Optional - Setup Demo External API Integrations

The productDetails component demonstrates how to call an external API. In our example, we call a [Demo Inventory Manager](https://inventorymanagerdemo.herokuapp.com/api/inventory/) External Service, which returns a product’s availability as a simple Boolean value. To enable this demo service in your org:

1. From Setup, enter Remote Site Settings in the Quick Find box, then select Remote Site Settings.
    This page displays a list of any remote sites that are already registered. It provides additional information about each site, including remote site name and URL.
1. Click New Remote Site.
1. For the Remote Site Name, enter Demo Inventory Manager.
1. For the remote site URL, enter https://inventorymanagerdemo.herokuapp.com.
1. Optionally, enter a site description.
1. Click Save.

## Search-specific Steps (to use Named Credentials)

Connect APIs for search don't have Apex enabled yet. So we can call those Connect APIs only through REST from Apex classes. For security reasons, the Lightning Component framework places restrictions on making API calls from JavaScript. 

* To call third-party APIs from your component’s JavaScript, add the API endpoint as a CSP Trusted Site.
* To call Salesforce APIs, make the API calls from your component’s Apex controller. Use a named credential to authenticate to Salesforce. (Documentation is [here](https://developer.salesforce.com/docs/atlas.en-us.lightning.meta/lightning/apex_api_calls.htm) and [here](https://developer.salesforce.com/docs/atlas.en-us.228.0.apexcode.meta/apexcode/apex_callouts_named_credentials.htm).)
* Create a Named Credential callout. The steps are documented [here](/examples/lwc/docs/NamedCredentials.md).

## Known Issues

### Flow Debugging

Debugging with the flow typically requires impersonating a buyer [Run flow as another user](https://help.salesforce.com/articleView?id=release-notes.rn_ls_debug_flow_as_another_user.htm&type=5&release=232). However, the custom payment component installed as a part of this installation will be run as the user that is debugging, and not the buyer. This typically causes some malfunctioning behavior like missing billing addresses. There are a few workarounds.

1. Don't debug and instead run as the buyer within the store relying on errors sent to the email specified in `Process Automation Settings` to find problems.
1. If you know the buyer's account you can make a change in [B2BPaymentController.cls](force-app/main/default/classes/B2BPaymentController.cls). Directions are specified near the top of `getPaymentInfo()`.
1. You can also make a change in the `getUserAccountInfo()` method in [B2BUtils.cls](force-app/main/default/classes/B2BUtils.cls). Here you would put the ID of the user instead of the call to `UserInfo.getUserId();`. This was not documented within the class as the effects would be farther reaching than in B2BPaymentController.cls. -->