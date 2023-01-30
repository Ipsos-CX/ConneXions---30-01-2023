CREATE TABLE [Lookup].[META_VehiclesAndOrganisations] (
    [VehicleID]                [dbo].[VehicleID] NOT NULL,
    [MatchedOrganisationID]    [dbo].[PartyID]   NOT NULL,
    [OrganisationName]			[dbo].[OrganisationName] NOT NULL,
    [VIN]                      [dbo].[VIN]       NOT NULL,
    [VehicleChecksum]          INT               NULL,
    [OrganisationNameChecksum] INT               NULL
);
