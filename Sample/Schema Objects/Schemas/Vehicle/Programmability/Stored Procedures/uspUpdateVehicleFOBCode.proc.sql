CREATE PROCEDURE [Vehicle].[uspUpdateVehicleFOBCode]

/*
	Purpose:	Update Sample database Vehicle table with vehicle modelyear
	
	Version			Date			Developer			Comment
	1.0				30/03/2017		Ben King 			Update Vehicle table with FOBCode BUG 13645
	1.1				10/07/2017		Ben King			BUG 14007 Code FoB Code 6 - Changshu (China)
	1.2				31/10/2017		Ben King			BUG 14327 New bespoke fob codes
	1.3				31/01/2018		Ben King			BUG 14517
	1.4				07/02/2020		Eddie Thomas		BUG 16933 : Set up factory Nitra (Slovakia)
	

*/

AS
SET NOCOUNT ON

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

		--BUG 14007 CHANGE
		UPDATE V
		SET V.FOBCode = 6
		FROM [Vehicle].Vehicles V
		WHERE SUBSTRING(V.VIN, 1, 3) = 'L2C'
		AND V.FOBCode IS NULL
		
		--BUG 14327 CHANGE
		UPDATE V
		SET V.FOBCode = 5
		FROM [Vehicle].Vehicles V
		WHERE SUBSTRING(V.VIN, 11, 1) = 'T'
		AND SUBSTRING(V.VIN, 1, 1) = '9'
		AND V.FOBCode IS NULL

		--BUG 14327 CHANGE
		UPDATE V  
		SET    V.FOBCode =  CASE   
                        WHEN (SUBSTRING(V.VIN, 1, 4) = 'SADF' AND SUBSTRING(V.VIN, 11, 1) = '1') THEN 8
						WHEN (SUBSTRING(V.VIN, 1, 4) = 'SADF' AND SUBSTRING(V.VIN, 11, 1) = 'L') THEN 7	
						WHEN (SUBSTRING(V.VIN, 1, 4) = 'SADH' AND SUBSTRING(V.VIN, 11, 1) = '1') THEN 8 --V1.3  
                    END
        FROM [Vehicle].Vehicles V             
		WHERE   SUBSTRING(V.VIN, 1, 4) IN ('SADF','SADH')
		AND V.FOBCode IS NULL

		--V1.4	Coincide with the release of New Defender L663 
		UPDATE	V  
		SET		V.FOBCode =  CASE   
								WHEN (SUBSTRING(V.VIN, 1, 4) = 'SALE' AND SUBSTRING(V.VIN, 11, 1) = '2') THEN 9
							END
        FROM	[Vehicle].Vehicles V             
		WHERE   SUBSTRING(V.VIN, 1, 4) = 'SALE'
				AND V.FOBCode IS NULL

		
		
		UPDATE V
		SET V.FOBCode = MF.FOBCode
		FROM [Vehicle].Vehicles V
		INNER JOIN [Vehicle].Models M ON V.ModelID = V.ModelID
		INNER JOIN [Vehicle].ModelFOB MF ON MF.VINCharacter = SUBSTRING(V.VIN, 11, 1) AND M.ManufacturerPartyID = MF.ManufacturerPartyID
		WHERE V.FOBCode IS NULL
		
		
		--ASSIGN CODE 99 TO UNMATCHED 'OTHERS' VINS
		UPDATE [Vehicle].Vehicles
		SET FOBCode = '99'
		WHERE FOBCode is NULL

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