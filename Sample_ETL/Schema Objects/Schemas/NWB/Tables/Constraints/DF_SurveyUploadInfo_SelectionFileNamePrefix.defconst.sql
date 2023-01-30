ALTER TABLE [NWB].[SurveyUploadInfo]
	ADD CONSTRAINT [DF_SurveyUploadInfo_SelectionFileNamePrefix] DEFAULT ('') FOR [SelectionFileNamePrefix]
