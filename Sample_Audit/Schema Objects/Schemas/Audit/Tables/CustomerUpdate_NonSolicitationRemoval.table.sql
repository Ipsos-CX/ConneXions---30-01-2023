CREATE TABLE [Audit].[CustomerUpdate_NonSolicitationRemoval] (	
    [AuditID]                        dbo.AuditID			NULL,
    [AuditItemID]                    dbo.AuditItemID		NULL,
    [ParentAuditItemID]              dbo.AuditItemID        NULL,    
    [FullName]						 NVARCHAR(500)			NOT NULL,
    [VIN]							 dbo.VIN				NOT NULL,    
    [EventDateOrig]					NVARCHAR(20)				NOT NULL,    
    [EventDate]						DATE					NULL,    
    [DateLoaded]                     DATETIME2				NOT NULL,
    [DateProcessed]                  DATETIME2				NULL,
    [NonSolicitationID]              dbo.NonSolicitationID            NULL,
    [PartyID]                        dbo.PartyID            NULL,
    EventID							dbo.EventID   NULL
);

