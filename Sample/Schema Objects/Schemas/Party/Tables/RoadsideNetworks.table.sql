CREATE TABLE [Party].[RoadsideNetworks]
(
	[PartyIDFrom] [dbo].[PartyID] NOT NULL,
	[PartyIDTo] [dbo].[PartyID] NOT NULL,
	[RoleTypeIDFrom] [dbo].[RoleTypeID] NOT NULL,
	[RoleTypeIDTo] [dbo].[RoleTypeID] NOT NULL,
	[RoadsideNetworkCode] [dbo].[RoadsideNetworkCode] NOT NULL,
	[FromDate] [datetime2](7) NOT NULL,
	[RoadsideNetworkName] [dbo].[RoadsideNetworkName] NULL,
	[CountryID]		  INT NULL
);

