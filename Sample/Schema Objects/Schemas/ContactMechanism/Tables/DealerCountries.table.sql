CREATE TABLE [ContactMechanism].[DealerCountries] (
    [PartyIDFrom]    dbo.PartyID           NOT NULL,
    [PartyIDTo]      dbo.PartyID           NOT NULL,
    [RoleTypeIDFrom] dbo.RoleTypeID      NOT NULL,
    [RoleTypeIDTo]   dbo.RoleTypeID      NOT NULL,
    [DealerCode]     dbo.DealerCode NOT NULL,
    [CountryID]      dbo.CountryID      NOT NULL
);

