ALTER TABLE [Warranty].[WarrantyEvents]
    ADD CONSTRAINT [DF_WarrantyEvents_ServiceDealerCodeOriginatorPartyID] DEFAULT (0) FOR [ServiceDealerCodeOriginatorPartyID];

