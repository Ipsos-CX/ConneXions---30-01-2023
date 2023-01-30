CREATE PROC [Audit].uspCheckFileExistsUsingSHA256Hash
	@FileName		VARCHAR(100),
	@FileChecksum	VARCHAR(100)

AS

/*
	Purpose:		Checks to see if a file with the same name and SHA checksum value has previously been loaded
	
	Release		Version			Date			Developer			Comment
	LIVE		1.0				2022-07-04		Eddie Thomas		Created from uspCheckFileExists

*/

IF (
	SELECT	COUNT(*) 
	FROM	[Audit].[vwIncomingFiles]
	WHERE	FileName		= @FileName AND 
			SHA256HashCode	= @FileChecksum AND 
			LoadSuccess		= 1 
) > 0 
BEGIN
	SELECT CAST(1 AS BIT) AS FileExists
END
ELSE 
BEGIN
	SELECT CAST(0 AS BIT) AS FileExists
END