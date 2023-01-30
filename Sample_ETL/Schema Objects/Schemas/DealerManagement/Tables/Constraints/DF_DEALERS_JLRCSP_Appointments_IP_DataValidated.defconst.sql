ALTER TABLE [DealerManagement].[DEALERS_JLRCSP_Appointments]
    ADD CONSTRAINT [DF_DEALERS_JLRCSP_Appointments_IP_DataValidated] DEFAULT ((0)) FOR [IP_DataValidated];

