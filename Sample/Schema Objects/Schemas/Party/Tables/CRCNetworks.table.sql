CREATE TABLE [Party].[CRCNetworks]
(
	[PartyIDFrom] [dbo].[PartyID] NOT NULL,
	[PartyIDTo] [dbo].[PartyID] NOT NULL,
	[RoleTypeIDFrom] [dbo].[RoleTypeID] NOT NULL,
	[RoleTypeIDTo] [dbo].[RoleTypeID] NOT NULL,
	[CRCCentreCode] [dbo].[CRCNetworkCode] NOT NULL,
	[FromDate] [datetime2](7) NOT NULL,
	[CRCCentreName] [dbo].[CRCNetworkName] NULL,
	[CountryID] INT NULL
);