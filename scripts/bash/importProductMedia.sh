#!/bin/bash
# This script will:
# - amend files needed to fill out Product data
# - import Products and related data to make store functional
function exit_error_message() {
  local red_color='\033[0;31m'
  local no_color='\033[0m'
  echo -e "${red_color}$1${no_color}"
  exit 0
}

function echo_attention() {
  local green='\033[0;32m'
  local no_color='\033[0m'
  echo -e "${green}$1${no_color}"
}

if [ -z "$1" ]
then
	exit_error_message "You need to specify the the store name to import it."
fi

storename=$1
echo_attention "Check if the store $storename already exists"
storeId=`sfdx force:data:soql:query -q "SELECT Id FROM WebStore WHERE Name='$1' LIMIT 1" -r csv |tail -n +2`

if [ -z "$storeId" ]
then
    echo_attention "This store name $storename doesn't exist"
    exit_error_message "The setup will stop."
fi

echo_attention "Store front id: $storeId found to $storename"

# I'm still working on it
# ./scripts/bash/importProductMedia.sh Shop


# productDetailImageGroup
# productListImageGroup


# SELECT Id, Name FROM ElectronicMediaGroup

# mediaType="cms_image"
# mediaUrlName="urlname"
# mediaStatus="Published"
# mediaAltText=""

# mediaThumbUrl="https://live.staticflickr.com/65535/49816090811_622af115a8.jpg",
# source