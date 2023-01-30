ALTER TABLE [Selection].[NPS_SelectedEvents]
	ADD CONSTRAINT [CK_NPS_SelectedEvents_MIS] 
	CHECK  (MIS = '6 MIS' OR MIS = '18 MIS' OR MIS = '30 MIS')
