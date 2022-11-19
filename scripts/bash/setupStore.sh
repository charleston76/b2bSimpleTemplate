#!/bin/bash
# Use this command followed by a store name.
#
# Before running this script make sure that you completed all the previous steps in the setup
# (run convert-examples-to-sfdx.sh, execute sfdx force:source:push -f, create store)
#
# This script will:
# - register the Apex classes needed for checkout integrations and map them to your store
# - associate the clone of the checkout flow to the checkout component in your store
# - add the Customer Community Plus Profile clone to the list of members for the store
# - import Products and necessary related store data in order to get you started
# - create a Buyer User and attach a Buyer Profile to it
# - create a Buyer Account and add it to the relevant Buyer Group
# - add Contact Point Addresses for Shipping and Billing to your new buyer Account
# - activate the store
# - publish your store so that the changes are reflected

function echo_attention() {
  local green='\033[0;32m'
  local no_color='\033[0m'
  echo -e "${green}$1${no_color}"
}

function just_wait_a_litte() {
	local green='\033[0;32m'
	local no_color='\033[0m'
	echo -e "${green}Just waiting a little to conitnue${no_color}"
	sleep 5
}

if [ -z "$1" ]
then
	echo "You need to specify the name of the storefront to create it."
	exit 0
fi

mkdir experience-bundle-package
#############################
#    Retrieve Store Info    #
#############################

communityNetworkName=$1
# If the name of the store starts with a digit, the CustomSite name will have a prepended X.
communitySiteName="$(echo $1 | sed -E 's/(^[0-9])/X\1/g')"
# The ExperienceBundle name is similar to the CustomSite name, but has a 1 appended.
communityExperienceBundleName="$communitySiteName"1

# Replace the names of the components that will be retrieved.
##sed -E "s/YourCommunitySiteNameHere/$communitySiteName/g;s/YourCommunityExperienceBundleNameHere/$communityExperienceBundleName/g;s/YourCommunityNetworkNameHere/$communityNetworkName/g" quickstart-config/package-retrieve-template.xml > package-retrieve.xml
sed -E "s/YourCommunitySiteNameHere/$communitySiteName/g;s/YourCommunityExperienceBundleNameHere/$communityExperienceBundleName/g;s/YourCommunityNetworkNameHere/$communityNetworkName/g" manifest/package-retrieve-template.xml > package-retrieve.xml

echo "Using this to retrieve your store info:"
cat package-retrieve.xml

echo "Retrieving the store metadata and extracting it from the zip file."
sfdx force:mdapi:retrieve -r experience-bundle-package -k  package-retrieve.xml
unzip -d experience-bundle-package experience-bundle-package/unpackaged.zip


#############################
#       Update Store        #
#############################

storeId=`sfdx force:data:soql:query -q "SELECT Id FROM WebStore WHERE Name='$1' LIMIT 1" -r csv |tail -n +2`

# Register Apex classes needed for checkout integrations and map them to the store
echo "1. Setting up your integrations."

