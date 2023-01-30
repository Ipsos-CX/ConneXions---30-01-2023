CREATE TABLE [dbo].[EventX_LostLeads_BDC](
	[Market] [dbo].[OrganisationName] NOT NULL DEFAULT '',
	[RetailerCode] [NVARCHAR](10) NOT NULL,
	[Retailer] [dbo].[OrganisationName] NOT NULL,
	[Brand] [dbo].[OrganisationName] NULL,
	[BDCName] [dbo].[OrganisationName] NULL,
	[BDCCode] [INT] NULL,
	[Confirmation] [bit] NOT NULL
) ON [PRIMARY]