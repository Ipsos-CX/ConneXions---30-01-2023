CREATE TABLE [SelectionOutput].[DealerPilotOutputCodes] (
	[DealerCode]			[dbo].[DealerCode] NOT NULL,
	[Market]				dbo.Country NOT NULL,
	[EventCategory]			VARCHAR(50) NOT NULL,
	[BaseITYPE]				VARCHAR(5)  NOT NULL,
    [PilotCodeForITYPE]		VARCHAR(10)  NULL,
    [PilotQuestionnaire]	INT NULL
);

