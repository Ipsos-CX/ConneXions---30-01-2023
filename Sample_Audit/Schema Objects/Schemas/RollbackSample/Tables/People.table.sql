CREATE TABLE [RollbackSample].[People]
(
	AuditID						dbo.AuditID			NOT NULL,
    [PartyID]					dbo.PartyID			NOT NULL,
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
	UnMergedDate				DATETIME2			NULL
 );

