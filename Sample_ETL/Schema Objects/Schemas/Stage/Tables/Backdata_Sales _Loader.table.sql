CREATE TABLE [Stage].[Backdata_Sales_Loader]
(

	[ID]							[int] IDENTITY(1,1) NOT NULL,
	[AuditID]						[dbo].[AuditID]		NULL,
	[PhysicalRowID]					[int]				NULL,
	[Vin]							dbo.Loadtext		NULL,
	[Vista_Market_Desc]				dbo.Loadtext		NULL,
	[Brand_Name]					dbo.Loadtext		NULL,
	[Dealer_CI_Code]				dbo.Loadtext		NULL,
	[Partner_UniqueId_Desc]			dbo.Loadtext		NULL,
	[Customer_Handover_Date]		dbo.Loadtext		NULL,
	[Model_Description]				dbo.Loadtext		NULL,
	[Order_Created_Date]			dbo.Loadtext		NULL,
	[Common_TypeOfSale_Desc]		dbo.Loadtext		NULL,
	[ConvertedCustomerHandoverDate]	[datetime2](7)		NULL,
	[ConvertedOrderCreatedDate]		[datetime2](7)		NULL,
	[ManufacturerPartyID]			[int]				NULL,
	[SampleSupplierPartyID]			[int]				NULL,
	[CountryID]						[smallint]			NULL,
	[EventTypeID]					[smallint]			NULL,
	[LanguageID]					[smallint]			NULL,
	[DealerCodeOriginatorPartyID]	[int]				NULL
)
