CREATE TABLE [dbo].[DailyBounceBack]
(
	AuditID BIGINT        NOT NULL, 
	FileName [nvarchar](100) NOT NULL,
	FileRowCount INT           NULL,
	ActionDate DATETIME2 (7) NOT NULL,
	LoadSuccess [varchar](50) NULL,
	LoadedRowCount INT           NULL



	

)
