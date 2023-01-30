CREATE TABLE [CustomerUpdate].[NonSolicitationRemoval] (
	[ID]							INT IDENTITY(1,1)		NOT NULL ,
    [AuditID]                        dbo.AuditID			NULL,
    [AuditItemID]                    dbo.AuditItemID		NULL,
    [ParentAuditItemID]              dbo.AuditItemID        NULL,   
    [FullName]						 NVARCHAR(500)			NOT NULL,
    [VIN]							 dbo.VIN				NOT NULL,    
    [EventDateOrig]					NVARCHAR(50)			NULL,    
    [EventDate]						DATE					NULL,    
    [DateLoaded]                     DATETIME2				NOT NULL,
    [DateProcessed]                  DATETIME2				NULL
);

