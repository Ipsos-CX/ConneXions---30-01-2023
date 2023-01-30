ALTER TABLE [DealerManagement].[DEALERS_JLRCSP_Flat]
    ADD CONSTRAINT [DF_DEALERS_JLRCSP_Flat_FleetDealer] DEFAULT ((0)) FOR [FleetDealer];

