CREATE TABLE [Party].[PartyTypes]
(
    [PartyTypeID]              dbo.PartyTypeID       IDENTITY (1, 1) NOT NULL,
    [PartyType]            NVARCHAR (255) NOT NULL,
    [PartyTypeAbbreviated] NVARCHAR (255) NULL,
	DefaultPartyExclusionCategoryID dbo.ExclusionCategoryID NOT NULL
);

