#!/bin/bash
# This script will:
# - amend files needed to fill out Product data
# - import Products and related data to make store functional
if [ -z "$1" ]
then
    echo "You need to specify the store name to import products"
else
	# Get Id for Store and replace in json files 
    storeId=`sfdx  force:data:soql:query -q "SELECT Id FROM WebStore WHERE Name='$1' LIMIT 1" -r csv |tail -n +2`
    sed -e "s/\"WebStoreId\": \"PutWebStoreIdHere\"/\"WebStoreId\": \"${storeId}\"/g" scripts/json/WebStorePricebooks-template.json > scripts/json/WebStorePricebooks.json
    sed -e "s/\"SalesStoreId\": \"PutWebStoreIdHere\"/\"SalesStoreId\": \"${storeId}\"/g" scripts/json/WebStoreCatalogs-template.json > scripts/json/WebStoreCatalogs.json
    sed -e "s/\"WebStoreId\": \"PutWebStoreIdHere\"/\"WebStoreId\": \"${storeId}\"/g" scripts/json/WebStoreBuyerGroups-template.json > scripts/json/WebStoreBuyerGroups.json

    # Get Standard Pricebooks for Store and replace in json files
	pricebook1=`sfdx force:data:soql:query -q "SELECT Id FROM Pricebook2 WHERE Name='Standard Price Book' AND IsStandard=true LIMIT 1" -r csv |tail -n +2`
	
	sed -e "s/\"Pricebook2Id\": \"PutStandardPricebookHere\"/\"Pricebook2Id\": \"${pricebook1}\"/g" scripts/json/PricebookEntrys-template.json > scripts/json/PricebookEntrys.json
	
	# Buyer Group
	numberofbuyergroups=`sfdx force:data:soql:query -q "SELECT COUNT(Id) FROM BuyerGroup" -r csv  |tail -n +2`
	# newnumber=$(($numberofbuyergroups + 1))
	# newbuyergroupname="BUYERGROUP_FROM_QUICKSTART_${newnumber}"
	newnumber=$(($numberofbuyergroups + 1))
	firstOne=1
	if [ "$newnumber" -gt "$firstOne" ]; 
	then
		newbuyergroupname="$1 Buyer Group${newnumber}"
	else
		newbuyergroupname="$1 Buyer Group"
	fi	

	echo "Checking if exists a buyer group created"
	checkExistingBuyergroupID=`sfdx force:data:soql:query --query \ "SELECT Id FROM BuyerGroup WHERE Name = '$newbuyergroupname'" -r csv |tail -n +2`
	echo $checkExistingBuyergroupID
	
	if [ "$checkExistingBuyergroupID" == "" ]
	then
		echo "Would create, but it is not creating the new Buyer group"
		#sfdx force:data:record:create -s BuyerGroup -v "Name='$newbuyergroupname' Description='$1'"
	fi

	sed -e "s/\"Name\": \"PutBuyerGroupHere\"/\"Name\": \"${newbuyergroupname}\"/g;s/\"Description\": \"PutStoreNameHere\"/\"Description\": \"${1}\"/g" scripts/json/BuyerGroups-template.json > scripts/json/BuyerGroups.json

	# Determine if Product-less insert or Product insert is needed.

	# For now, if there is atleast 1 match, skip inserting products. 
	# Down the line, explore Bulk Upsert if people delete Products.
	# Workaround, use throwaway community to delete all products to trigger re-insert.
	productq=`sfdx force:data:soql:query -q "SELECT COUNT(Id) FROM Product2 WHERE StockKeepingUnit In ('B-C-COFMAC-001', 'DRW-1', 'SS-DR-BB', 'ESP-001', 'TM-COFMAC-001', 'ESP-IOT-1', 'ID-PEM', 'TR-COFMAC-001', 'LRW-1', 'MRC-1', 'CP-2', 'GDG-1', 'E-ESP-001', 'ID-CAP-II', 'PS-DB', 'Q85YQ2', 'CCG-1', 'CERCG-1', 'CF-1', 'E-MR-B', 'ID-CAP-III', 'PS-EL', 'EM-ESP-001', 'CP-3', 'CL-DR-BB', 'CR-DEC', 'CREV-DR-BLEND', 'CM-MSB-300', 'COF-FIL', 'CP-1')" -r csv |tail -n +2`

	if [ "$productq" -gt 0 ]
	then 
		# Grab Product IDs to create Product Entitlements
		sfdx force:data:soql:query -q "SELECT Id FROM Product2 WHERE StockKeepingUnit In ('B-C-COFMAC-001', 'DRW-1', 'SS-DR-BB', 'ESP-001', 'TM-COFMAC-001', 'ESP-IOT-1', 'ID-PEM', 'TR-COFMAC-001', 'LRW-1', 'MRC-1', 'CP-2', 'GDG-1', 'E-ESP-001', 'ID-CAP-II', 'PS-DB', 'Q85YQ2', 'CCG-1', 'CERCG-1', 'CF-1', 'E-MR-B', 'ID-CAP-III', 'PS-EL', 'EM-ESP-001', 'CP-3', 'CL-DR-BB', 'CR-DEC', 'CREV-DR-BLEND', 'CM-MSB-300', 'COF-FIL', 'CP-1')" -r csv > productfile.csv
		INPUT="productfile.csv"
		array=()
		# Load Product IDs into array 	
		while IFS="\n" read var1 ; do
			echo $var1
			if [ $var1 != "Id" ] 
			then	
			    array+=("$var1")
			fi	
		done < $INPUT

		# Import Productless data
		sfdx force:data:tree:import -p scripts/json/Productless-Plan-1.json
		# Get newly created Entitlement Policy ID
		policyID=`sfdx force:data:soql:query -q "SELECT Id FROM CommerceEntitlementPolicy ORDER BY CreatedDate Desc LIMIT 1" -r csv |tail -n +2`
		# Create new Product Entitlement records
		for i in "${array[@]}"
		do
	   		:
			sfdx force:data:record:create -s CommerceEntitlementProduct -v "PolicyId='${policyID}' ProductId='${i}'"
		done

		# Get Webstore ID
		storeId=`sfdx  force:data:soql:query -q "SELECT Id FROM WebStore WHERE Name='$1' LIMIT 1" -r csv |tail -n +2`
		
		# Add Store Catalog mapping
		catalogId=`sfdx force:data:soql:query -q "SELECT Id FROM ProductCatalog WHERE Name='CATALOG_FROM_QUICKSTART' ORDER BY CreatedDate Desc LIMIT 1" -r csv | tail -n +2`
		sfdx force:data:record:create -s WebStoreCatalog -v "ProductCatalogId='${catalogId}' SalesStoreId='${storeId}'"

		# Add Store Pricebook mapping
		pricebook2Id=`sfdx force:data:soql:query -q "SELECT Id FROM Pricebook2 WHERE Name='BASIC_PRICEBOOK_FROM_QUICKSTART' ORDER BY CreatedDate Desc LIMIT 1" -r csv | tail -n +2`
		sfdx force:data:record:create -s WebStorePricebook -v "IsActive=true Pricebook2Id='${pricebook2Id}' WebStoreId='${storeId}'"
		
		# Add Buyer Group Pricebook mapping
		buyergroupId=`sfdx force:data:soql:query -q "SELECT Id FROM BuyerGroup WHERE Name='${newbuyergroupname}'  LIMIT 1" -r csv | tail -n +2`
		sfdx force:data:record:create -s BuyerGroupPricebook -v "Pricebook2Id='${pricebook2Id}' BuyerGroupId='${buyergroupId}'"

		# Cleanup
		rm productfile.csv

	else
		# Import files
		sfdx force:data:tree:import -p scripts/json/Plan-1.json
	fi

	# Cleanup
	rm scripts/json/WebStorePricebooks.json
	rm scripts/json/WebStoreCatalogs.json
	rm scripts/json/WebStoreBuyerGroups.json
	rm scripts/json/BuyerGroups.json	
	rm scripts/json/PricebookEntrys.json
	
	# Return BuyerGroup Name to be used in BuyerGroup Account mapping 
	echo $newbuyergroupname

fi
