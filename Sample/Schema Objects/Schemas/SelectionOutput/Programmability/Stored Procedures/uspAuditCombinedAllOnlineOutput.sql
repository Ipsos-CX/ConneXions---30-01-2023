CREATE PROCEDURE [SelectionOutput].[uspAuditCombinedAllOnlineOutput]
(
	@FileName VARCHAR(255)
)
AS

/*
		Purpose:	Audit the all combined output for online
	
		Version		Date			Developer			Comment
LIVE	1.0			12/01/2021		Eddie Thomas		Created
LIVE	1.1			22/01/2021		Eddie Thomas		Procedure intermittingly fails and seem unable to debug because of sub procedure call.
														Removed sub procedure call and carry out its processing locally.
LIVE	1.2			25/02/2021		Eddie Thomas		Added EventID
LIVE	1.3			24/03/2021		Chris Ledger		Task 299 - Add General Enquiry fields
LIVE	1.4			29/06/2021		Eddie Thomas		Bugtracker 18235 - PHEV Flagging
LIVE	1.5			24/08/2021      Ben King            TASK 567
LIVE	1.6			2021-09-29      Ben King			TASK 600 - 18342 - Legitimate Business Interest (LBI) Consent
LIVE	1.7			2022-06-23      Eddie Thomas		TASK 877 - Land Rover Experience
LIVE	1.8			2022-06-27		Eddie Thomas		TASK 900 - Business & Fleet Vehicle changes
LIVE	1.9			2022-08-26		Chris Ledger		TASK 877 - Add Land Rover Experience to list of EventTypes
LIVE	1.10		2022-09-07		Eddie Thomas		TASK 1017 - Added SubBrand
*/

