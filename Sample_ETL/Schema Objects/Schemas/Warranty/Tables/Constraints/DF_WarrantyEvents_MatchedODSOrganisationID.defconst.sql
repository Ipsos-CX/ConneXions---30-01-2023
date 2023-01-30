ALTER TABLE [Warranty].[WarrantyEvents]
    ADD CONSTRAINT [DF_WarrantyEvents_MatchedODSOrganisationID] DEFAULT (0) FOR [MatchedODSOrganisationID];

