CREATE PROC [Meta].[uspBusinessEventsVariableBuild]

(
	@BuildType  VARCHAR(50)
)

AS

/*
	Purpose:	Drops, recreates and reindexes Meta.BusinessEvents META table which is a denormalised set of data used to simplify complex views.
				Variable build, FULL or Partial. Partial clears and rebuild current years Events only
		
	Release			Version			Date			Developer			Comment
	LIVE			1.1				2022-14-01		Ben King			TASK 840 - Improve metadata creation step

*/

SET NOCOUNT ON

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY


	-- Check @BuildType supplied is valid		
	IF ISNULL(@BuildType, '?') NOT IN ('Full', 'Partial')
	RAISERROR ('Error: @BuildType param not in valid values list: "Full", "Partial".', -- Message text.  
				1016, -- Severity.  
				1 -- State.
				);  


	DECLARE @EventStartDate DATETIME2

	DECLARE @MinEventID BIGINT

	IF @BuildType = 'Partial'
		BEGIN 

			IF(MONTH(GETDATE()) IN (1))
			BEGIN
				   SELECT @EventStartDate = DATEADD(yy, DATEDIFF(yy, 0, GETDATE()), -90)
			END
			ELSE IF(MONTH(GETDATE()) IN (2))
			BEGIN
					SELECT @EventStartDate = DATEADD(yy, DATEDIFF(yy, 0, GETDATE()), -60)
			END
			ELSE IF(MONTH(GETDATE()) IN (3))
			BEGIN
					SELECT @EventStartDate = DATEADD(yy, DATEDIFF(yy, 0, GETDATE()), -30)
			END
			ELSE IF(MONTH(GETDATE()) IN (4,5,6,7,8,9,10,11,12))
			BEGIN
					SELECT @EventStartDate = DATEADD(yy, DATEDIFF(yy, 0, GETDATE()), 0)
			END

			--MIN EventID for the Year
			SELECT @MinEventID = 
							(
								SELECT MIN(B.EventID)
								FROM Meta.BusinessEvents B
								INNER JOIN [Event].[Events] E ON B.EventID = E.EventID
								WHERE E.EventDate = @EventStartDate
							)

			DELETE B
			FROM Meta.BusinessEvents B
			WHERE B.EventID >= @MinEventID


			INSERT INTO Meta.BusinessEvents
			(
				 EventID
				,VehicleRoleTypeID
				,PartyID
				,OrganisationName
			)
			SELECT DISTINCT
					M.EventID
				,M.VehicleRoleTypeID
				,M.PartyID
				,M.OrganisationName
			FROM Meta.vwBusinessEvents M
			WHERE EventID >= @MinEventID

		END
	ELSE 
		BEGIN  -- FULL BUILD
			
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

		END 


END TRY
BEGIN CATCH

	SELECT
		 @ErrorNumber = Error_Number()
		,@ErrorSeverity = Error_Severity()
		,@ErrorState = Error_State()
		,@ErrorLocation = Error_Procedure()
		,@ErrorLine = Error_Line()
		,@ErrorMessage = Error_Message()

	EXEC [Sample_Errors].dbo.uspLogDatabaseError
		 @ErrorNumber
		,@ErrorSeverity
		,@ErrorState
		,@ErrorLocation
		,@ErrorLine
		,@ErrorMessage
		
	RAISERROR(@ErrorNumber, @ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorLine)
		
END CATCH
GO
