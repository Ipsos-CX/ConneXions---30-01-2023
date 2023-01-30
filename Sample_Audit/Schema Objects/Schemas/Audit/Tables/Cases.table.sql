CREATE TABLE [Audit].[Cases]
(
	[AuditItemID]	dbo.AuditItemID   NOT NULL,
	[PartyCaseIDComboValid]	BIT	NULL,
	[PartyID]		dbo.PartyID		NULL,			
    [CaseID]		dbo.CaseID	NULL,
    [CaseStatusTypeID] TINYINT       NULL,
    [CreationDate]     DATETIME2       NULL,
	[ClosureDateOrig]  VARCHAR(10) NULL,	
    [ClosureDate]      DATETIME2       NULL,
    [OnlineExpiryDate] DATETIME2		NULL,
    [SelectionOutputPassword] VARCHAR(10)	 NULL,
    [AnonymityDealer] BIT NULL,
    [AnonymityManufacturer] BIT NULL
);
