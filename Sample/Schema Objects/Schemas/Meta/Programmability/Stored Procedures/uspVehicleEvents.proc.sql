CREATE PROCEDURE [Meta].[uspVehicleEvents]
(
	@EventStartDate DATETIME2 = '1 Jan 2008'
)
AS

/*
	Purpose:	Drops, recreates and reindexes Meta.VehicleEvents META table which is a denormalised set of data used to simplify complex views.
		
	Version			Date				Developer			Comment
	1.0				$(ReleaseDate)		Simon Peacock		Created from [Prophet-ODS].dbo.uspIP_Update_GENERAL_VehicleEvents
	2.0				2015-01-26			Peter Doyle			Add index suggested by Optimiser (when running Echo or Sample Reports)	
	2.1				2018-10-29			Chris Ledger		Change EventCategory to Varchar(20)
	2.2				2018-11-29			Chris Ledger		Rename IX_Meta_VehicleEvents_EventID_VehicleID
	2.3				2019-10-29			Chris Ross			BUG 16717 - Temporary Fix - Comment out the index build steps at the end because they are causing the overnight load to fail.
	2.4				2020-04-01			Chris Ledger		Put back in Index Build - TAKEN OUT 14/12/2020 - BK.
	2.5				2022-06-13			Eddie Thomas		TASK 877 - EventCategory field widened to accommodate string 'Land Rover Experience'
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
	IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'Meta.VehicleEvents') AND type in (N'U'))
	BEGIN
		DROP TABLE Meta.VehicleEvents
	END

	CREATE TABLE Meta.VehicleEvents
	(
		EventID dbo.EventID NOT NULL, 
		VehicleID dbo.VehicleID NOT NULL, 
		ModelID dbo.ModelID NULL,
		PartyID dbo.PartyID NOT NULL,
		VehicleRoleTypeID dbo.VehicleRoleTypeID NULL,
		VIN dbo.VIN NULL, 
		RegistrationNumber dbo.RegistrationNumber NULL, 
		RegistrationDate DATETIME2 NULL, 
		EventDate DATETIME2 NULL, 
		EventType NVARCHAR(200) NULL, 
		EventTypeID dbo.EventTypeID NOT NULL,
		EventCategory VARCHAR(50) NULL,			--V2.5
		EventCategoryID dbo.EventCategoryID NULL,
		OwnershipCycle dbo.OwnershipCycle NULL,
		DealerPartyID dbo.PartyID NOT NULL,
		DealerCode dbo.DealerCode NULL, 
		ManufacturerPartyID dbo.PartyID NULL
	)
	
	-- INSERT THE DATA
	INSERT INTO Meta.VehicleEvents
	(
		EventID, 
		VehicleID, 
		ModelID,
		PartyID,
		VehicleRoleTypeID,
		VIN, 
		RegistrationNumber, 
		RegistrationDate, 
		EventDate, 
		EventType, 
		EventTypeID,
		EventCategory,
		EventCategoryID,
		OwnershipCycle,
		DealerPartyID,
		DealerCode, 
		ManufacturerPartyID
	)
	SELECT
		EventID, 
		VehicleID, 
		ModelID,
		PartyID,
		VehicleRoleTypeID,
		VIN, 
		RegistrationNumber, 
		RegistrationDate, 
		EventDate, 
		EventType, 
		EventTypeID,
		EventCategory,
		EventCategoryID,
		OwnershipCycle,
		DealerPartyID,
		DealerCode, 
		ManufacturerPartyID
	FROM Meta.vwVehicleEvents
	WHERE EventDate >= @EventStartDate
	

	-- ADD A PRIMARY KEY
	--ALTER TABLE Meta.VehicleEvents WITH NOCHECK
	--ADD CONSTRAINT PK_META_VehicleEvents PRIMARY KEY  CLUSTERED 
	--(
	--	PartyID,
	--	VehicleID,
	--	DealerPartyID,
	--	EventID,
	--	EventTypeID
	--) ON [PRIMARY]

	-- suggested (by Optimiser) index for Echo & Sample reports added by P.Doyle 26-Jan-2015
	--CREATE NONCLUSTERED INDEX IX_Meta_VehicleEvents_EventID_VehicleID
	--ON [Meta].[VehicleEvents] ([EventID],[VehicleID])


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