--TASK 690
CREATE TABLE [Stage].[InviteMatrix](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[AuditID] [dbo].[AuditID] NULL,
	[AuditItemID] [dbo].[AuditItemID] NULL,
	[PhysicalRowID] [int] NULL,
	[IP_DataError] [nvarchar](255) NULL,
	[Brand] [dbo].[OrganisationName] NOT NULL,
	[Market] [dbo].[Country] NOT NULL,
	[Questionnaire] [varchar](100) NOT NULL,
	[EmailLanguage] [varchar](100) NOT NULL,
	[EmailSignator] [nvarchar](500) NULL,
	[EmailSignatorTitle] [nvarchar](500) NULL,
	[EmailContactText] [nvarchar](2000) NULL,
	[EmailCompanyDetails] [nvarchar](2000) NULL,
	[JLRCompanyname] [nvarchar](2000) NULL,
	[JLRPrivacyPolicy] [nvarchar](2000) NULL,
	[SubBrand] [varchar](100) NOT NULL			-- TASK 1017 : HOB 
) ON [PRIMARY]
