-- ========================================================================
-- Author:      Karl Singleton
-- Create date: 08/31/2017
-- Description:	Gets the availavble NWB Sample Upload Requests
-- ========================================================================
CREATE PROCEDURE [NwbSampleUploadRequests_sp_Get]
	
AS
BEGIN

	SET NOCOUNT ON;
	
	DECLARE @v_NwbSampleUploadRequests TABLE
		(
			[NwbSampleUploadRequestKey] INT NOT NULL,
			[ProjectId] nvarchar(512) NOT NULL,
			[SampleUploadInputTypeKey] INT NOT NULL,
			[InputPath] nvarchar(512) NOT NULL,
			[InputParameter] nvarchar(512) NOT NULL,
			[HubName] nvarchar(512) NOT NULL,
			[TargetServerName] nvarchar(512) NOT NULL,
			[ReRandomizeSortId] BIT NOT NULL, 
			[CreatedTimestamp] DATETIME NOT NULL,
			[ModifiedTimestamp] DATETIME NOT NULL
		)

	BEGIN TRANSACTION
	INSERT INTO @v_NwbSampleUploadRequests
		(
			NwbSampleUploadRequestKey,
			ProjectId,
			SampleUploadInputTypeKey,
			InputPath,
			InputParameter,
			HubName,
			TargetServerName,
			ReRandomizeSortId, 
			CreatedTimestamp,
			ModifiedTimestamp
		)
	SELECT 
		pkNwbSampleUploadRequestKey,
		ProjectId,
		fkSampleUploadInputTypeKey,
		InputPath,
		InputParameter,
		HubName,
		TargetServerName,
		ReRandomizeSortId, 
		CreatedTimestamp,
		ModifiedTimestamp
	FROM NwbSampleUpload_ut_Request WITH(UPDLOCK, READPAST)
	WHERE fkSampleUploadStatusKey IS NULL
	ORDER BY pkNwbSampleUploadRequestKey
	
	UPDATE NwbSampleUpload_ut_Request
	SET fkSampleUploadStatusKey = 0,
		QueuedTimestamp = GETUTCDATE(),
		ModifiedTimestamp = GETUTCDATE()
	WHERE pkNwbSampleUploadRequestKey IN
										(
											SELECT NwbSampleUploadRequestKey
											FROM @v_NwbSampleUploadRequests
										)
	
	COMMIT
	SELECT 
		NwbSampleUploadRequestKey [Key],
		CreatedTimestamp,
		ModifiedTimestamp,
		ProjectId,
		SampleUploadInputTypeKey [InputType],
		InputPath,
		InputParameter,
		HubName,
		TargetServerName,
		ReRandomizeSortId 
	FROM @v_NwbSampleUploadRequests
END