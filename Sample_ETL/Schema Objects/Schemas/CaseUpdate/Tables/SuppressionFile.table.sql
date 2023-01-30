CREATE TABLE [CaseUpdate].[SuppressionFile]
(
	[ID]				INT IDENTITY(1,1) NOT NULL ,
	[AuditID]			dbo.AuditID		NULL,
	[AuditItemID]		dbo.AuditItemID	NULL,
    [CaseID]			INT		NULL,
    [PartyID]			INT		    NULL
);