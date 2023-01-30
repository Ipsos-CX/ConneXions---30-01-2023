/* -- CGR 14-06-2016 - Removed as part of BUG 11771 - This index can be fully removed in the fullness of time	
					-- but for now I will leave in place but deactivated
					

CREATE NONCLUSTERED INDEX [IX_Audit_META_VehiclesAndOrganisations_OrganisationNameChecksum_VehicleChecksum]
    ON [Audit].[META_VehiclesAndOrganisations]([OrganisationNameChecksum] ASC, [VehicleChecksum] ASC)
    INCLUDE([MatchedOrganisationID]) WITH (ALLOW_PAGE_LOCKS = ON, ALLOW_ROW_LOCKS = ON, PAD_INDEX = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF, ONLINE = OFF, MAXDOP = 0);

*/