CREATE TABLE [Lookup].[LostLeadsAgencyStatus]
(
	[Market]			[dbo].[OrganisationName] NOT NULL,
	[CICode]			[dbo].[DealerCode] NOT NULL,
	[Retailer]			[dbo].[OrganisationName] NOT NULL,
	[Brand]				[dbo].[OrganisationName] NULL,
	[LostSalesProvider] [dbo].[OrganisationName] NULL,
	[Confirmation]		BIT NOT NULL
)
