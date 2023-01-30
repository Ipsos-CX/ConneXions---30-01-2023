CREATE TABLE [Audit].[InternalUpdate_ReissueInvite] (
    [PartyID]                   dbo.PartyID            NOT NULL,
    [CaseID]                    dbo.CaseID			NOT NULL,
    [Reoutput]					varchar(10)			NULL,
    [AuditID]                   dbo.AuditID			NOT NULL,
    [AuditItemID]               dbo.AuditItemID     NOT  NULL,
    [ParentAuditItemID]         dbo.AuditItemID     NULL,
    [CasePartyCombinationValid] BIT					NOT NULL,
    NewSelectionRequirementID	dbo.RequirementID	NULL,
    NewCaseID					dbo.CaseID			NULL,    
    [DateProcessed]             DATETIME2			NOT NULL,
    EventCategoryID				dbo.EventTypeID		NULL
);

