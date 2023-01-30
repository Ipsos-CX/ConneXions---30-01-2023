CREATE TABLE [NWB].[SurveyUploadInfo]
(
	LocalServerName	NVARCHAR(512) NOT NULL,
	Questionnaire	VARCHAR(255) NOT NULL,
	ProjectId		NVARCHAR(512) NOT NULL,
	UploadTableName VARCHAR(512) NOT NULL,
	TargetServerName NVARCHAR(512) NOT NULL
)