# For each Apex class needed for integrations, register it and map to the store
function register_and_map_integration() {
	# $1 is Apex class name
	# $2 is DeveloperName
	# $3 is ExternalServiceProviderType

	echo "Registering Apex class $1 ($2) for $3 integration."

	# Get the Id of the Apex class
	local apexClassId=`sfdx force:data:soql:query -q "SELECT Id FROM ApexClass WHERE Name='$1' LIMIT 1" -r csv |tail -n +2`
	if [ -z "$apexClassId" ]
	then
		echo "There was a problem getting the ID of the Apex class $1 for checkout integrations."
		echo "The registration and mapping for this class will be skipped!"
		echo "Make sure that you run convert-examples-to-sfdx.sh and execute sfdx force:source:push -f before setting up your store."
	else
		# Register the Apex class. If the class is already registered, a "duplicate value found" error will be displayed but the script will continue.
		sfdx force:data:record:create -s RegisteredExternalService -v "DeveloperName=$2 ExternalServiceProviderId=$apexClassId ExternalServiceProviderType=$3 MasterLabel=$2"

		# Map the Apex class to the store if no other mapping exists for the same Service Provider Type
		local storeIntegratedServiceId=`sfdx force:data:soql:query -q "SELECT Id FROM StoreIntegratedService WHERE ServiceProviderType='$3' AND StoreId='$storeId' LIMIT 1" -r csv |tail -n +2`
		if [ -z "$storeIntegratedServiceId" ]
		then
			# No mapping exists, so we will create one
			local registeredExternalServiceId=`sfdx force:data:soql:query -q "SELECT Id FROM RegisteredExternalService WHERE ExternalServiceProviderId='$apexClassId' LIMIT 1" -r csv |tail -n +2`
			sfdx force:data:record:create -s StoreIntegratedService -v "Integration=$registeredExternalServiceId StoreId=$storeId ServiceProviderType=$3"
		else
			echo "There is already a mapping in this store for $3 ServiceProviderType: $storeIntegratedServiceId"
		fi
	fi
}

# Maps a standard integration. This is for nodes like pricing and promotions which don't require external services to run.
function map_standard_integration {
	local serviceProviderType=$1
	local integrationName=$2

	echo "Mapping internal ($integrationName) for $serviceProviderType integration."

	local integrationId=`sfdx force:data:soql:query -q "SELECT Id FROM StoreIntegratedService WHERE ServiceProviderType='$serviceProviderType' AND StoreId='$storeId' LIMIT 1" -r csv |tail -n +2`
	if [ -z "$integrationId" ]
	then
		sfdx force:data:record:create -s StoreIntegratedService -v "Integration=$integrationName StoreId=$storeId ServiceProviderType=$serviceProviderType"
		echo "To register an external ($serviceProviderType) integration, delete the internal mapping and then add the external ($serviceProviderType) mapping.  See the code for details how."
	else
		echo "There is already a mapping in this store for ($serviceProviderType) ServiceProviderType: $integrationId"
	fi
}

function register_and_map_pricing_integration {
	map_standard_integration "Price" "Price__B2B_STOREFRONT__StandardPricing"
}

function register_and_map_promotions_integration {
	map_standard_integration "Promotions" "Promotions__B2B_STOREFRONT__StandardPromotions"
}

function register_and_map_credit_card_payment_integration {
	echo "Registering credit card payment integration."

	# Creating Payment Gateway Provider
	apexClassId=`sfdx force:data:soql:query -q "SELECT Id FROM ApexClass WHERE Name='SalesforceAdapter' LIMIT 1" -r csv |tail -n +2`
	echo "Creating PaymentGatewayProvider record using ApexAdapterId=$apexClassId."
	sfdx force:data:record:create -s PaymentGatewayProvider -v "DeveloperName=SalesforcePGP ApexAdapterId=$apexClassId MasterLabel=SalesforcePGP IdempotencySupported=Yes Comments=Comments"

	# Creating Payment Gateway
	paymentGatewayProviderId=`sfdx force:data:soql:query -q "SELECT Id FROM PaymentGatewayProvider WHERE DeveloperName='SalesforcePGP' LIMIT 1" -r csv | tail -n +2`
	namedCredentialId=`sfdx force:data:soql:query -q "SELECT Id FROM NamedCredential WHERE MasterLabel='Salesforce' LIMIT 1" -r csv | tail -n +2`
	echo "Creating PaymentGateway record using MerchantCredentialId=$namedCredentialId, PaymentGatewayProviderId=$paymentGatewayProviderId."
	sfdx force:data:record:create -s PaymentGateway -v "MerchantCredentialId=$namedCredentialId PaymentGatewayName=SalesforcePG PaymentGatewayProviderId=$paymentGatewayProviderId Status=Active"

	# Creating Store Integrated Service
	storeId=`sfdx force:data:soql:query -q "SELECT Id FROM WebStore WHERE Name='$communityNetworkName' LIMIT 1" -r csv | tail -n +2`
	paymentGatewayId=`sfdx force:data:soql:query -q "SELECT Id FROM PaymentGateway WHERE PaymentGatewayName='SalesforcePG' LIMIT 1" -r csv | tail -n +2`

	echo "Creating StoreIntegratedService using the $communityNetworkName store and Integration=$paymentGatewayId (PaymentGatewayId)"
	sfdx force:data:record:create -s StoreIntegratedService -v "Integration=$paymentGatewayId StoreId=$storeId ServiceProviderType=Payment"
}

