CREATE TABLE [Event].[CaseLostLeadResponses] (
    [CaseID]			dbo.CaseID   NOT NULL,
    [LoadedToConnexions]			DATETIME2	 NULL,
    [ResponseDate]					DATETIME2	 NULL,
    [LeadStatus]					NVARCHAR(50)	NULL,
	[ReasonsCode]					NVARCHAR(1000)	NULL,
	[ResurrectedFlag]				NVARCHAR(50)	NULL,
	[BoughtElsewhereCompetitorFlag] NVARCHAR(50)	NULL,
	[BoughtElsewhereJLRFlag]		NVARCHAR(50)	NULL,
	[VehicleLostBrand]				NVARCHAR(50)	NULL,
	[VehicleLostModelRange]			NVARCHAR(50)	NULL
);

