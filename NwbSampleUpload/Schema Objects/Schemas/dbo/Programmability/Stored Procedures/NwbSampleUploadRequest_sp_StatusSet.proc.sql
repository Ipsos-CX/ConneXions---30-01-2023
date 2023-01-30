-- ========================================================================
-- Author:      Karl Singleton
-- Create date: 08/31/2017
-- Description:	Sets the status and timestamps for a given request key
-- ========================================================================
CREATE PROCEDURE [NwbSampleUploadRequest_sp_StatusSet]
	@p_requestKey INT,
	@p_statusKey INT,
	@p_startedTimestamp DATETIME,
	@p_completedTimestamp DATETIME
AS
BEGIN

	SET NOCOUNT ON;

	UPDATE NwbSampleUpload_ut_Request
	SET fkSampleUploadStatusKey = @p_statusKey,
		startedTimestamp = @p_startedTimestamp,
		completedTimestamp = @p_completedTimestamp,
		modifiedTimestamp = GETUTCDATE()
	WHERE pkNwbSampleUploadRequestKey = @p_requestKey

END