CREATE PROCEDURE [SelectionOutput].[uspRunOutputEnprecis]

AS
SET NOCOUNT ON


/*
	Purpose:	Collates output data for all Enprecis selections yet to be outputted.  
		
	Version			Date			Developer			Comment
	1.0				14/01/2014		Martin Riverol		Created
	1.1				28/02/2014		Martin Riverol		Pull model description from specific enprecis model name column
														Pull country from CaseDetails, if no data then go to dealer hierarchy
	2.0				20150309		Peter Doyle			Added further JOIN for models that seemed to be missing	

*/

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

	/* CLEARDOWN THE HOLDING TABLE OF THE LAST SELECTIONS OUTPUTTED */
	
	IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'SelectionOutput.Enprecis') AND type in (N'U'))
	
		TRUNCATE TABLE SelectionOutput.Enprecis

	

	/* IDENTIFY WHICH SELECTIONS ARE TO BE OUTPUTTED (I.E. THOSE THAT HAVE YET TO BE STAMPED AS OUTPUTTED) AND PUT THEIR DATA INTO THE HOLDING TABLE */ 
	
	;WITH cteTelephoneNumbers
	AS
		(
			SELECT PTN.PartyID, TN.ContactNumber Tel, MTN.ContactNumber MobTel, WTN.ContactNumber WorkTel
			FROM Meta.PartyBestTelephoneNumbers PTN
			LEFT JOIN ContactMechanism.TelephoneNumbers MTN ON PTN.MobileID = MTN.ContactMechanismID 
			LEFT JOIN ContactMechanism.TelephoneNumbers WTN ON PTN.WorkLandlineID = WTN.ContactMechanismID 
			LEFT JOIN ContactMechanism.TelephoneNumbers TN ON PTN.LandlineID = TN.ContactMechanismID
		)		
	, cteEmailAddresses
	AS 
		(
			SELECT PTN.PartyID, EA.EmailAddress
			FROM Meta.PartyBestemailaddresses PTN
			INNER JOIN ContactMechanism.EmailAddresses EA ON PTN.ContactMechanismID = EA.ContactMechanismID
		)

		INSERT INTO SelectionOutput.Enprecis
					
					(
						ProgrammeRequirementID
						, ProgrammeRequirement
						, QuestionnaireRequirementID
						, QuestionnaireRequirement
						, SelectionRequirementID
						, SelectionRequirement
						, PartyID
						, CaseID
						, Country
						, ManufacturerName
						, VIN
						, ChassisNumber
						, FullModelDesc
						, RegistrationNumber
						, DeliveryDate
						, Salutation
						, Addressee
						, Title
						, FirstName
						, LastName
						, SecondLastName
						, OrganisationName
						, BuildingName
						, SubStreet
						, StreetNumber
						, Street
						, SubLocality
						, Locality
						, Town
						, Region
						, PostCode
						, AddCountry
						, WorkTel
						, Tel
						, MobTel
						, Emailaddress
						, OutputDate
						, SaleType
						, Selection
						, ModelDescription
						, DealerName
						, DealerCode
						, SubNationalRegion
						, DealerPartyID
						, RegistrationDate
						, EventDate
						, OwnershipCycle
						, BuildYear
						, GenderID
					)

						SELECT 
								P.RequirementID AS ProgrammeRequirementID
								, P.Requirement AS ProgrammeRequirement
								, Q.RequirementID AS QuestionnaireRequirementID
								, Q.Requirement AS QuestionnaireRequirement
								, S.RequirementID AS SelectionRequirementID
								, S.Requirement AS SelectionRequirement
								, CD.PartyID
								, SC.CaseID
								, D.Country
								, CASE QR.ManufacturerPartyID
									WHEN 2 THEN 'Jaguar'
									WHEN 3 THEN 'LR'
									ELSE ''	
								END AS ManufacturerName
								, CD.VIN
								, CD.ChassisNumber
								, CD.ModelDerivative AS FullModelDesc
								, CD.RegistrationNumber 
								, NULL AS DeliveryDate
								, Party.udfGetAddressingText (CD.PartyID, Q.RequirementID, CD.CountryID, CD.LanguageID, 1) AS Salutation
								, Party.udfGetAddressingText (CD.PartyID, Q.RequirementID, CD.CountryID, CD.LanguageID, 2) AS Addressee
								, CD.Title 
								, CD.FirstName
								, CD.LastName 
								, CD.SecondLastName
								, CD.OrganisationName
								, PA.BuildingName  
								, PA.SubStreet 
								, PA.StreetNumber
								, PA.Street 
								, PA.SubLocality 
								, PA.Locality 
								, PA.Town 
								, PA.Region 
								, PA.PostCode
								, COALESCE(CD.Country, D.Country) AS Country
								, TN.WorkTel
								, TN.Tel
								, TN.MobTel
								, EA.Emailaddress
								, GETDATE() AS OutputDate
								, CD.SaleType
								, CD.Selection 
								, MD.EnprecisOutputFileModelDescription AS ModelDescription
								, CD.DealerName
								, D.DealerCode  
								, D.SubNationalRegion   
								, CD.DealerPartyID
								, CD.RegistrationDate
								, CD.EventDate
								, OC.OwnershipCycle
								, V.BuildYear
								, CD.GenderID
					FROM Requirement.Requirements P
					INNER JOIN Requirement.RequirementRollups PQ ON P.RequirementID = PQ.RequirementIDPartOf
					INNER JOIN Requirement.Requirements Q ON PQ.RequirementIDMadeUpOf = Q.RequirementID
					INNER JOIN Requirement.QuestionnaireRequirements QR ON Q.RequirementID = QR.RequirementID
					INNER JOIN Requirement.RequirementRollups QS ON Q.RequirementID = QS.RequirementIDPartOf
					INNER JOIN Requirement.Requirements S ON QS.RequirementIDMadeUpOf = S.RequirementID
					INNER JOIN Requirement.RequirementRollups SM ON S.RequirementID = SM.RequirementIDPartOf
					INNER JOIN Requirement.Requirements M ON SM.RequirementIDMadeUpOf = M.RequirementID
					-- Version 2.0 added by P.Doyle 20150309
					INNER JOIN [Requirement].[QuestionnaireModelRequirements] qmr ON SM.RequirementIDMadeUpOf = qmr.RequirementIDMadeUpOf AND qmr.RequirementIDPartOf = q.RequirementID
					INNER JOIN Requirement.SelectionRequirements SR ON S.RequirementID = SR.RequirementID
					INNER JOIN Requirement.SelectionCases SC ON SM.RequirementIDMadeUpOf = SC.RequirementIDMadeUpOf
																	AND SM.RequirementIDPartOf = SC.RequirementIDPartOf
					INNER JOIN Meta.CaseDetails CD ON SC.CaseID = CD.CaseID
					INNER JOIN 
						(
							SELECT DISTINCT 
								OutletPartyID
								, CASE Market
									WHEN 'UK' THEN 'United Kingdom'
									ELSE Market
								END AS Country
								, SubNationalRegion
								, COALESCE(OutletCode_GDD, OutletCode) DealerCode
							FROM dbo.DW_JLRCSPDealers
							WHERE OutletFunctionID = 8
						) D 
					ON CD.DealerPartyID = D.OutletPartyID 
					INNER JOIN Vehicle.Vehicles V ON CD.VehicleID = V.VehicleID
					INNER JOIN Vehicle.Models MD ON V.ModelID = MD.ModelID
					LEFT JOIN Meta.PartyBestPostalAddresses PBPA 
						INNER JOIN ContactMechanism.PostalAddresses PA ON PBPA.ContactMechanismID = PA.ContactMechanismID
					ON CD.PartyID = PBPA.PartyID
					LEFT JOIN Event.CaseRejections CR ON CD.CaseID = CR.CaseID
					LEFT JOIN Event.OwnershipCycle OC ON CD.EventID = OC.EventID
					LEFT JOIN cteTelephoneNumbers TN ON CD.PartyID = TN.PartyID
					LEFT JOIN cteEmailAddresses EA ON CD.PartyID = EA.PartyID
					WHERE P.RequirementTypeID = 1 
					AND P.Requirement LIKE 'Enprecis%2014+'--'Enprecis%' /* ONLT SELECTIONS TIED TO THE ENPRECIS PROGRAMME */
					AND SR.DateOutputAuthorised IS NULL /* ONLY SELECTIONS THAT HAVE YET TO BE OUTPUTTED */
					--AND S.requirement LIKE '%Enprecis%20150330'					
					AND CR.CaseID IS NULL; /* REMOVE ANY REJECTIONS */

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

