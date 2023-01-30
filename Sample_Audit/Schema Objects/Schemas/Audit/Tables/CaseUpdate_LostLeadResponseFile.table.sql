CREATE TABLE [Audit].CaseUpdate_LostLeadResponseFile (
	[AuditID]			dbo.AuditID		NULL,
	[AuditItemID]		dbo.AuditItemID	NULL,
    [CaseID]			INT				NULL,
    [PartyID]			INT				NULL,
    [CasePartyCombinationValid]  BIT	NULL,
    [DateProcessed]     DATETIME2       NULL,
    
    [ResponseDate]					NVARCHAR(50)	NULL,
    [LeadStatus]					NVARCHAR(50)	NULL,
	[ReasonsCode]					NVARCHAR(1000)	NULL,
	[ResurrectedFlag]				NVARCHAR(50)	NULL,
	[BoughtElsewhereCompetitorFlag] NVARCHAR(50)	NULL,
	[BoughtElsewhereJLRFlag]		NVARCHAR(50)	NULL,
	[VehicleLostBrand]				NVARCHAR(50)	NULL,
	[VehicleLostModelRange]			NVARCHAR(50)	NULL
);

