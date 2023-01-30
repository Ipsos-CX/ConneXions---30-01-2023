/* -- CGR 14-06-2016 - Removed as part of BUG 11771 - This table can be fully removed in the fullness of time	
					-- but for now I will leave in place but deactivated
					
					
CREATE TABLE [Audit].[META_VehiclesAndOrganisations] (
    [VehicleID]                [dbo].[VehicleID] NOT NULL,
    [MatchedOrganisationID]    [dbo].[PartyID]   NOT NULL,
    [OrganisationName]			[dbo].[OrganisationName] NOT NULL,
    [VIN]                      [dbo].[VIN]       NOT NULL,
    [VehicleChecksum]          INT               NULL,
    [OrganisationNameChecksum] INT               NULL
);

*/