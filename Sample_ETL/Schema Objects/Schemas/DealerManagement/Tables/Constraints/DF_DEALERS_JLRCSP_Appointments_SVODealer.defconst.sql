ALTER TABLE [DealerManagement].[DEALERS_JLRCSP_Appointments]
    ADD CONSTRAINT [DF_DEALERS_JLRCSP_Appointments_SVODealer] DEFAULT ((0)) FOR [SVODealer];