register_and_map_integration "B2BCheckInventorySample" "CHECK_INVENTORY" "Inventory"
register_and_map_integration "B2BDeliverySample" "COMPUTE_SHIPPING" "Shipment"
register_and_map_integration "B2BTaxSample" "COMPUTE_TAXES" "Tax"

# By default, use the internal pricing integration
register_and_map_pricing_integration
# To use an external integration instead, use the code below:
# register_and_map_integration "B2BPricingSample" "COMPUTE_PRICE" "Price"
# Or follow the documentation for setting up the integration manually:
# https://developer.salesforce.com/docs/atlas.en-us.b2b_comm_lex_dev.meta/b2b_comm_lex_dev/b2b_comm_lex_integration_setup.htm

# By default, use the internal promotions integration
register_and_map_promotions_integration 

register_and_map_credit_card_payment_integration

echo "You can view the results of the mapping in the Store Integrations page at /lightning/page/storeDetail?lightning__webStoreId=$storeId&storeDetail__selectedTab=store_integrations"

# Map the checkout flow with the checkout component in the store
# This is to allow for changes in case for the checkout meta file which we have noticed to shift around quite a lot.
echo "2. Updating flow associated to checkout."
checkoutMetaFolder="experience-bundle-package/unpackaged/experiences/$communityExperienceBundleName/views/"
checkoutFileToGrep="Checkout.json"
# Do a case insensitive grep and capture file
greppedFile=`ls $checkoutMetaFolder | egrep -i "^$checkoutFileToGrep"`
echo "Grepped File is: " $greppedFile
checkoutMetaFile=$checkoutMetaFolder$greppedFile	
tmpfile=$(mktemp)
# This determines the name of the main flow as it will always be the only flow to terminate in "Checkout.flow"
mainFlowName=`ls force-app/main/default/flows/*Checkout.flow-meta.xml | sed 's/.*flows\/\(.*\).flow-meta.xml/\1/'`
# This will make this the selected checkout flow in the store
sed "s/sfdc_checkout__CheckoutTemplate/$mainFlowName/g" $checkoutMetaFile > $tmpfile
mv -f $tmpfile $checkoutMetaFile


# This adding group member needs to be evalueted better, since it is not a scratch org
# due that I'm removing it
# Add the Customer Community Plus Profile clone to the list of members for the store
#    + add value 'Live' to field 'status' to activate community
echo "3. Updating members list and activating community."
networkMetaFile="experience-bundle-package/unpackaged/networks/$communityNetworkName".network
tmpfile=$(mktemp)
sed "s/<networkMemberGroups>/<networkMemberGroups><profile>Buyer_Profile<\/profile>/g;s/<status>.*/<status>Live<\/status>/g" $networkMetaFile > $tmpfile
mv -f $tmpfile $networkMetaFile

# Import Products and related data
# Get new Buyer Group Name
echo "4. Importing products and the other things"
buyergroupName=$(bash ./scripts/bash/importProductSample.sh $1 | tail -n 1)


