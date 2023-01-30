CREATE TABLE [dbo].[Weekly]
(
		VIN						VARCHAR (50),
		VehicleID				BIGINT,
		ModelDescription		VARCHAR(200),
		CountryID				INT,
		BusinessRegion			VARCHAR(200),
		[FileName]				VARCHAR(200),
		ActionDate				DATETIME2,
		Uncoded					BIT,
		EventID					BIGINT
)
