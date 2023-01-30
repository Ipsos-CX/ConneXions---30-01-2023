CREATE TABLE [dbo].[PoolPreSelectionCheck](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[AuditItemID] [int] NULL,
	[QuestionnaireRequirementID] [int] NULL,
	[MatchedODSEventID] [int] NULL,
	[PartyID] [int] NULL,
	[MatchedODSEmailAddressID] [int] NULL,
	[EventCategory] [varchar](50) NULL,
	[EventCategoryID] [int] NULL,
	[MatchedODSVehicleID] [int] NULL
) ON [PRIMARY]
GO
