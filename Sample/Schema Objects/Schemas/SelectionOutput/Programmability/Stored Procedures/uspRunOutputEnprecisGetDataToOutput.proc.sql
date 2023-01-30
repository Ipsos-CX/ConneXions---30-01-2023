CREATE PROCEDURE [SelectionOutput].[uspRunOutputEnprecisGetDataToOutput]
	@ProgrammeRequirement VARCHAR(255)
AS
SET NOCOUNT ON


/*
	Purpose:	Get all output data for specifc Enprecis programme (i.e. MIS).
		
	Version			Date			Developer			Comment
	1.0				16/01/2014		Martin Riverol		Created
	1.1				28/02/2014		Martin Riverol		Amended output format of date fields
	1.2				26/03/2014		Martin Riverol		Get Country from address if there is one else use the dealers market
*/

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

	/* GET DATA */ 
	SELECT 
		'RETAILSALETYPE' AS SalesRecordType
		, COALESCE(NULLIF(AddCountry, N''), Country) AS Country
		, VIN
		, ISNULL(FirstName, '') AS CustomerFirstName
		, ISNULL(LastName, '') AS CustomerLastName
		, ISNULL(StreetNumber, '') + ' ' + ISNULL(Street, '') AS CustomerAddressOne
		, ISNULL(SubLocality, '') AS CustomerAddressTwo
		, ISNULL(Town, '') AS CustomerCity
		, ISNULL(Region, '') AS CustomerState
		, ISNULL(PostCode, '') AS CustomerZip
		, ISNULL(emailaddress, '') AS CustomersEmailAddress
		, ISNULL(COALESCE(WorkTel, Tel), '') AS CustomerPhoneOne
		, ISNULL(MobTel, '') AS CustomerPhoneTwo
		, ModelDescription AS ModelType
		, ISNULL(BuildYear, '') AS ModelYear
		, DealerName
		, DealerCode
		, SubNationalRegion AS SalesRegion
		, ' ' AS SalesDistrict
		, CONVERT(VARCHAR(10), EventDate, 101) AS SalesDate
		, CONVERT(VARCHAR(10), RegistrationDate, 101) AS RDRDate
		, ' ' AS ManufacturingDate
		, ' ' AS TrimLevel
		, ' ' AS ExteriorColor
		, ' ' AS InteriorColor
		, ' ' AS Transmission
		, ' ' AS EngineType
		, CaseID
		, ISNULL(Title, '') AS CustomerTitle
		, ISNULL(RegistrationNumber, '') AS RegistrationPlate
		, ISNULL(Salutation, '') AS Salutation
		, ISNULL(SecondLastName, '') AS SecondSurname
		, ISNULL(OwnershipCycle, '') AS OwnershipCycle
	FROM SelectionOutput.Enprecis EO
	WHERE EO.ProgrammeRequirement = @ProgrammeRequirement
	ORDER BY Country, CaseID	


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