SET NOCOUNT ON

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

	BEGIN TRAN
	
		DECLARE @Date DATETIME
		SET @Date = GETDATE()
		
		-- CREATE A TEMP TABLE TO HOLD EACH TYPE OF OUTPUT
		CREATE TABLE #OutputtedSelections
		(
			PhysicalRowID INT IDENTITY(1,1) NOT NULL,
			AuditID INT NULL,
			AuditItemID INT NULL,
			CaseID INT NULL,
			PartyID INT NULL,
			CaseOutputTypeID INT NULL
		)

		DECLARE @RowCount INT
		DECLARE @AuditID dbo.AuditID

		INSERT INTO #OutputtedSelections (CaseID, PartyID, CaseOutputTypeID)
		SELECT DISTINCT
			O.[ID] AS CaseID, 
			O.PartyID,
			CASE SUBSTRING(ITYPE, 1,1)			--v1.6
				WHEN 'H' THEN (SELECT CaseOutputTypeID FROM [Event].CaseOutputTypes WHERE CaseOutputType = 'Online')
				WHEN 'T' THEN (SELECT CaseOutputTypeID FROM [Event].CaseOutputTypes WHERE CaseOutputType = 'CATI')
				WHEN 'S' THEN (SELECT CaseOutputTypeID FROM [Event].CaseOutputTypes WHERE CaseOutputType = 'SMS')
				ELSE (SELECT CaseOutputTypeID FROM [Event].CaseOutputTypes WHERE CaseOutputType = 'Postal')
			END AS CaseOutputTypeID
		FROM SelectionOutput.CombinedOnlineOutput O
			INNER JOIN [Event].vwEventTypes ET ON ET.EventTypeID = O.[EventTypeID] 
												AND ET.EventCategory IN ('Sales', 'Service', 'Roadside', 'CRC', 'PreOwned', 'LostLeads', 'Bodyshop', 'CRC General Enquiry', 'Land Rover Experience')	-- V1.3, V1.9
		
		
		-- get the RowCount
		SET @RowCount = (SELECT COUNT(*) FROM #OutputtedSelections)

		IF @RowCount > 0
		BEGIN
		
			--EXEC SelectionOutput.uspAudit @FileName, @RowCount, @Date, @AuditID OUTPUT
			------------------------------------------- V1.1----------------------------------------------------------
			-- CHECK TO SEE IF FILE ALREADY EXISTS
			SELECT @AuditID = ISNULL((	SELECT TOP 1 AuditID 
										FROM [$(AuditDB)].dbo.Files 
										WHERE FileName = @FileName), 0)

			-- EXISTING FILE
			IF @AuditID > 0
			BEGIN
				UPDATE [$(AuditDB)].dbo.Files 
				SET FileRowCount = FileRowCount + @RowCount 
				WHERE AuditID = @AuditID
			END;
	
	
			-- NEW FILE
			IF @AuditID = 0
			BEGIN
	
				-- get an AuditID
				SELECT @AuditID = ISNULL(MAX(AuditID), 0) + 1 
				FROM [$(AuditDB)].dbo.[Audit]
		
				INSERT INTO [$(AuditDB)].dbo.[Audit]
				SELECT @AuditID

				INSERT INTO [$(AuditDB)].dbo.Files
				(
					AuditID,
					FileTypeID,
					[FileName],
					FileRowCount,
					ActionDate
				)
				VALUES
				(
					@AuditID, 
					(	SELECT FileTypeID 
						FROM [$(AuditDB)].dbo.FileTypes 
						WHERE FileType = 'Selection Output'),
					@FileName,
					@RowCount,
					@Date
				)

				INSERT INTO [$(AuditDB)].dbo.OutgoingFiles (AuditID, OutputSuccess)
				VALUES (@AuditID, 1)
	
			END;


			-- Write back the AuditID
			UPDATE #OutputtedSelections
			SET AuditID = @AuditID
			WHERE AuditID IS NULL

			-- Create AuditItems
			DECLARE @max_AuditItemID INT
			SELECT @max_AuditItemID = ISNULL(MAX(AuditItemID), 0) 
			FROM [$(AuditDB)].dbo.AuditItems

			-- Update AuditItemID in table by adding value above to autonumber
			UPDATE #OutputtedSelections
			SET AuditItemID = PhysicalRowID + @max_AuditItemID
			WHERE AuditID = @AuditID

			-- Insert rows from table into AuditItems
			INSERT INTO [$(AuditDB)].dbo.AuditItems (AuditItemID, AuditID)
			SELECT AuditItemID, 
				AuditID
			FROM #OutputtedSelections
			WHERE AuditID = @AuditID

			-- Insert rows from table into FileRows
			INSERT INTO [$(AuditDB)].dbo.FileRows (AuditItemID, PhysicalRow)
			SELECT AuditItemID, 
				PhysicalRowID
			FROM #OutputtedSelections
			WHERE AuditID = @AuditID


			-- Record the output in CaseOutput
			INSERT INTO [Event].CaseOutput (CaseID, AuditID, AuditItemID, CaseOutputTypeID)
			SELECT CaseID, 
				AuditID, 
				AuditItemID, 
				CaseOutputTypeID
			FROM #OutputtedSelections
			------------------------------------------- V1.1----------------------------------------------------------


			INSERT INTO [$(AuditDB)].[Audit].CombinedOnlineOutput
			(
				AuditID,
				AuditItemID,
				SelectionOutputTypeID,
				CaseID,
				SurveyTypeID,
				ModelCode,
				ModelDescription,
				ModelYear,
				ManufacturerID,
				Manufacturer,
				CarRegistration,
				VIN,
				ModelVariantCode,
				ModelVariantDescription,
				PartyID,
				Title,
				Initial,
				LastName,
				FullName,
				DearName,
				CompanyName,
				Address1,
				Address2,
				Address3,
				Address4,
				Address5,
				Address6,
				Address7,
				Address8,
				Country,
				CountryID,
				EmailAddress,
				HomeNumber,
				WorkNumber,
				MobileNumber,
				CustomerUniqueID,
				VersionCode,
				LanguageID,
				GenderID,
				EventTypeID,
				EventDate,
				[Password],
				IType,
				SelectionDate,
				[Week],
				Expired,
				CampaignID,
				Test,
				DealerPartyID,
				ReportingDealerPartyID,
				DealerName,
				DealerCode,
				GlobalDealerCode,
				BusinessRegion,
				OwnershipCycle,
				EmailSignator,
				EmailSignatorTitle,
				EmailContactText,
				EmailCompanyDetails,
				JLRPrivacyPolicy,
				JLRCompanyName,
				UnknownLanguage,
				BilingualFlag,
				BilingualLanguageID,
				DearNameBilingual,
				EmailSignatorTitleBilingual,
				EmailContactTextBilingual,
				EmailCompanyDetailsBilingual,
				JLRPrivacyPolicyBilingual,
				EmployeeCode,
				EmployeeName,
				CRMSalesmanCode,
				CRMSalesmanName,
				RockarDealer,
				SVOTypeID,
				SVODealer,
				VistaContractOrderNumber,
				DealerNumber,
				FOBCode,
				HotTopicCodes,
				ServiceTechnicianID,
				ServiceTechnicianName,
				ServiceAdvisorID,
				ServiceAdvisorName,
				RepairOrderNumber,
				ServiceEventType,
				Approved,
				BreakdownDate,
				BreakdownCountry,
				BreakdownCountryID,
				BreakdownCaseID,
				CarHireStartDate,
				ReasonForHire,
				HireGroupBranch,
				CarHireTicketNumber,
				HireJobNumber,
				RepairingDealer,
				DataSource,
				ReplacementVehicleMake,
				ReplacementVehicleModel,
				CarHireStartTime,
				RepairingDealerCountry,
				RoadsideAssistanceProvider,
				BreakdownAttendingResource,
				CarHireProvider,
				VehicleOriginCountry,
				CRCOwnerCode,
				CRCCode,
				CRCMarketCode,
				SampleYear,
				VehicleMileage,
				VehicleMonthsinService,
				CRCRowID,
				CRCSerialNumber,
				NSCFlag,
				JLREventType,
				DealerType,
				[Queue],
				Dealer10DigitCode,
				EventID,
				EngineType,
				LeadVehSaleType,				-- V1.5
				LeadOrigin,                     -- V1.5
				LegalGrounds,                   -- V1.6
				AnonymityQuestion,              -- V1.6
				LandRoverExperienceID,			-- V1.7
				BusinessFlag,					-- V1.8
				CommonSaleType,					-- V1.8
				SubBrand						-- V1.10	
			)				
			SELECT DISTINCT
				O.AuditID, 
				O.AuditItemID, 
				(SELECT SelectionOutputTypeID FROM [$(AuditDB)].dbo.SelectionOutputTypes WHERE SelectionOutputType = 'All') AS SelectionOutputTypeID,
				S.ID,
				S.SurveyTypeID,
				S.ModelCode,
				S.ModelDescription,
				S.ModelYear,
				S.ManufacturerID,
				S.Manufacturer,
				S.CarRegistration,
				S.VIN,
				S.ModelVariantCode,
				S.ModelVariantDescription,
				S.PartyID,
				S.Title,
				S.Initial,
				S.LastName,
				S.FullName,
				S.DearName,
				S.CompanyName,
				S.Address1,
				S.Address2,
				S.Address3,
				S.Address4,
				S.Address5,
				S.Address6,
				S.Address7,
				S.Address8,
				S.Country,
				S.CountryID,
				S.EmailAddress,
				S.HomeNumber,
				S.WorkNumber,
				S.MobileNumber,
				S.CustomerUniqueID,
				S.VersionCode,
				S.LanguageID,
				S.GenderID,
				S.EventTypeID,
				S.EventDate,
				S.[Password],
				S.IType,
				S.SelectionDate,
				S.[Week],
				S.Expired,
				S.CampaignID,
				S.Test,
				S.DealerPartyID,
				S.ReportingDealerPartyID,
				S.DealerName,
				S.DealerCode,
				S.GlobalDealerCode,
				S.BusinessRegion,
				S.OwnershipCycle,
				S.EmailSignator,
				S.EmailSignatorTitle,
				S.EmailContactText,
				S.EmailCompanyDetails,
				S.JLRPrivacyPolicy,
				S.JLRCompanyName,
				S.UnknownLanguage,
				S.BilingualFlag,
				S.BilingualLanguageID,
				S.DearNameBilingual,
				S.EmailSignatorTitleBilingual,
				S.EmailContactTextBilingual,
				S.EmailCompanyDetailsBilingual,
				S.JLRPrivacyPolicyBilingual,
				S.EmployeeCode,
				S.EmployeeName,
				S.CRMSalesmanCode,
				S.CRMSalesmanName,
				S.RockarDealer,
				S.SVOTypeID,
				S.SVODealer,
				S.VistaContractOrderNumber,
				S.DealerNumber,
				S.FOBCode,
				S.HotTopicCodes,
				S.ServiceTechnicianID,
				S.ServiceTechnicianName,
				S.ServiceAdvisorID,
				S.ServiceAdvisorName,
				S.RepairOrderNumber,
				S.ServiceEventType,
				S.Approved,
				S.BreakdownDate,
				S.BreakdownCountry,
				S.BreakdownCountryID,
				S.BreakdownCaseID,
				S.CarHireStartDate,
				S.ReasonForHire,
				S.HireGroupBranch,
				S.CarHireTicketNumber,
				S.HireJobNumber,
				S.RepairingDealer,
				S.DataSource,
				S.ReplacementVehicleMake,
				S.ReplacementVehicleModel,
				S.CarHireStartTime,
				S.RepairingDealerCountry,
				S.RoadsideAssistanceProvider,
				S.BreakdownAttendingResource,
				S.CarHireProvider,
				S.VehicleOriginCountry,
				S.CRCOwnerCode,
				S.CRCCode,
				S.CRCMarketCode,
				S.SampleYear,
				S.VehicleMileage,
				S.VehicleMonthsinService,
				S.CRCRowID,
				S.CRCSerialNumber,
				S.NSCFlag,
				S.JLREventType,
				S.DealerType,
				S.[Queue],
				S.Dealer10DigitCode,
				S.EventID,
				S.EngineType,
				S.LeadVehSaleType,				-- V1.5
				S.LeadOrigin,                   -- V1.5
				S.LegalGrounds,                 -- V1.6
				S.AnonymityQuestion,			-- V1.6
				S.LandRoverExperienceID,		-- V1.7
				S.BusinessFlag,					-- V1.8
				S.CommonSaleType,				-- V1.8
				S.SubBrand						-- V1.10

			FROM #OutputtedSelections O
				INNER JOIN SelectionOutput.CombinedOnlineOutput S ON O.CaseID = S.ID
																	AND O.PartyID = S.PartyID
				--INNER JOIN [Event].vwEventTypes AS ET ON	ET.EventTypeID = S.EventTypeID AND 
				--											ET.EventCategory IN ('Sales','Service','Roadside','CRC','PreOwned','LostLeads','Bodyshop')

			
		END

		-- DROP THE TEMPORARY TABLE
		DROP TABLE #OutputtedSelections
		
	COMMIT TRAN
		
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
		
	IF @@TRANCOUNT > 0
	BEGIN
		ROLLBACK TRAN
	END
		
	RAISERROR(@ErrorNumber, @ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorLine)
		
END CATCH
