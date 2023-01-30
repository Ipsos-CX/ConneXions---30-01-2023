CREATE VIEW [Canada].[vwSales_LoadtoVWT]
	AS 
	

/*
	Purpose:	Return the Canada Sales events which have yet to be transferred to VWT
	
	Version		Developer			Date			Comment
	1.0			Chris Ross			16/04/2017		Created
	1.1			Chris Ross			10/04/2017		BUG 13831: Add new column Converted_ContractDate. Remove old column Converted_PurchaseOrderDate.


*/	
	
SELECT 
	[AuditID],
	[PhysicalRowID] ,

	DealerID                         ,
	ContractType                     ,
	SaleType                         ,
	ContractDate					  ,
	DealNumber                       ,				
	VIN                              ,
	TypeCode                         ,
	Make                             ,
	Model                            ,
	ModelYear                        ,
	LicensePlateNumber               ,
	InventoryType                    ,
	InvoicePrice                     ,
	VehicleSalePrice                 ,
	BuyerSalutation                  ,
	BuyerFirstName                   ,
	BuyerMiddleName                  ,
	BuyerLastName                    ,
	BuyerFullName                    ,
	BuyerBirthDate                   ,
	BuyerHomeAddress                 ,
	BuyerHomeAddressDistrict         ,
	BuyerHomeAddressCity             ,
	BuyerHomeAddressRegion           ,
	BuyerHomeAddressPostalCode       ,
	BuyerHomeAddressCountry          ,
	BuyerHomePhoneNumber             ,
	BuyerBusinessPhoneNumber         ,
	BuyerPersonalEmailAddress        ,
	SalesManagerID                   ,
	SalesManagerFullName             ,
	FIManagerID                      ,
	
	[Converted_ContractDate],					-- v1.1
	[Converted_BuyerBirthDate] ,
	
	[Extracted_CompanyName]		,
	[SalesPeople_ContactID]		,
	[SalesPeople_FullName]		,
	
	[ManufacturerPartyID] ,
	[SampleSupplierPartyID] ,
	[CountryID] ,
	[EventTypeID],
	[LanguageID],
	[DealerCodeOriginatorPartyID],
	[SetNameCapitalisation] ,
	[SampleTriggeredSelectionReqID]  ,
	[CustomerIdentifierUsable] 
FROM Canada.Sales
WHERE DateTransferredToVWT IS NULL 
AND ISNULL(FilteredFlag , 'N') <> 'Y'