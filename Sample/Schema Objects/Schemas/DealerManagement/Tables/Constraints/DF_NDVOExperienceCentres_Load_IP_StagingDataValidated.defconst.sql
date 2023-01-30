ALTER TABLE [DealerManagement].[NDVOExperienceCentres_Load]
	ADD CONSTRAINT [DF_NDVOExperienceCentres_Load_IP_StagingDataValidated]
	DEFAULT 0
	FOR [IP_StagingDataValidated]
