CREATE PROCEDURE [China].[uspLoadSalesToVWT]

AS
DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)


SET LANGUAGE ENGLISH
SET DATEFORMAT DMY


BEGIN TRY

	BEGIN TRAN 
		------------------------------------------------------------------------------------------
		-- Copy records (not already transfered) to the VWT 
		------------------------------------------------------------------------------------------
			
		INSERT INTO [dbo].[VWT]
		(
			 AuditID
			,PhysicalFileRow
			,OrganisationName
			,OrganisationNameOrig
			,SaleDateOrig
			,SaleDate
			,RegistrationDateOrig
			,RegistrationDate
			,Title
			,FirstName
			,FirstNameOrig
			,LastName
			,LastNameOrig
			,SecondLastName
			,SecondLastNameOrig
			,Salutation
			,Street
			,Locality
			,Town
			,Region
			,Postcode
			,Country
			,PrivTel
			,BusTel
			,MobileTel
			,ModelDescription
			,BuildYear
			,VehicleIdentificationNumber
			,VehicleIdentificationNumberUsable
			,VehicleRegistrationNumber
			,EmailAddress
			,PrivEmailAddress
			,PartySuppression
			,EmailSuppression
			,PostalSuppression
			,InvoiceNumber
			,InvoiceValue
			,SalesmanCode
			,Salesman
			,OwnershipCycle
			,GenderID
			,PrivateOwner
			,OwningCompany
			,UserChooserDriver
			,EmployerCompany
			,ManufacturerID
			,SampleSupplierPartyID
			,CountryID
			,ODSEventTypeID
			,JLRSuppliedEventType
			,LanguageID
			,SetNameCapitalisation
			,SampleTriggeredSelectionReqID
			,CustomerIdentifier
			,CustomerIdentifierUsable
			,SalesDealerCode
			,SalesDealerCodeOriginatorPartyID
		)
		
		
		SELECT 
				AuditID
				,PhysicalFileRow
				,OrganisationName
				,OrganisationNameOrig
				,SaleDateOrig
				,SaleDate
				,RegistrationDateOrig
				,RegistrationDate
				,Title
				,FirstName
				,FirstNameOrig
				,LastName
				,LastNameOrig
				,SecondLastName
				,SecondLastNameOrig
				,Salutation
				,Street
				,Locality
				,Town
				,Region
				,Postcode
				,Country
				,PrivTel
				,BusTel
				,MobileTel
				,ModelDescription
				,BuildYear
				,VehicleIdentificationNumber
				, CASE  
						WHEN LEN(REPLACE(VehicleIdentificationNumber, ' ', '')) = 17 THEN CAST(1 AS BIT)
						ELSE CAST(0 AS BIT)
				  END AS VehicleIdentificationNumberUsable
				,VehicleRegistrationNumber
				,EmailAddress
				,PrivEmailAddress
				,PartySuppression
				,EmailSuppression
				,PostalSuppression
				,InvoiceNumber
				,InvoiceValue
				,SalesmanCode
				,Salesman
				,OwnershipCycle
				,GenderID
				,PrivateOwner
				,OwningCompany
				,UserChooserDriver
				,EmployerCompany
				,ManufacturerID
				,SampleSupplierPartyID
				,CountryID
				,ODSEventTypeID
				,JLRSuppliedEventType
				,LanguageID
				,SetNameCapitalisation
				,SampleTriggeredSelectionReqID
				,CustomerIdentifier
				,CustomerIdentifierUsable
				,SalesDealerCode
				,SalesDealerCodeOriginatorPartyID
		FROM [CHINA].vwLoadSalesToVWT
		ORDER BY ID
		
		
		------------------------------------------------------------------------------------------
		-- Update the transferred to VWT flag
		------------------------------------------------------------------------------------------
		
		DECLARE @Date DATETIME
		SET @Date = GETDATE()
		
		UPDATE s
		SET s.[DateTransferredToVWT] = @Date
		FROM dbo.VWT v
		INNER JOIN [China].[Sales_WithResponses] s ON s.AuditID = v.AuditID
													AND s.PhysicalRowID = v.PhysicalFileRow 
		
		
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
		
	RAISERROR(@ErrorNumber, @ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorLine)
		
END CATCH

