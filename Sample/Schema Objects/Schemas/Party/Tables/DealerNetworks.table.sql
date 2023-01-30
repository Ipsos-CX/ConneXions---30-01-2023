CREATE TABLE [Party].[DealerNetworks] (
    [PartyIDFrom]     dbo.PartyID            NOT NULL,
    [PartyIDTo]       dbo.PartyID            NOT NULL,
    [RoleTypeIDFrom]  dbo.RoleTypeID       NOT NULL,
    [RoleTypeIDTo]    dbo.RoleTypeID       NOT NULL,
    [DealerCode]      dbo.DealerCode  NOT NULL,
    [FromDate]        DATETIME2       NOT NULL,
    [DealerShortName] dbo.DealerName NULL,
    [CountryID]		  INT NULL
);

