-- ========================================================================
-- Author:      Karl Singleton
-- Create date: 08/31/2017
-- Description:	Sets the log text for a given request key
-- ========================================================================
CREATE PROCEDURE [NwbSampleUploadRequestLog_sp_Set]
	@p_requestKey INT,
	@p_logText NVARCHAR(1024)
AS
BEGIN

	SET NOCOUNT ON;

	INSERT INTO NwbSampleUpload_ut_RequestLog(fkNwbSampleUploadRequestKey, logText, createdTimestamp, modifiedTimestamp)
	VALUES (@p_requestKey, @p_logText, GETUTCDATE(), GETUTCDATE())

END