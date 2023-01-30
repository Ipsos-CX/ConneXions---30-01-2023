/****** Object: Table [Sample_Audit].[dbo].[Audit_Landrover_Brazil_Sales_Contract]   Script Date: 23/02/2012 09:43:59 ******/
CREATE TABLE [Audit].LandRover_Brazil_Sales_Contract
(
	[AuditID]				[dbo].[AuditID] NULL,
	[AuditItemID]			bigint NULL,
	[PartnerUniqueID]		[dbo].[LoadText] NULL,
	[CommonOrderNumber]		[dbo].[LoadText] NULL,
	[VIN]					[dbo].[LoadText] NULL,
	[ContractNo]			[dbo].[LoadText] NULL,
	[ContractVersion]		[dbo].[LoadText] NULL,
	[CustomerID]			[dbo].[LoadText] NULL,
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
	[CustType]				[dbo].[LoadText] NULL,
	[Customers]				[dbo].[LoadText] NULL)
	ON [PRIMARY];
GO

