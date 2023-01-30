ALTER TABLE [Selection].[NPS_SelectedEvents]
   ADD CONSTRAINT [DF_NPS_SelectedEvents_SampleFlag] 
   DEFAULT 1
   FOR SampleFlag

