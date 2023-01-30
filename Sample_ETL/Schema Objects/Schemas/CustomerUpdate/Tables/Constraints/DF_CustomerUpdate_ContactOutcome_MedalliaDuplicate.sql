ALTER TABLE [CustomerUpdate].[ContactOutcome]
	ADD CONSTRAINT [DF_CustomerUpdate_ContactOutcome_MedalliaDuplicate]
	DEFAULT 0
	FOR MedalliaDuplicate
