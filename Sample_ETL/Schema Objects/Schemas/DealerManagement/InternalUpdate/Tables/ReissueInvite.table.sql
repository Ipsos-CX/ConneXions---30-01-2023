CREATE TABLE [InternalUpdate].[ReissueInvite] (
	[ID]							INT IDENTITY(1,1) NOT NULL ,
    [PartyID]                   dbo.PartyID            NOT NULL,
    [CaseID]                    dbo.CaseID         NOT NULL,
    [Reoutput]					varchar(10)			NOT NULL,
    [AuditID]                   dbo.AuditID         NULL,
    [AuditItemID]               dbo.AuditItemID         NULL,
    [ParentAuditItemID]         dbo.AuditItemID         NULL,
    [CasePartyCombinationValid] BIT					NOT NULL,
    NewSelectionRequirementID	dbo.RequirementID	NULL,
    NewCaseID					dbo.CaseID			NULL
);

