CREATE PROC Meta.uspBusinessEvents

AS

/*
	Purpose:	Drops, recreates and reindexes Meta.BusinessEvents META table which is a denormalised set of data used to simplify complex views.
		
	Version			Date			Developer			Comment
	1.0				$(ReleaseDate)		Simon Peacock		Created from [Prophet-ODS].dbo.uspIP_Update_META_SELECTIONS_BusinessEvents

*/

SET NOCOUNT ON

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

	-- DROP AND RECREATE THE TABLE
	IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'Meta.BusinessEvents') AND type in (N'U'))
	BEGIN
		DROP TABLE Meta.BusinessEvents
	END
	
	CREATE TABLE Meta.BusinessEvents
	(
		 EventID dbo.EventID NOT NULL
		,VehicleRoleTypeID dbo.RoleTypeID NULL
		,PartyID dbo.PartyID NULL
		,OrganisationName dbo.OrganisationName NULL
	)
	
	INSERT INTO Meta.BusinessEvents
	(
		 EventID
		,VehicleRoleTypeID
		,PartyID
		,OrganisationName
	)
	SELECT DISTINCT
		 EventID
		,VehicleRoleTypeID
		,PartyID
		,OrganisationName
	FROM Meta.vwBusinessEvents


	ALTER TABLE Meta.BusinessEvents
	ADD CONSTRAINT PK_META_BusinessEvents PRIMARY KEY CLUSTERED (EventID) 
	WITH  FILLFACTOR = 100  ON [PRIMARY] 
	
	CREATE NONCLUSTERED INDEX IX_Meta_BusinessEvents_EventID
	ON Meta.BusinessEvents (EventID)
	INCLUDE (OrganisationName)
	
	
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