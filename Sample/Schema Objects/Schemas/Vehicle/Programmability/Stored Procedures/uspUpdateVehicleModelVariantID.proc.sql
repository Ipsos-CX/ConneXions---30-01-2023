CREATE PROCEDURE [Vehicle].[uspUpdateVehicleModelVariantID]
	
	AS
	
	/*
	
		Purpose:	One time update of the JLR reporting model variant. 
					This is derrived using the model code and model year.
					
		
					Version		Date			Developer			Comment
		LIVE		1.0			20/03/2013		Martin Riverol		Created
		LIVE		1.1			21/05/2013		Martin Riverol		Added F-Type variant coding
		LIVE		1.2			19/08/2013		Chris Ross			BUG 9329 - Add in Range Rover Sport model variant
		LIVE		1.3			10/12/2014		Chris Ross			BUG 10745 - Add in new Discovery Sport model variant coding
		LIVE		1.4			21/05/2015		Chris Ross			BUG 11042 - Add in XE model variant coding
		LIVE		1.5			29/10/2015		Chris Ledger		BUG 11842 - Add in new XF & XF Sportbrake model variant coding
		LIVE		1.6			14/03/2016		Eddie Thomas		BUG 12446 - Add in new F-PACE model variant coding
		LIVE		1.7			12/05/2016		Eddie Thomas		[COMMENTED OUT CHANGES AS 12856 and 12765 RELEASED FIRST] BUG 12685 - Add in new XJS model variant coding
		LIVE		1.8			26/07/2016		Ben King			BUG 12856 - Add in Evoque Convertible
		LIVE		1.9			26/07/2016		Chris Ross			BUG 12765 - Add in F-Type (SVR) and Project 7
		LIVE		1.10		04/11/2016		Chris Ledger		BUG 13189 - Add in XFL
		LIVE		1.11		15/03/2017		Chris Ledger		BUG 13177 - Add in Discovery (L462)
		LIVE		1.12		26/04/2017		Chris Ledger		BUG 13877 - Add in Range Rover Velar
		LIVE		1.13		01/06/2017		Chris Ledger		BUG 13970 - Add in F-TYPE Matching String SAJD_[15][A-Z]__[J-Z]%
		LIVE		1.14		24/08/2017		Chris Ledger		BUG 14172 - Add in E-PACE		DEPLOYED LIVE: CL 2017-08-24
		LIVE		1.15		12/01/2018		Eddie Thomas		BUG 14485 - Add in XEL
		LIVE		1.16		13/03/2018		Ben King			BUG 14517 - Add Jaguar I-Pace
		LIVE		1.17		29/06/2018		Chris Ledger		BUG 14668 - Add in Project 8
		LIVE		1.18		02/08/2018		Chris Ledger		BUG 14887 - Add in SV-Coupe
		LIVE		1.19		26/03/2019		Chris Ledger		BUG 15290 - Add in Range Rover Evoque II (L551)
		LIVE		1.20		23/10/2019		Ben King			BUG 15558 - Add 'L2CG%'
		LIVE		1.21		10/02/2020		Eddie Thomas		BUG 16921 - Add in New Defender L663
		LIVE		1.22		14/01/2021		Eddie Thomas		BUG 18004 - Add in F-TYPE (X152 2021-)
		LIVE		1.23		08/04/2021		Chris Ledger		TASK 377 - Tidy up SP and fix Discovery 3 coding
		LIVE		1.24		24/05/2021		Eddie Thomas		BUG 18166/18189  - New Range Rover Variant=> Range Rover (L460 2021-)
		LIVE		1.25		04/08/2021		Eddie Thomas		BUG 18289 - New Range Rover Sport & New Defender
		LIVE		1.26        2021-10-20      Ben King            TASK 665 - 18374 - Changes to China VIN decoding
		LIVE		1.27		06/12/2021		Eddie Thomas		BUG 18406 - UPDATED VIN matching string 85
	*/
	
	/* SET LOCAL CONNECTION SETTINGS */
	
		SET NOCOUNT ON

		DECLARE @ErrorNumber INT
		DECLARE @ErrorSeverity INT
		DECLARE @ErrorState INT
		DECLARE @ErrorLocation NVARCHAR(500)
		DECLARE @ErrorLine INT
		DECLARE @ErrorMessage NVARCHAR(2048)

		BEGIN TRY
		
			/* UPDATE TO KNOWN VARIANTS */
			UPDATE V
				SET ModelVariantID = 
					CASE 
						WHEN V.ModelID = 2 AND V.BuildYear BETWEEN 1999 AND 2008 THEN 4			--'S-TYPE (x200 1999-2008)'
						WHEN V.ModelID = 2 AND V.BuildYear IS NULL THEN 3						--'S-TYPE (Generic)'	
						WHEN V.ModelID = 3 AND V.BuildYear <= 2015 THEN 6						--'XF (x250 2008-)'
						WHEN V.ModelID = 3 AND V.BuildYear >= 2016 THEN 44						--'XF (x250 2016-)'
						WHEN V.ModelID = 3 AND V.BuildYear IS NULL THEN 5						--'XF (Generic)'
						WHEN V.ModelID = 4 AND V.BuildYear BETWEEN 2003 AND 2010 THEN 10		--'XJ (x350 2003-2010)'
						WHEN V.ModelID = 4 AND V.BuildYear > 2010 THEN 11						--'XJ (x351 2010-)'
						WHEN V.ModelID = 4 AND V.BuildYear IS NULL THEN 9						--'XJ (Generic)'	
						WHEN V.ModelID = 5 AND V.BuildYear BETWEEN 1997 AND 2006 THEN 13		--'XK (x100 1997-2006)'
						WHEN V.ModelID = 5 AND V.BuildYear > 2006 THEN 14						--'XK (x150 2006-)'
						WHEN V.ModelID = 5 AND V.BuildYear IS NULL THEN 12						--'XK (Generic)'	
						WHEN V.ModelID = 6 AND V.BuildYear BETWEEN 2001 AND 2009 THEN 16		--'X-TYPE (x400 2001-2009)'
						WHEN V.ModelID = 6 AND V.BuildYear IS NULL THEN 15						--'X-TYPE (Generic)'	
						WHEN V.ModelID = 8 THEN 17												--'Defender'
						WHEN V.ModelID = 9 AND V.BuildYear <= 2004 THEN 18						--'Discovery (<2004)'
						WHEN V.ModelID = 9 AND V.BuildYear IS NULL THEN 19						--'Discovery (Generic)'
						WHEN V.ModelID = 10 AND V.BuildYear BETWEEN 2004 AND 2008 THEN 21		--'Discovery 3 (L319 2004-2009)'
						--WHEN V.ModelID = 10 AND V.BuildYear >= 2009 THEN 22					--'Discovery 4 (L319 2009)'					-- V1.23
						WHEN V.ModelID = 11 AND V.BuildYear BETWEEN 1996 AND 2005 THEN 24		--'Freelander (L314 1996-2006)'
						WHEN V.ModelID = 11 AND V.BuildYear IS NULL THEN 23						--'Freelander (Generic)'	
						WHEN V.ModelID = 12 AND V.BuildYear >= 2006 THEN 26						--'Freelander 2 (L359 2006-)'
						WHEN V.ModelID = 12 AND V.BuildYear IS NULL THEN 25						--'Freelander 2 (Generic)'	
						WHEN V.ModelID = 13 AND V.BuildYear < 2001 THEN 28						--'Range Rover (<2001)'
						WHEN V.ModelID = 13 AND V.BuildYear >= 2001 THEN 30						--'Range Rover (L322 2001-)'
						WHEN V.ModelID = 13 AND V.BuildYear IS NULL THEN 29						--'Range Rover (Generic)'	
						WHEN V.ModelID = 14 AND V.VIN LIKE 'SALZ%' THEN 65						--'Range Rover Evoque II (L551)'
						WHEN V.ModelID = 14 AND V.VIN LIKE '99JZ%' THEN 65						--'Range Rover Evoque II (L551)'
						WHEN V.ModelID = 14 AND V.VIN LIKE 'L2CG%' THEN 65						--'Range Rover Evoque II (L551)'
						WHEN V.ModelID = 14 AND V.VIN LIKE 'L2CJ%' THEN 65						--'Range Rover Evoque II (L551)'			--V1.27
						WHEN V.ModelID = 14 AND V.VIN LIKE 'L2CV%' THEN 32						--'Range Rover Evoque (L538 2011-)' --V1.26
						WHEN V.ModelID = 14 AND V.BuildYear >= 2011 THEN 32						--'Range Rover Evoque (L538 2011-)'
						WHEN V.ModelID = 14 AND V.BuildYear IS NULL THEN 31						--'Range Rover Evoque (Generic)'	
						WHEN V.ModelID = 15 AND V.BuildYear >= 2005 AND V.VIN NOT LIKE 'SALWA%' THEN 34 --'Range Rover Sport (L320 2005-)'   -- V1.2
						WHEN V.ModelID = 15 AND V.BuildYear >= 2014 AND V.VIN LIKE 'SALWA%' THEN 37		--'Range Rover Sport (L494)'		 -- V1.2
						WHEN V.ModelID = 15 AND V.BuildYear IS NULL THEN 33						--'Range Rover Sport (Generic)'	
						WHEN V.ModelID = 16 THEN 22												--'Discovery 4 (L319 2009)'						
						WHEN V.ModelID = 21 AND V.BuildYear < 2016 THEN 7						--'XF Sportbrake'
						WHEN V.ModelID = 21 AND V.BuildYear >= 2016 THEN 45						--'XF Sportbrake (x250 2016-)'
						WHEN V.ModelID = 21 AND V.BuildYear IS NULL THEN 46						--'XF Sportbrake (Generic)'
						WHEN V.ModelID = 22 AND V.VIN LIKE 'SALK%' THEN 68						--'New Range Rover (L460 2021-)'			-- V1.24
						WHEN V.ModelID = 22 THEN 27												--'New Range Rover (L405)'
						WHEN V.ModelID = 23 AND V.VIN LIKE 'SAJ__6[0-7]____[KP]%' AND V.BuildYear >= 2014 THEN 36 --'F-TYPE (x152 2014-)'	-- V1.9
						WHEN V.ModelID = 23 AND V.VIN LIKE 'SAJD_[15][A-Z]__[J-Z]%' THEN 36		--'F-TYPE (x152 2014-)'						-- V1.13
						WHEN V.ModelID = 23 AND V.VIN LIKE 'SAJ__6[89JK]____[KP]%' THEN 50		--'F-TYPE (SVR)'							-- V1.9
						WHEN V.ModelID = 23 AND V.VIN LIKE 'SAJD_[15][A-Z]__[M-Z]%' THEN 67		--'F-TYPE (X152 2021-)'						-- V1.2
						WHEN V.ModelID = 24 AND SUBSTRING(V.VIN, 10, 1) = 'F'  THEN 39			--'Discovery Sport (L550)'
						WHEN V.ModelID = 27 THEN 43												--'XE (X760)'								
						WHEN V.ModelID = 28 AND V.BuildYear >= 2016 THEN 48						--'F-PACE (X761 2016-)'
						WHEN V.ModelID = 28 AND V.BuildYear IS NULL THEN 47						--'F-PACE (Generic)'
						WHEN V.ModelID = 32 THEN 54												--'XFL (x260 2016-)'						-- V1.10
						WHEN V.ModelID = 33 THEN 55												--'Discovery (L462)'						-- V1.11								
						WHEN V.ModelID = 34 THEN 56												--'Range Rover Velar (Generic)'				-- V1.12								
						WHEN V.ModelID = 39 THEN 61												--'E-PACE (Generic)'						-- V1.14
						WHEN V.ModelID = 43 AND V.VIN LIKE 'SALE_[8F]%' THEN 71                 -- 130 Defender (L663)						-- v1.25 
						WHEN V.ModelID = 43 THEN 66												--'Defender (L663)'							-- V1.21																
						WHEN V.ModelID = 44 THEN 70												-- Range Rover Sport (L461)					-- V1.25
						ELSE NULL
					END
			FROM Vehicle.Vehicles V
			WHERE V.ModelVariantID IS NULL
			
			
			/* !!!!! BUGGER, I NEED TO ADD A NEW BIT TO SET DEFAULT MODEL VARIANTS AS WE HAVE LOADS OF MODELS WITH MODEL YEARS 
				THAT DO NOT FIT IN THE RANGE !!!!! */
			
			/* UPDATE ANY OUTSTANDING TO GENERIC VARIANTS */
			
			UPDATE V
				SET ModelVariantID = 
					CASE 
						WHEN V.ModelID = 2 THEN 3			-- S-TYPE (Generic)
						WHEN V.ModelID = 3 THEN 5			-- XF (Generic)
						WHEN V.ModelID = 4 THEN 9			-- XJ (Generic)
						WHEN V.ModelID = 5 THEN 12			-- XK (Generic)
						WHEN V.ModelID = 6	THEN 15			-- X-TYPE (Generic)
						WHEN V.ModelID = 9	THEN 19			-- Discovery (Generic)
						WHEN V.ModelID = 10	THEN 20			-- Discovery 3 (Generic)
						WHEN V.ModelID = 11	THEN 23			-- Freelander (Generic)
						WHEN V.ModelID = 12	THEN 25			-- Freelander 2 (Generic)
						WHEN V.ModelID = 13	THEN 29			-- Range Rover (Generic)
						WHEN V.ModelID = 14	THEN 31			-- Range Rover Evoque (Generic)
						WHEN V.ModelID = 15	THEN 33			-- Range Rover Sport (Generic)
						WHEN V.ModelID = 21 THEN 46			-- XF Sportbrake (Generic)
						WHEN V.ModelID = 23	THEN 35			-- F-TYPE (Generic)
						WHEN V.ModelID = 24 THEN 38			-- Discovery Sport (Generic)
						WHEN V.ModelID = 27 THEN 42			-- XE (Generic)
						WHEN V.ModelID = 28 THEN 47			-- F-PACE (Generic)
					--	[REMOVED CGR 28-07-2016]   WHEN V.ModelID = 29 THEN 49 -- XJS (Generic)
						WHEN V.ModelID = 29 THEN 49			-- Evoque Convertible
						WHEN V.ModelID = 31 THEN 51			-- Project 7 (Generic)	-- V1.9
						WHEN V.ModelID = 40 THEN 62			-- XEL (X760 2018-)		-- V1.15
						WHEN V.ModelID = 37 THEN 59			-- I-PACE (Generic)		-- V1.16
						WHEN V.ModelID = 41 THEN 63			-- Project 8 (Generic)	-- V1.17
						WHEN V.ModelID = 42 THEN 64			-- SV-Coupe (Generic)	-- V1.18
						ELSE NULL
					END
			FROM Vehicle.Vehicles V
			WHERE V.ModelVariantID IS NULL
	
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
				
			IF @@TRANCOUNT > 0
			BEGIN
				ROLLBACK TRAN
			END
				
			RAISERROR(@ErrorNumber, @ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorLine)
				
		END CATCH