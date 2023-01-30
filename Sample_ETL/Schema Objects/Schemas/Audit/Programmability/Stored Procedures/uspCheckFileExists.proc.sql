CREATE PROC [Audit].uspCheckFileExists
	@FileName VARCHAR(100),
	@FileChecksum INT
AS

/*
	Purpose:	Checks to see if a file with the same name and checksum value has previously been loaded
	
	Version			Date			Developer			Comment
	1.0				$(ReleaseDate)		Simon Peacock		Created from [Prophet-ETL].dbo.uspVWTLOAD_CheckFileExists

*/

IF (
	SELECT COUNT(*) 
	FROM  [Audit].[vwIncomingFiles]
	WHERE FileName = @FileName
	AND FileChecksum = @FileChecksum 
	AND LoadSuccess = 1 
) > 0 
BEGIN
	SELECT CAST(1 AS BIT) AS FileExists
END
ELSE 
BEGIN
	SELECT CAST(0 AS BIT) AS FileExists
END




