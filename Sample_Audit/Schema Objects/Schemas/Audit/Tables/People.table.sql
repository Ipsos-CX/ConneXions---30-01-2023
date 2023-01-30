CREATE TABLE [Audit].[People] (
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
    [NameChecksum]       AS                  (BINARY_CHECKSUM(LEFT(COALESCE(NULLIF(UPPER([FirstName]), ''), NULLIF(UPPER([INITIALS]), ''),N''),(1)),REPLACE(ISNULL(UPPER([LastName]),N''),N' ',N''))) PERSISTED,
	[MonthAndYearOfBirth] dbo.NameDetail	 NULL,
	[PreferredMethodOfContact]  dbo.NameDetail NULL,
	[UseLatestName]		BIT					NOT NULL

);



