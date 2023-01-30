CREATE TABLE [RollbackSample].[Audit_People]
(
	[AuditID]			 dbo.AuditID	NOT NULL,
    [AuditItemID]        [dbo].[AuditItemID] NOT NULL,
    [PartyID]            [dbo].[PartyID]     NOT NULL,
    [FromDate]           DATETIME2 (7)       NOT NULL,
    [TitleID]            [dbo].[TitleID]     NULL,
    [Title]              [dbo].[Title]       NULL,
    [Initials]           [dbo].[NameDetail]  NULL,
    [FirstName]          [dbo].[NameDetail]  NULL,
    [FirstNameOrig]      [dbo].[NameDetail]  NULL,
    [MiddleName]         [dbo].[NameDetail]  NULL,
    [LastName]           [dbo].[NameDetail]  NULL,
    [LastNameOrig]       [dbo].[NameDetail]  NULL,
    [SecondLastName]     [dbo].[NameDetail]  NULL,
    [SecondLastNameOrig] [dbo].[NameDetail]  NULL,
    [GenderID]           [dbo].[GenderID]    NULL,
    [BirthDate]          DATETIME2 (7)       NULL,
    [MonthAndYearOfBirth] dbo.NameDetail	 NULL,
	[PreferredMethodOfContact]  dbo.NameDetail NULL
);
