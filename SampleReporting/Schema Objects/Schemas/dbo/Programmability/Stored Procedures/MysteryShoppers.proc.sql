CREATE PROCEDURE [dbo].[MysteryShoppers]
AS
BEGIN
/*
	Purpose:	Build count for file rows loaded for the disposition report
		
	Version			Date			Developer			Comment
	1.0				???????			Poorvi				Created by Poorvi
	1.1				12/12/2013		Chris Ross			Copied in to procedure wrapper+error handling.
														BUG 
	1.2				15/01/2020		Chris Ledger		BUG 15372 - Fix Hard coded references to databases
*/

	--
	-- Declare all the variable
	--
	SET NOCOUNT ON

	DECLARE @ErrorNumber INT
	DECLARE @ErrorSeverity INT
	DECLARE @ErrorState INT
	DECLARE @ErrorLocation NVARCHAR(500)
	DECLARE @ErrorLine INT
	DECLARE @ErrorMessage NVARCHAR(2048)
	

	BEGIN TRY


		DECLARE @startdate datetime2
		DECLARE @@Date_Value_Start VARCHAR(30)
		DECLARE @@Date_Value_End VARCHAR(30)

		SET @startdate = dateadd(mm,-10,getdate())

		SET @@Date_Value_Start = (SELECT CONVERT(VARCHAR(25),DATEADD(dd,-(DAY(@startdate)-1),@startdate),112))
		SET @@Date_Value_End = (SELECT CONVERT(VARCHAR(25),DATEADD(dd,-(DAY(DATEADD(mm,1,@startdate))),DATEADD(mm,1,@startdate)),112))



		CREATE TABLE #Base
			(
					PartyID INT , 
					CaseID INT,
					VIN  NVARCHAR(50),
					EventDate DATETIME2,
					ModelDescription VARCHAR(20),
					RegistrationNumber NVARCHAR(100),
					Title NVARCHAR(200),
					FirstName NVARCHAR(100),
					LastName NVARCHAR(100),
					SecondLastName NVARCHAR(100),
					OrganisationName NVARCHAR(510),
					BuildingName NVARCHAR(400),
					SubStreet NVARCHAR(400),
					StreetNumber NVARCHAR(400),
					Street NVARCHAR(400),
					SubLocality NVARCHAR(400),
					Locality NVARCHAR(400),
					Town NVARCHAR(400),
					Region NVARCHAR(400),
					PostCode NVARCHAR(60),
					CountryID INT,
					DealerName  NVARCHAR(150),
					DealerCode  NVARCHAR(20),
					MobileID  INT,
					WorklandlineID INT,
					LandlineID INT,
					EmailAddress  NVARCHAR(510),
					MobileNumber VARCHAR(200),
					WorkLandlineNumber VARCHAR(200),
					LandlineNumber VARCHAR(200),
					
					
				)

				INSERT INTO #Base (PartyID, CaseID, VIN, EventDate,ModelDescription,RegistrationNumber,Title,FirstName,LastName,SecondLastName,OrganisationName,BuildingName,SubStreet,StreetNumber,Street,SubLocality,Locality,Town,Region,PostCode,CountryID,DealerName,DealerCode,MobileID,WorklandlineID,LandlineID,EmailAddress)
				SELECT cd.PartyID, 
						cd.CaseID,
						cd.VIN,
						cd.EventDate,
						cd.ModelDescription,
						cd.RegistrationNumber,
						cd.Title,
						cd.FirstName,
						cd.LastName,
						cd.SecondLastName,
						cd.OrganisationName,
						pa.BuildingName,
						pa.SubStreet,
						pa.StreetNumber,
						pa.Street,
						pa.SubLocality,
						pa.Locality,
						pa.Town,
						pa.Region,
						pa.PostCode,
						cd.CountryID,
						cd.DealerName,
						cd.DealerCode,
						ptn.MobileID,
						ptn.WorkLandlineID,
						ptn.LandlineID,
						ea.EmailAddress
		FROM [$(SampleDB)].Meta.CaseDetails cd
		LEFT JOIN [$(SampleDB)].ContactMechanism.PostalAddresses pa on cd.PostalAddressContactMechanismID = pa.ContactMechanismID
		LEFT JOIN [$(SampleDB)].ContactMechanism.EmailAddresses ea on cd.EmailAddressContactMechanismID = ea.ContactMechanismID
		LEFT JOIN [$(SampleDB)].Meta.PartyBestTelephoneNumbers ptn on cd.PartyID = ptn.PartyID 
		LEFT JOIN [$(SampleDB)].ContactMechanism.TelephoneNumbers tn on ptn.MobileID = tn.ContactMechanismID and ptn.WorkLandlineID = tn.ContactMechanismID and ptn.LandlineID = tn.ContactMechanismID
		WHERE QuestionnaireRequirementID in (31,234)
		AND EventTypeID = 2
		AND EventDate BETWEEN @@Date_Value_Start AND @@Date_Value_End

			UPDATE #Base
		SET MobileNumber = tn.ContactNumber
		FROM  [$(SampleDB)].ContactMechanism.TelephoneNumbers tn 
		WHERE tn.ContactMechanismID = #Base.MobileID

		UPDATE #Base
		SET WorkLandlineNumber = tn.ContactNumber
		FROM  [$(SampleDB)].ContactMechanism.TelephoneNumbers tn 
		WHERE tn.ContactMechanismID = #Base.WorklandlineID

		UPDATE #Base
		SET LandlineNumber = tn.ContactNumber
		FROM  [$(SampleDB)].ContactMechanism.TelephoneNumbers tn 
		WHERE tn.ContactMechanismID = #Base.LandlineID


		INSERT INTO dbo.AdhocExtractMysteryShopping (PartyID, CaseID,VIN, EventDate,ModelDescription,RegistrationNumber,Title,FirstName,LastName,SecondLastName,OrganisationName,BuildingName,SubStreet,StreetNumber,Street,SubLocality,Town,Region,PostCode,CountryID,DealerName,DealerCode,MobileID,WorklandlineID,LandlineID,EmailAddress )
		SELECT PartyID, 
				max(CaseID) AS CaseID,
				VIN,
				max(EventDate) AS EventDate,
				ModelDescription,
				RegistrationNumber,
				Title,
				FirstName,
				LastName,
				SecondLastName,
				OrganisationName,
				BuildingName,
				SubStreet,
				StreetNumber,
				Street,
				SubLocality,
				Town,
				Region,
				PostCode,
				CountryID,
				DealerName,
				DealerCode,
				MobileID,
				WorklandlineID,
				LandlineID,
				EmailAddress 
		FROM #Base
		WHERE PartyID NOT IN (SELECT PartyID FROM dbo.AdhocExtractMysteryShopping)
		GROUP BY PartyID,VIN,ModelDescription,RegistrationNumber,Title,FirstName,LastName,SecondLastName,OrganisationName,BuildingName,SubStreet,StreetNumber,Street,SubLocality,Town,Region,PostCode,CountryID,DealerName,DealerCode,MobileID,WorklandlineID,LandlineID,EmailAddress 



	END TRY
	--
	-- Write out any error to the sample errors database
	--
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

END

