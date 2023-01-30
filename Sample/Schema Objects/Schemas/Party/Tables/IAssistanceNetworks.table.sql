CREATE TABLE [Party].[IAssistanceNetworks]
(
	[PartyIDFrom] [dbo].[PartyID] NOT NULL,
	[PartyIDTo] [dbo].[PartyID] NOT NULL,
	[RoleTypeIDFrom] [dbo].[RoleTypeID] NOT NULL,
	[RoleTypeIDTo] [dbo].[RoleTypeID] NOT NULL,
	[IAssistanceCentreCode] NVARCHAR(50) NOT NULL,
	[FromDate] [datetime2](7) NOT NULL,
	[IAssistanceCentreName] NVARCHAR(200) NULL,
	[CountryID] INT NULL
);