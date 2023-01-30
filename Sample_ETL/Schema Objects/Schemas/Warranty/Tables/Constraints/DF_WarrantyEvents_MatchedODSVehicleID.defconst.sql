ALTER TABLE [Warranty].[WarrantyEvents]
    ADD CONSTRAINT [DF_WarrantyEvents_MatchedODSVehicleID] DEFAULT (0) FOR [MatchedODSVehicleID];

