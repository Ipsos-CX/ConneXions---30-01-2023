/****** Object: Table [dbo].[Audit_Landrover_Brazil_Sales_Customer]   Script Date: 23/02/2012 10:07:31 ******/
CREATE TABLE [Audit].[LandRover_Brazil_Sales_Customer] 
(
	[AuditID]				[dbo].[AuditID] NULL,
	[AuditItemID]			bigint NULL,
	[PartnerUniqueID]		[dbo].[LoadText] NULL,
	[CustomerID]			[dbo].[LoadText] NULL,
	[Surname]				[dbo].[LoadText] NULL,
	[Forename]				[dbo].[LoadText] NULL,
	[Title]					[dbo].[LoadText] NULL,
	[DateOfBirth]			[dbo].[LoadText] NULL,
	[Occupation]			[dbo].[LoadText] NULL,
	[Email]					[dbo].[LoadText] NULL,
	[MobileTelephone]		[dbo].[LoadText] NULL,
	[HomeTelephone]			[dbo].[LoadText] NULL,
	[WorkTelephone]			[dbo].[LoadText] NULL,
	[Address1]				[dbo].[LoadText] NULL,
	[Address2]				[dbo].[LoadText] NULL,
	[PostCode]				[dbo].[LoadText] NULL,
	[Town]					[dbo].[LoadText] NULL,
	[Country]				[dbo].[LoadText] NULL,
	[CompanyName]			[dbo].[LoadText] NULL,
	[State]					[dbo].[LoadText] NULL,
	[PersonalTaxNumber]		[dbo].[LoadText] NULL,
	[CompanyTaxNumber]		[dbo].[LoadText] NULL,
	[MaritalStatus]			[dbo].[LoadText] NULL,
	[EmailOptIn]			[dbo].[LoadText] NULL,
	[EmailOptInDate]		[dbo].[LoadText] NULL,
	[TelephoneOptIn]		[dbo].[LoadText] NULL,
	[TelephoneOptInDate]	[dbo].[LoadText] NULL,
	[MobileOptIn]			[dbo].[LoadText] NULL,
	[MobileOptInDate]		[dbo].[LoadText] NULL,
	[DateCreated]			[dbo].[LoadText] NULL,
	[CreatedBy]				[dbo].[LoadText] NULL,
	[LastUpdatedBy]			[dbo].[LoadText] NULL,
	[LastUpdated]			[dbo].[LoadText] NULL,
	[CustType]				[dbo].[LoadText] NULL)
ON [PRIMARY];
GO

