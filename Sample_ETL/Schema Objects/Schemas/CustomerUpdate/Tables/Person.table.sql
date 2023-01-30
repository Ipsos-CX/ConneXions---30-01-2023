CREATE TABLE [CustomerUpdate].[Person] (
	[ID]							INT IDENTITY(1,1) NOT NULL ,
    [PartyID]                   dbo.PartyID            NOT NULL,
    [CaseID]                    dbo.CaseID         NOT NULL,
    [Title]                     dbo.Title NULL,
    [FirstName]                 dbo.NameDetail NULL,
    [LastName]                  dbo.NameDetail NULL,
    [SecondLastName]            dbo.NameDetail NULL,
    [AuditID]                   dbo.AuditID         NULL,
    [AuditItemID]               dbo.AuditItemID         NULL,
    [ParentAuditItemID]         dbo.AuditItemID         NULL,
    [TitleID]         dbo.TitleID            NULL,
    [CasePartyCombinationValid] BIT            NOT NULL
);