# If notnot working with scratch orgs, comment the code below
# Assign a role to the admin user, else update user will error out
echo "5. Mapping Admin User to Role."
ceoID=`sfdx force:data:soql:query --query \ "SELECT Id FROM UserRole WHERE Name = 'CEO'" -r csv |tail -n +2`
sfdx force:data:record:create -s UserRole -v "ParentRoleId='$ceoID' Name='AdminRoleScriptCreation' DeveloperName='AdminRoleScriptCreation' RollupDescription='AdminRoleScriptCreation' "
# after creating, just wait a little to get the id back
just_wait_a_litte
newRoleID=`sfdx force:data:soql:query --query \ "SELECT Id FROM UserRole WHERE Name = 'AdminRoleScriptCreation'" -r csv |tail -n +2`
echo_attention "newRoleID $newRoleID"
# after creating, just wait a little to get the id back
just_wait_a_litte
username=`sfdx force:user:display | grep "Username" | sed 's/Username//g;s/^[[:space:]]*//g'`
echo_attention "username $username"
# after creating, just wait a little to get the id back
just_wait_a_litte
sfdx force:data:record:update -s User -w "Username='$username'" -v "UserRoleId='$newRoleID'" 

# Putted on the manifest to deploy there
# echo_attention "Deploying the profile to create the user"
# sfdx force:source:deploy -p ./force-app/main/default/profiles/Buyer\ Profile.profile-meta.xml

# Create Buyer User. Go to config/buyer-user-def.json to change name, email and alias.
echo "6. Creating Buyer User with associated Contact and Account."

echo_attention "Creating a folder to copy json file"
mkdir setupB2b

# Replace the name there and put with the scratch org name
# sfdx force:user:create -f scripts/json/buyer-user-def.json
sed -E "s/YOUR_SCRATCH_NAME/$communityNetworkName/g" scripts/json/buyer-user-def.json > setupB2b/tmpBuyerUserDef.json
sfdx force:user:create -f setupB2b/tmpBuyerUserDef.json
# Get the Contact user name
contactUsername=`grep -i '"Username":' setupB2b/tmpBuyerUserDef.json|cut -d "\"" -f 4`
echo_attention "contactUsername $contactUsername"
echo_attention "Removing the setupB2b folder"
rm -rf setupB2b

# The code below definitely works, but I prefere define the name with the store name
# buyerusername=`grep -i '"Username":' scripts/json/buyer-user-def.json|cut -d "\"" -f 4`
buyerusername="buyer Account ${1}"
# buyerusername = "'.'${buyerusername}"
echo "buyerusername >>>>>>>>>> " $buyerusername

# Get most recently created account with Account Store Name suffix
# Convert Account to Buyer Account
echo "Making Account a Buyer Account."
sfdx force:data:record:create -s Account -v "Name='$buyerusername'"

accountID=`sfdx force:data:soql:query --query \ "SELECT Id FROM Account WHERE Name LIKE '${buyerusername}' ORDER BY CreatedDate Desc LIMIT 1" -r csv |tail -n +2`
sfdx force:data:record:create -s BuyerAccount -v "BuyerId='$accountID' Name='$buyerusername' isActive=true"

# Assign Account to Buyer Group
echo "Assigning Buyer Account to Buyer Group."
buyergroupID=`sfdx force:data:soql:query --query \ "SELECT Id FROM BuyerGroup WHERE Name = '${buyergroupName}'" -r csv |tail -n +2`
sfdx force:data:record:create -s BuyerGroupMember -v "BuyerGroupId='$buyergroupID' BuyerId='$accountID'"

# Add the contact
contactUserId=`sfdx force:data:soql:query --query \ "SELECT Id FROM User WHERE username = '$contactUsername'" -r csv |tail -n +2`
echo_attention "Creating the contact $contactUsername user Id $contactUserId"
sfdx force:data:record:create -s Contact -v "AccountId='$accountID' FirstName='B2B' LastName='$contactUsername'"
contactId=`sfdx force:data:soql:query --query \ "SELECT Id FROM Contact WHERE Name = 'B2B $contactUsername'" -r csv |tail -n +2`
sfdx force:data:record:update -s User -w "Username='$username'" -v "ContactId='$contactId'" 

