CREATE TABLE [dbo].[DailyUnMatchedVINs]
(
	[VIN] [nvarchar](100) NOT NULL,
	[ModelDescription] [nvarchar](200) NULL,
	[FileName] [nvarchar](100) NOT NULL, 
	[ActionDate] DATETIME2 (7) NOT NULL
)
