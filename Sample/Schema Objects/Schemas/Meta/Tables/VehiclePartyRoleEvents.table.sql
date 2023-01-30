CREATE TABLE [Meta].[VehiclePartyRoleEvents] (
    [EventID]         [dbo].[EventID]   NOT NULL,
    [VehicleID]       [dbo].[VehicleID] NOT NULL,
    [Purchaser]       [dbo].[PartyID]   NULL,
    [RegisteredOwner] [dbo].[PartyID]   NULL,
    [PrincipleDriver] [dbo].[PartyID]   NULL,
    [OtherDriver]     [dbo].[PartyID]   NULL,
    [FleetManager]	  [dbo].[PartyID]   NULL
);



