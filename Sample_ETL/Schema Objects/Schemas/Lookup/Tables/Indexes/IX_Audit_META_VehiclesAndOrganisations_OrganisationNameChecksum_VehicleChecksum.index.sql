CREATE NONCLUSTERED INDEX [IX_Lookup_META_VehiclesAndOrganisations_OrganisationNameChecksum_VehicleChecksum]
    ON [Lookup].[META_VehiclesAndOrganisations]([OrganisationNameChecksum] ASC, [VehicleChecksum] ASC)
    INCLUDE([MatchedOrganisationID]) WITH (ALLOW_PAGE_LOCKS = ON, ALLOW_ROW_LOCKS = ON, PAD_INDEX = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF, ONLINE = OFF, MAXDOP = 0);

