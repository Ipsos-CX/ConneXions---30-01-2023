-- ========================================================================
-- Author:      Karl Singleton
-- Create date: 08/31/2017
-- Description:	Sets an NWB Sample Upload Request
-- ========================================================================
CREATE PROCEDURE [NwbSampleUploadRequest_sp_Set]
	@p_projectId NVARCHAR(512),
	@p_connectionString NVARCHAR(512),
	@p_tableName NVARCHAR(512),
	@p_hubName NVARCHAR(512),
	@p_targetServerName NVARCHAR(512),
	@p_reRandomizeSortId BIT
AS
BEGIN

	SET NOCOUNT ON;
	
	INSERT INTO NwbSampleUpload_ut_Request
		(
			[ProjectId],
			[fkSampleUploadInputTypeKey],
			[InputPath],
			[InputParameter],
			[HubName],
			[TargetServerName],
			[ReRandomizeSortId], 
			[CreatedTimestamp],
			[ModifiedTimestamp]
		)
	VALUES
		(
			@p_projectId,
			2,
			@p_connectionString,
			@p_tableName,
			@p_hubName,
			@p_targetServerName,
			@p_reRandomizeSortId,
			GETUTCDATE(),
			GETUTCDATE()
		)
END
