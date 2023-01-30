CREATE TABLE [SampleReport].[SampleFilesSchedule] (
	[Brand]				NVARCHAR(510) NOT NULL,
	[Market]			VARCHAR(200) NOT NULL,
	[Questionnaire]		VARCHAR(255) NOT NULL,
    [FileName]          VARCHAR (100) NOT NULL,
    [DueDate]			DATETIME2 (7) NOT NULL
);

