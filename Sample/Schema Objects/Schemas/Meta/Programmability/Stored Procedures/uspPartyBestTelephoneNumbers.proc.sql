CREATE PROC Meta.uspPartyBestTelephoneNumbers

AS

/*
	Purpose:	Drops, recreates and reindexes Meta.PartyBestTelephoneNumbers META table which is a denormalised set of data containing the latest non solicitated telephone numbers for a party
		
	Version			Date			Developer			Comment
	1.0				$(ReleaseDate)		Simon Peacock		Created from [Prophet-ODS].dbo.uspIP_Update_META_GENERAL_PartyBestTelecommunicationsNumbers

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
	IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'Meta.PartyBestTelephoneNumbers') AND type in (N'U'))
	BEGIN
		DROP TABLE Meta.PartyBestTelephoneNumbers
	END
	
	CREATE TABLE Meta.PartyBestTelephoneNumbers
	(
		PartyID dbo.PartyID NOT NULL,
		PhoneID dbo.ContactMechanismID NULL,
		LandlineID dbo.ContactMechanismID NULL,
		HomeLandlineID dbo.ContactMechanismID NULL,
		WorkLandlineID dbo.ContactMechanismID NULL,
		MobileID dbo.ContactMechanismID NULL
	)
	
	INSERT INTO Meta.PartyBestTelephoneNumbers
	(
		PartyID,
		PhoneID,
		LandlineID,
		HomeLandlineID,
		WorkLandlineID,
		MobileID
	)
	SELECT DISTINCT
		PartyID,
		PhoneID,
		LandlineID,
		HomeLandlineID,
		WorkLandlineID,
		MobileID
	FROM Meta.vwPartyBestTelephoneNumbers
	
	ALTER TABLE Meta.PartyBestTelephoneNumbers
	ADD CONSTRAINT [PK_META_PartyBestTelephoneNumbers] PRIMARY KEY CLUSTERED ([PartyID])
	WITH  FILLFACTOR = 100  ON [PRIMARY] 

	CREATE UNIQUE INDEX [IX_META_PartyBestTelephoneNumbers_Phone] ON Meta.PartyBestTelephoneNumbers([PhoneID], [PartyID]) ON [PRIMARY]

	CREATE UNIQUE INDEX [IX_META_PartyBestTelephoneNumbers_Landline] ON Meta.PartyBestTelephoneNumbers([LandlineID], [PartyID]) ON [PRIMARY]

	CREATE UNIQUE INDEX [IX_META_PartyBestTelephoneNumbers_HomeLandline] ON Meta.PartyBestTelephoneNumbers([HomeLandlineID], [PartyID]) ON [PRIMARY]

	CREATE UNIQUE INDEX [IX_META_PartyBestTelephoneNumbers_WorkLandline] ON Meta.PartyBestTelephoneNumbers([WorkLandlineID], [PartyID]) ON [PRIMARY]

	CREATE UNIQUE INDEX [IX_META_PartyBestTelephoneNumbers_Mobile] ON Meta.PartyBestTelephoneNumbers([MobileID], [PartyID]) ON [PRIMARY]

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