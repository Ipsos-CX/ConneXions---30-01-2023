CREATE TABLE [Vehicle].[PHEVModels]
(
	[ModelID]			[dbo].[ModelID] NOT NULL,
	[ModelDescription]	[varchar](50) NOT NULL,
	[EngineDescription] [varchar](500) NULL,
	[VINPrefix]			[varchar](4) NOT NULL,
	[VINCharacter]		[varchar](1) NOT NULL,
	[EngineTypeID]		INT NULL,
)
