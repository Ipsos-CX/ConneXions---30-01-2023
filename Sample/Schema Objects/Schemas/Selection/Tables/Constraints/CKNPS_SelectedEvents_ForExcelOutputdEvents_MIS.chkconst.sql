ALTER TABLE [Selection].[NPS_SelectedEvents_ForExcelOutput]
	ADD CONSTRAINT [CKNPS_SelectedEvents_ForExcelOutputdEvents_MIS] 
	CHECK  ([MIS]='6 MIS' OR [MIS]='18 MIS' OR [MIS]='30 MIS')