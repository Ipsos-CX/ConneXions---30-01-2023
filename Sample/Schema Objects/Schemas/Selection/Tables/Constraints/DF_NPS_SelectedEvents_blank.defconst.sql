ALTER TABLE [Selection].[NPS_SelectedEvents]
   ADD CONSTRAINT [DF_NPS_SelectedEvents_blank] 
   DEFAULT ' '
   FOR blank

