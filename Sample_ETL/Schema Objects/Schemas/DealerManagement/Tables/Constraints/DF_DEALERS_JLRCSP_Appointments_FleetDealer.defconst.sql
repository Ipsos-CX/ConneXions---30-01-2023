ALTER TABLE [DealerManagement].[DEALERS_JLRCSP_Appointments]
    ADD CONSTRAINT [DF_DEALERS_JLRCSP_Appointments_FleetDealer] DEFAULT ((0)) FOR [FleetDealer];

