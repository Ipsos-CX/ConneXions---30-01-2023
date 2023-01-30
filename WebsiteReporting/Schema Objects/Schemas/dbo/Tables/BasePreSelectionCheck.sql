CREATE TABLE [dbo].[BasePreSelectionCheck](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[AuditItemID] [int] NULL,
	[QuestionnaireRequirementID] [int] NULL,
	[MatchedODSEventID] [int] NULL,
	[PartyID] [int] NULL,
	[MatchedODSEmailAddressID] [int] NULL,
	[EventCategory] [varchar](50) NULL,
	[EventCategoryID] [int] NULL,
	[DeleteBarredEmail] [bit] NOT NULL,
	[MatchedODSVehicleID] [int] NULL
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[BasePreSelectionCheck] ADD  DEFAULT ((0)) FOR [DeleteBarredEmail]
GO