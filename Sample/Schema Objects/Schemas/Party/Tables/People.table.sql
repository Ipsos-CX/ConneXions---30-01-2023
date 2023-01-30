CREATE TABLE [Party].[People] (
    [PartyID]					dbo.PartyID		NOT NULL,
    [FromDate]					DATETIME2			NOT NULL,
    [TitleID]					dbo.TitleID			NULL,
    [Initials]					dbo.NameDetail		NULL,
    [FirstName]					dbo.NameDetail		NULL,
    [MiddleName]				dbo.NameDetail		NULL,
    [LastName]					dbo.NameDetail		NULL,
    [SecondLastName]			dbo.NameDetail		NULL,
    [GenderID]					dbo.GenderID		NULL,
    [BirthDate]					DATETIME2			NULL,
    [MonthAndYearOfBirth]		dbo.NameDetail		NULL,
    [PreferredMethodOfContact]	dbo.NameDetail		NULL,
	MergedDate					DATETIME2			NULL,				
	ParentFlag					dbo.ParentFlag		NULL,
	ParentFlagDate				DATETIME2			NULL,
	UnMergedDate				DATETIME2			NULL,
    [NameChecksum] AS (BINARY_CHECKSUM(LEFT(COALESCE(NULLIF(UPPER([FirstName]), ''), NULLIF(UPPER([INITIALS]), ''),N''),(1)),REPLACE(ISNULL(UPPER([LastName]),N''),N' ',N''))) PERSISTED,
	UseLatestName				BIT					NOT NULL
);

