ALTER TABLE [NWB].[SurveyUploadInfo]
	ADD CONSTRAINT [FK_SurveyUploadInfo_LocalServerName]
	FOREIGN KEY (LocalServerName) 
	REFERENCES NWB.LocalServers (LocalServerName)
	ON DELETE NO ACTION ON UPDATE NO ACTION;

