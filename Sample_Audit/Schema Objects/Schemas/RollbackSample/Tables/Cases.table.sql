CREATE TABLE [RollbackSample].[Cases]
(
	[AuditID]					dbo.AuditID	NOT NULL,
    [CaseID]					dbo.CaseID  NOT NULL,
    [CaseStatusTypeID]			INT			NOT NULL,
    [CreationDate]				DATETIME2   NOT NULL,
    [ClosureDate]				DATETIME2   NULL,
    [OnlineExpiryDate]			DATETIME2	NULL,
    [SelectionOutputPassword]	VARCHAR(200) NULL,
    [AnonymityDealer]			BIT			NULL,
    [AnonymityManufacturer]		BIT			NULL
);

