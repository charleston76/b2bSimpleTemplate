#!/bin/sh

if [[ -z "$1" ]] || [[ -z "$2" ]]
then
	echo "You need to specify the name of the store and name of the buyer group."
	echo "Command should look like: ./enable-guest-browsing.sh <YourStoreName> <NameOfBuyerGroup>"
	exit 1
fi

############################################################
# The real deployment part will be done by the git action
# loading the necessary things from the package
############################################################

communityNetworkName=$1
# If the name of the store starts with a digit, the CustomSite name will have a prepended X.
communitySiteName="$(echo $1 | sed -E 's/(^[0-9])/X\1/g')"
# The ExperienceBundle name is similar to the CustomSite name, but has a 1 appended.
buyergroupName=$2


# Enable Guest Browsing for WebStore and create Guest Buyer Profile. 
# Assign to Buyer Group of choice.
sfdx force:data:record:update -s WebStore -v "OptionsGuestBrowsingEnabled='true'" -w "Name='$communityNetworkName'"
guestBuyerProfileId=`sfdx force:data:soql:query --query \ "SELECT GuestBuyerProfileId FROM WebStore WHERE Name = '$communityNetworkName'" -r csv |tail -n +2`
buyergroupID=`sfdx force:data:soql:query --query \ "SELECT Id FROM BuyerGroup WHERE Name = '${buyergroupName}'" -r csv |tail -n +2`
sfdx force:data:record:create -s BuyerGroupMember -v "BuyerId='$guestBuyerProfileId' BuyerGroupId='$buyergroupID'"



echo "Rebuilding the  search index."
sfdx 1commerce:search:start -n "$communityNetworkName"


echo "Publishing the community."
sfdx force:community:publish -n "$communityNetworkName"
sleep 10

echo
echo
echo "Done! Guest Buyer Access is setup!"
echo "Don't forget to activate your store manually in the environment"
echo
echo