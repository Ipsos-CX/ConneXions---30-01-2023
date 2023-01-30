CREATE TABLE [CaseUpdate].[CRMHeaderFile]
(
	[ID]				INT IDENTITY(1,1) NOT NULL ,
	[AuditID]			dbo.AuditID		NULL,
	[AuditItemID]		dbo.AuditItemID	NULL,
    [CaseID]			INT				NULL,
    [PartyID]			INT				NULL,
    [CasePartyCombinationValid]  BIT	NULL,
    [DateProcessed]     DATETIME2       NULL,
    [ResponseDate]		NVARCHAR(20)	NULL,
    [RedFlag]			NVARCHAR(20)	NULL,
    [GoldFlag]			NVARCHAR(20)	NULL
);