

CREATE TABLE [Stage].LandRover_Brazil_Sales_Contract
(
	[ID]					int IDENTITY(1, 1) NOT NULL,
	[AuditID]				[dbo].[AuditID] NULL,
	[PhysicalRowID]			int NULL,
	[AuditItemID]			bigint NULL,
	[PartnerUniqueID]		[dbo].[LoadText] NULL,
	[CommonOrderNumber]		[dbo].[LoadText] NULL,
	[VIN]					[dbo].[LoadText] NULL,
	[ContractNo]			[dbo].[LoadText] NULL,
	[ContractVersion]		[dbo].[LoadText] NULL,
	[CustomerID]			[dbo].[LoadText] NULL,
	[CustType]				[dbo].[LoadText] NULL,
	[CancelDate]			[dbo].[LoadText] NULL,
	[CommonTypeOfSale]		[dbo].[LoadText] NULL,
	[ContractDate]			[dbo].[LoadText] NULL,
	[HandoverDate]			[dbo].[LoadText] NULL,
	[SalesmanCode]			[dbo].[LoadText] NULL,
	[ContractRelationship]	[dbo].[LoadText] NULL,
	[DealerReference]		[dbo].[LoadText] NULL,
	[DateCreated]			[dbo].[LoadText] NULL,
	[CreatedBy]				[dbo].[LoadText] NULL,
	[LastUpdatedBy]			[dbo].[LoadText] NULL,
	[LastUpdated]			[dbo].[LoadText] NULL,
	[Customers]				[dbo].[LoadText] NULL,
	[ConvertedContractDate]			datetime2 NULL,
	[ConvertedHandoverDate]			datetime2 NULL,
	[ConvertedCancelDate]			datetime2 NULL,
	[ConvertedDateCreated]			datetime2 NULL,
	[ConvertedLastUpdated]			datetime2 NULL
)
	
ON [PRIMARY];
GO



