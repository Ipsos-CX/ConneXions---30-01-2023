ALTER TABLE [NWB].[SurveyUploadInfo]
	ADD CONSTRAINT [FK_SurveyUploadInfo_TargetServerName]
	FOREIGN KEY (TargetServerName) 
	REFERENCES NWB.TargetServers (TargetServerName)
	ON DELETE NO ACTION ON UPDATE NO ACTION;