# Add Contact Point Addresses to the buyer account associated with the buyer user.
# The account will have 2 Shipping and 2 billing addresses associated to it.
# To view the addresses in the UI you need to add Contact Point Addresses to the related lists for Account
echo "7. Add Contact Point Addresses to the Buyer Account."
existingCPAForBuyerAccount=`sfdx force:data:soql:query --query \ "SELECT Id FROM ContactPointAddress WHERE ParentId='${accountID}' LIMIT 1" -r csv |tail -n +2`
if [ -z "$existingCPAForBuyerAccount" ]
then
	sfdx force:data:record:create -s ContactPointAddress -v "AddressType='Shipping' ParentId='$accountID' ActiveFromDate='2020-01-01' ActiveToDate='2040-01-01' City='California' Country='United States' IsDefault='true' Name='Default Shipping' PostalCode='V6B 5A7' State='California' Street='333 Seymour Street (Shipping)'"
	sfdx force:data:record:create -s ContactPointAddress -v "AddressType='Billing' ParentId='$accountID' ActiveFromDate='2020-01-01' ActiveToDate='2040-01-01' City='California' Country='United States' IsDefault='true' Name='Default Billing' PostalCode='V6B 5A7' State='California' Street='333 Seymour Street (Billing)'"
	sfdx force:data:record:create -s ContactPointAddress -v "AddressType='Shipping' ParentId='$accountID' ActiveFromDate='2020-01-01' ActiveToDate='2040-01-01' City='California' Country='United States' IsDefault='false' Name='Non-Default Shipping' PostalCode='94105' State='California' Street='415 Mission Street (Shipping)'"
	sfdx force:data:record:create -s ContactPointAddress -v "AddressType='Billing' ParentId='$accountID' ActiveFromDate='2020-01-01' ActiveToDate='2040-01-01' City='California' Country='United States' IsDefault='false' Name='Non-Default Billing' PostalCode='94105' State='California' Street='415 Mission Street (Billing)'"
else
	echo "There is already at least 1 Contact Point Address for your Buyer Account ${buyerusername}"
fi

echo "Setup Guest Browsing."
storeType=`sfdx force:data:soql:query --query \ "SELECT Type FROM WebStore WHERE Name = '${communityNetworkName}'" -r csv |tail -n +2`
echo "Store Type is $storeType"
# Originally it just was doing to b2c... but...
# # Update Guest Profile with required CRUD and FLS
# if [ "$storeType" = "B2C" ]
# then
	sh ./scripts/bash/b2bGuestBrowsing.sh $communityNetworkName $buyergroupName true
# fi	
#############################
#   Deploy Updated Store    #
#############################

echo "Creating the package to deploy, including the new flow."
cd experience-bundle-package/unpackaged/
cp -f ../../manifest/package-deploy-template.xml package.xml
zip -r -X ../"$communityExperienceBundleName"ToDeploy.zip *
cd ../..

# Uncomment the line below if you'd like to pause the script in order to save the zip file to deploy
# read -p "Press any key to resume ..."

echo "Deploy the new zip including the flow, ignoring warnings, then clean-up."
sfdx force:mdapi:deploy -g -f experience-bundle-package/"$communityExperienceBundleName"ToDeploy.zip --wait -1 --verbose --singlepackage
rm -fr experience-bundle-package

echo "Removing the package xml files used for retrieving and deploying metadata at this step."
rm package-retrieve.xml

echo "Publishing the community."
sfdx force:community:publish -n "$communityNetworkName"
sleep 10

echo "Creating search index."
sfdx 1commerce:search:start -n "$communityNetworkName"


echo "QUICK START COMPLETE!"

# # Now, I get the user name there in the file, to create the user
# contactUsername=`grep -i '"Username":' scripts/json/buyer-user-def.json|cut -d "\"" -f 4`
# sfdx force:user:password:generate -o ${contactUsername}
# echo "Use this buyer user to log in to the store:"
# sfdx force:user:display -u ${contactUsername}

# echo "NOW WE REALLY ARE DONE!"