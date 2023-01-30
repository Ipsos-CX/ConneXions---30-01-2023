CREATE PROC dbo.uspGetSampleFileDestinationFolder
(
	@FileNamePrefix VARCHAR(50),
	@FileNameExtension VARCHAR(50),
	@ErrorPath VARCHAR(50)
)
AS

/*
	Purpose:	Gets the sample file destination path for the supplied file prefix and extension.  If we have no value return the default error folder
		
	Version			Date			Developer			Comment
	1.0				$(ReleaseDate)		Simon Peacock		Created
	1.1				29/08/2013		Chris Ross			Modified to check the whole of the File name part against 
														the prefix as we were only taking from the 3rd underscore char ("_")
														and this stopped the VISTA files loading (8969 - France VISTA files)
*/

SET NOCOUNT ON

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

	DECLARE @SampleFileID INT
	DECLARE @SampleFileDestination VARCHAR(255)
	
	SELECT @SampleFileDestination = SampleFileDestination, @SampleFileID = SampleFileID
	FROM dbo.vwBrandMarketQuestionnaireSampleMetadata
	WHERE @FileNamePrefix like (SampleFileNamePrefix + '%')  -- v1.1
	AND SampleFileExtension = @FileNameExtension
	
	SELECT ISNULL(@SampleFileID, 0) AS SampleFileID, ISNULL(@SampleFileDestination, @ErrorPath + '\Errors\') AS SampleFileDestination

END TRY
BEGIN CATCH

	SELECT
		 @ErrorNumber = Error_Number()
		,@ErrorSeverity = Error_Severity()
		,@ErrorState = Error_State()
		,@ErrorLocation = Error_Procedure()
		,@ErrorLine = Error_Line()
		,@ErrorMessage = Error_Message()

	EXEC [$(ErrorDB)].dbo.uspLogDatabaseError
		 @ErrorNumber
		,@ErrorSeverity
		,@ErrorState
		,@ErrorLocation
		,@ErrorLine
		,@ErrorMessage
		
	RAISERROR(@ErrorNumber, @ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorLine)
		
END CATCH	