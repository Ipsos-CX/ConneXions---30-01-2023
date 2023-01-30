CREATE TABLE [Requirement].[AdhocSelectionRequirements]
(
	[RequirementID] [dbo].[RequirementID] NOT NULL,
	[BrandID] [dbo].[ManufacturerPartyID] NOT NULL,
	[QuestionnaireID] [int] NOT NULL,
	[StartDate] [datetime2](7) NOT NULL,
	[EndDate] [datetime2](7) NOT NULL,
	[PostCode] [dbo].[Postcode] NULL,
	[SelectionDate] [datetime2](7) NOT NULL,
	[SelectionStatusTypeID] [dbo].[SelectionStatusTypeID] NOT NULL,
	[SelectionTypeID] [dbo].[SelectionTypeID] NULL,
	[DateLastRun] [datetime2](7) NULL,
	[RecordsSelected] [int] NULL,
	[DateOutput] [datetime2](7) NULL,
	[ScheduledRunDate] [datetime2](7) NULL
)
