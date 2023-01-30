CREATE PROC Meta.uspVehiclePartyRoleEvents

AS

/*
	Purpose:	Drops, recreates and reindexes Meta.VehiclePartyRoleEvents META table which is a denormalised set of data used to simplify complex views.
		
	Version			Date			Developer			Comment
	1.0				$(ReleaseDate)		Simon Peacock		Created from [Prophet-ODS].dbo.uspIP_Update_GENERAL_VehiclePartyRoleEvents
	2.0				20-Jan-2015			Peter Doyle			Add Clustered Primmary Key
	2.1				07-09-2015			Chris Ross			BUG 11796 - Add Fleet Manager role type
	2.2				30-05-2018			Chris Ross			BUG 14399 - Filter out GDPR dummy vehicles as they are not needed and can cause dupe EventID entries.
	
*/

SET NOCOUNT ON

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

	----------------------------------------------------
	-- Get the GDPR Dummy Vehicle IDs			--	v2.2
	----------------------------------------------------
	DECLARE @DummyJagVehicleID BIGINT,
			@DummyLRVehicleID BIGINT

	SELECT	@DummyJagVehicleID = sv.DummyJagVehicleID,
			@DummyLRVehicleID = sv.DummyLRVehicleID
	FROM GDPR.SystemValues sv
	
	
	-- Check vehicle IDs present 
	IF  @DummyJagVehicleID Is NULL OR
		@DummyLRVehicleID  Is NULL 
	BEGIN
			RAISERROR ('ERROR (Meta.uspVehiclePartyRoleEvents) : System variables not configuring correctly.  Please contact the Connexions team.',
					16, -- Severity
					1  -- State 
				) 
		RETURN 0
	END 		



	----------------------------------------------------
	-- DROP AND RECREATE THE TABLE
	----------------------------------------------------
	
	IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'Meta.VehiclePartyRoleEvents') AND type in (N'U'))
	BEGIN
		DROP TABLE Meta.VehiclePartyRoleEvents
	END

	CREATE TABLE Meta.VehiclePartyRoleEvents
	(
		EventID dbo.EventID NOT NULL, 
		VehicleID dbo.VehicleID NOT NULL, 
		Purchaser dbo.PartyID NULL, 
		RegisteredOwner dbo.PartyID NULL, 
		PrincipleDriver dbo.PartyID NULL, 
		OtherDriver dbo.PartyID NULL,
		FleetManager dbo.PartyID NULL
	)

	-- POPULATE THE DATA
	INSERT INTO Meta.VehiclePartyRoleEvents
	(
		EventID,
		VehicleID,
		Purchaser,
		RegisteredOwner,
		PrincipleDriver,
		OtherDriver,
		FleetManager
	)
	SELECT 
		EventID,
		VehicleID,
		Purchaser,
		RegisteredOwner,
		PrincipleDriver,
		OtherDriver,
		FleetManager
	FROM Meta.vwVehiclePartyRoleEvents
	WHERE VehicleID NOT IN (@DummyJagVehicleID, @DummyLRVehicleID)			-- v2.2
	
	
ALTER TABLE  Meta.VehiclePartyRoleEvents
	ADD CONSTRAINT pk_Meta_VehiclePartyRoleEvents PRIMARY KEY CLUSTERED (EventId)
	
	-- RECREATE INDEXES
/* TODO - work out what indexes we need and add primary key
CREATE INDEX [IX_GENERAL_VehiclePartyRoleEvents_EventID] 
	ON [dbo].[GENERAL_VehiclePartyRoleEvents]([EventID]) ON [PRIMARY]
	

CREATE INDEX [IX_GENERAL_VehiclePartyRoleEvents_VehicleID] 
	ON [dbo].[GENERAL_VehiclePartyRoleEvents]([VehicleID]) ON [PRIMARY]


CREATE INDEX [IX_GENERAL_VehiclePartyRoleEvents_Purchaser] 
	ON [dbo].[GENERAL_VehiclePartyRoleEvents]([Purchaser]) ON [PRIMARY]


CREATE INDEX [IX_GENERAL_VehiclePartyRoleEvents_RegisteredOwner] 
	ON [dbo].[GENERAL_VehiclePartyRoleEvents]([RegisteredOwner]) ON [PRIMARY]


CREATE INDEX [IX_GENERAL_VehiclePartyRoleEvents_PrincipleDriver] 
	ON [dbo].[GENERAL_VehiclePartyRoleEvents]([PrincipleDriver]) ON [PRIMARY]


CREATE INDEX [IX_GENERAL_VehiclePartyRoleEvents_OtherDriver] 
	ON [dbo].[GENERAL_VehiclePartyRoleEvents]([OtherDriver]) ON [PRIMARY]

*/


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
