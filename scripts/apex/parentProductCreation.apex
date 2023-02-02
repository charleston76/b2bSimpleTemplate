// The productset is saved in this objec
// SELECT Id, DeveloperName, MasterLabel, Description FROM ProductAttributeSet

// The productset item, that are the fields that make part of the product set
// are saved in this object
// SELECT Id, Field, Sequence, ProductAttributeSetId FROM ProductAttributeSetItem

// And the combination between the product set, and the products (parent variation in this example)
// are saved in this object
// SELECT Id, ProductAttributeSetId, Product.Name, ProductId  FROM ProductAttributeSetProduct


// Get the attibut set by developer name
String attributeSetName = 'Clothing_options';
String attributeSetId = String.valueof([
    SELECT Id FROM ProductAttributeSet
    WHERE DeveloperName =:attributeSetName
    LIMIT 1
    ]?.Id
);

system.debug('attributeSetId ' + attributeSetId);

// Remove the undesired products, for now
List<Product2> lstDelete = [
    SELECT Id FROM Product2
];

List<ProductAttributeSetItem> delProdAttItem = [
    SELECT Id  FROM ProductAttributeSetItem
    WHERE ProductAttributeSetId =: attributeSetId
];


List<ProductAttributeSetProduct> delProdAttSetProd = [
    SELECT Id, ProductId, ProductAttributeSetId 
    FROM ProductAttributeSetProduct
    WHERE ProductAttributeSetId =: attributeSetId
];




system.debug('delProdAttItem.size() ' + delProdAttItem.size());
if (delProdAttItem.size() > 0 ) delete delProdAttItem;

system.debug('delProdAttSetProd.size() ' + delProdAttSetProd.size());
if (delProdAttSetProd.size() > 0 ) delete delProdAttSetProd;


system.debug('lstDelete.size() ' + lstDelete.size());
if (lstDelete.size() > 0 ) delete lstDelete;

// Remove the undesired categoris, for now
List<ProductCategory> lstDelCateg = [
    SELECT Id FROM ProductCategory
];

system.debug('lstDelCateg.size() ' + lstDelCateg.size());

if (lstDelCateg.size() > 0 ) delete lstDelCateg;


