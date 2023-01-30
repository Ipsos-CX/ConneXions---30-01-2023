CREATE TABLE [CaseUpdate].[ResponseFile]
(
	[ID]				INT IDENTITY(1,1) NOT NULL ,
	[AuditID]			dbo.AuditID		NULL,
	[AuditItemID]		dbo.AuditItemID	NULL,
    [CaseID]			INT		NULL,
    [PartyID]			INT		    NULL,
	[ClosureDateOrig]	VARCHAR(10)		NULL,	
    [ClosureDate]		DATETIME2       NULL,
    [AnonymityDealer]	BIT				NULL,
    [AnonymityManufacturer] BIT			NULL
);