// // Insert the parent products
// List<Product2> lstNew = new List<Product2>{
//     new Product2( IsActive = true, Name = 'Tank top shirt 1' , Description = 'Unisex Tank top shirt 1' , StockKeepingUnit = 'CD0001' , ProductCode = 'CD0001'  , Type =  'Base'  ) ,  
//     new Product2( IsActive = true, Name = 'Tank top shirt 2' , Description = 'Unisex Tank top shirt 2' , StockKeepingUnit = 'CD0002' , ProductCode = 'CD0002'  , Type =  'Base'  ) ,  
//     new Product2( IsActive = true, Name = 'Tank top shirt 3' , Description = 'Unisex Tank top shirt 3' , StockKeepingUnit = 'CD0003' , ProductCode = 'CD0003'  , Type =  'Base'  ) ,  
//     new Product2( IsActive = true, Name = 'Long sleeve shirt 1' , Description = 'Unisex Long sleeve shirt 1' , StockKeepingUnit = 'CD0004' , ProductCode = 'CD0004'  , Type =  'Base'  ) ,  
//     new Product2( IsActive = true, Name = 'Long sleeve shirt 2' , Description = 'Unisex Long sleeve shirt 2' , StockKeepingUnit = 'CD0005' , ProductCode = 'CD0005'  , Type =  'Base'  ) ,  
//     new Product2( IsActive = true, Name = 'boat neck t-shirt 1' , Description = 'Unisex boat neck t-shirt 1' , StockKeepingUnit = 'CD0006' , ProductCode = 'CD0006'  , Type =  'Base'  ) ,  
//     new Product2( IsActive = true, Name = 'boat neck t-shirt 2' , Description = 'Unisex boat neck t-shirt 2' , StockKeepingUnit = 'CD0007' , ProductCode = 'CD0007'  , Type =  'Base'  ) ,  
//     new Product2( IsActive = true, Name = 'boat neck t-shirt 3' , Description = 'Unisex boat neck t-shirt 3' , StockKeepingUnit = 'CD0008' , ProductCode = 'CD0008'  , Type =  'Base'  ) ,  
//     new Product2( IsActive = true, Name = 'Polo collar t-shirt 1' , Description = 'Unisex Polo collar t-shirt 1' , StockKeepingUnit = 'CD0009' , ProductCode = 'CD0009'  , Type =  'Base'  ) ,  
//     new Product2( IsActive = true, Name = 'Polo collar t-shirt 2' , Description = 'Unisex Polo collar t-shirt 2' , StockKeepingUnit = 'CD0010' , ProductCode = 'CD0010'  , Type =  'Base'  ) ,  
//     new Product2( IsActive = true, Name = 'Polo collar t-shirt 3' , Description = 'Unisex Polo collar t-shirt 3' , StockKeepingUnit = 'CD0011' , ProductCode = 'CD0011'  , Type =  'Base'  ) ,  
//     new Product2( IsActive = true, Name = 'Traditional dress shirt  1' , Description = 'Unisex Traditional dress shirt  1' , StockKeepingUnit = 'CD0012' , ProductCode = 'CD0012'  , Type =  'Base'  ) ,  
//     new Product2( IsActive = true, Name = 'Traditional dress shirt 2' , Description = 'Unisex Traditional dress shirt 2' , StockKeepingUnit = 'CD0013' , ProductCode = 'CD0013'  , Type =  'Base'  ) ,  
//     new Product2( IsActive = true, Name = 'Traditional shorts 1' , Description = 'Unisex Traditional shorts 1' , StockKeepingUnit = 'CD0014' , ProductCode = 'CD0014'  , Type =  'Base'  ) ,  
//     new Product2( IsActive = true, Name = 'Traditional shorts 2' , Description = 'Unisex Traditional shorts 2' , StockKeepingUnit = 'CD0015' , ProductCode = 'CD0015'  , Type =  'Base'  ) ,  
//     new Product2( IsActive = true, Name = 'Traditional shorts 3' , Description = 'Unisex Traditional shorts 3' , StockKeepingUnit = 'CD0016' , ProductCode = 'CD0016'  , Type =  'Base'  ) ,  
//     new Product2( IsActive = true, Name = 'Tactel shorts 1 ' , Description = 'Unisex Tactel shorts 1 ' , StockKeepingUnit = 'CD0017' , ProductCode = 'CD0017'  , Type =  'Base'  ) ,  
//     new Product2( IsActive = true, Name = 'Tactel shorts 2' , Description = 'Unisex Tactel shorts 2' , StockKeepingUnit = 'CD0018' , ProductCode = 'CD0018'  , Type =  'Base'  ) ,  
//     new Product2( IsActive = true, Name = 'Tactel shorts 3' , Description = 'Unisex Tactel shorts 3' , StockKeepingUnit = 'CD0019' , ProductCode = 'CD0019'  , Type =  'Base'  ) 
// };

// system.debug('lstNew.size()  ' + lstNew.size() );

// insert lstNew;

// // Relate those with the attribute set
// List<ProductAttributeSetProduct> lstPrdAttToEntry =  new List<ProductAttributeSetProduct>();
    
// for (Product2 rowProd : lstNew){
//     ProductAttributeSetProduct newPrdAttToEntry = new ProductAttributeSetProduct(
//         ProductAttributeSetId = attributeSetId,
//         productId =rowProd.Id
//     );

//     lstPrdAttToEntry.add(newPrdAttToEntry);
    
// }


// system.debug('lstPrdAttToEntry.size() ' + lstPrdAttToEntry.size());

// if (lstPrdAttToEntry.size() > 0 ) insert  lstPrdAttToEntry;

// sfdx force:apex:execute -f scripts/apex/parentProductCreation.apex