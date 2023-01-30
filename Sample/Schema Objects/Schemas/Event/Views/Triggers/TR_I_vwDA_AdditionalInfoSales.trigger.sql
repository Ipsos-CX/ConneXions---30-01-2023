CREATE TRIGGER Event.TR_I_vwDA_AdditionalInfoSales ON Event.vwDA_AdditionalInfoSales
INSTEAD OF INSERT

AS

/*
		Purpose:	Loads Additional Sales information we are supplied but that we don't model into a junk table.
					If event already has a row then overwrite it and store write to audit.
	
		Version		Date			Developer			Comment
LIVE	1.0			31/01/2014		Martin Riverol		Created
LIVE	1.1			11/03/2015		Eddie Thomas		Additional fields added. Bug 11105: Netherlands - Service Event Driven Setup
LIVE	1.2			13/03/2015		Chris Ross			BUG 11273 - Add in 2 new fields from VISTA loaders
LIVE	1.3			03/02/2016		Chris Ross			BUG 12268 - Add in Approved column
LIVE	1.4			19/08/2016		Chris Ross			BUG 12858 - Add in Lost Leads column LostLead_DateOfLeadCreation
LIVE	1.5			23/01/2017		Chris Ross			BUG 13646 - Add in ServiceAdvisorID, ServiceAdvisor, TechnicianID and TechnicianName columns
LIVE	1.6			27/01/2017		Chris Ross			BUG 13510 - Add in VehicleSalePrice, SalesAdvisorID and SalesAdvisorName columns
LIVE	1.7			05/05/2017		Chris Ledger		BUG 13897 - Add EventParentAuditItemID & LostLead_DateOfLeadCreation
LIVE	1.8			31/08/2017		Chris Ross			BUG 14122 - Add in PDI_Flag column.  Do roll-up of values so flag is 'N' if more than one value present for an event. 
LIVE	1.9			20/03/2018		Chris Ross			BUG 14413 - Add in ParentAuditItemID to identify which row used for LostLead Event info.
LIVE	1.10		02/08/2018		Eddie Thomas		BUG 14820 - Added new fields introduced to the Lost Leads Global Loader
LIVE	1.11		23/10/2018		Chris Ledger		BUG 15056 - Added IAssistanceHelpdeskAdvisorName and IAssistanceHelpdeskAdvisorID fields
LIVE	1.12		13/01/2020		Eddie Thomas		BUG 16850 - Added RONumber (WIPNumber LL Loader) field
LIVE	1.13		07/06/2022	    Ben King			TASK 879 - Land Rover Experience - SSIS Loader
LIVE	1.14		22/06/2022	    Ben King			TASK 899 - CXP Sales Loader change to use 3 additional fields
*/

SET NOCOUNT ON

DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @ErrorLocation NVARCHAR(500)
DECLARE @ErrorLine INT
DECLARE @ErrorMessage NVARCHAR(2048)

BEGIN TRY

	-- UPDATE EVENTS THAT ALREADY EXIST (ARBITRARILY TAKE THE LAST ROW)

	-- DEDUPE EVENTS
	CREATE TABLE #DistinctEventRow
	(
		EventID		INT,
		AuditItemID INT
	)

	INSERT INTO #DistinctEventRow 
	(
		EventID,
		AudititemID
	)
	SELECT EventID, 
		MAX(AuditItemID) AS AuditItemID
	FROM INSERTED
	GROUP BY EventID;


	-- ROLL-UP PDI_FLAG VALUES TO USE 'N', IN CASE MORE THAN ONE VALUE PRESENT		-- V1.8
	CREATE TABLE #Distinct_PDI_Flag
	(
		EventID		INT,
		PDI_Flag	VARCHAR(1)
	)

	INSERT INTO #Distinct_PDI_Flag
	(
		EventID,
		PDI_Flag
	)
	SELECT EventID, 
		MIN(ISNULL(PDI_Flag, 'N')) AS PDI_Flag
	FROM INSERTED
	GROUP BY EventID;
	

	-- UPDATE PRE-EXISTING EVENTS FIRST 
	UPDATE AI
	SET SalesOrderNumber = I.SalesOrderNumber,
		SalesCustomerType = I.SalesCustomerType,
		SalesPaymentType = I.SalesPaymentType,
		Salesman = I.Salesman,
		ContractRelationship = I.ContractRelationship,
		ContractCustomer = I.ContractCustomer,
		SalesmanCode = I.SalesmanCode,
		InvoiceNumber = I.InvoiceNumber,				-- V1.1
        InvoiceValue = I.InvoiceValue,					-- V1.1
        PrivateOwner = I.PrivateOwner,					-- V1.1
        OwningCompany = I.OwningCompany,				-- V1.1
        UserChooserDriver = I.UserChooserDriver,		-- V1.1
        EmployerCompany	= I.EmployerCompany,			-- V1.1
        AdditionalCountry = I.AdditionalCountry,		-- V1.2
        State = I.State,								-- V1.2
        VehiclePurchaseDate = I.VehiclePurchaseDate,	-- V1.1
		VehicleDeliveryDate = I.VehicleDeliveryDate,	-- V1.1
        TypeOfSaleOrig = I.TypeOfSaleOrig,				-- V1.1
        Approved = I.Approved,							-- V1.3
		LostLead_DateOfLeadCreation = I.LostLead_DateOfLeadCreation,	-- V1.4
		ServiceAdvisorID = I.ServiceAdvisorID,			-- V1.5
		ServiceAdvisorName = I.ServiceAdvisorName,		-- V1.5
		TechnicianID = I.TechnicianID,					-- V1.5
		TechnicianName = I.TechnicianName,				-- V1.5
		VehicleSalePrice = I.VehicleSalePrice,			-- V1.6
		SalesAdvisorID = I.SalesAdvisorID,				-- V1.6
		SalesAdvisorName = I.SalesAdvisorName,			-- V1.6
		PDI_Flag = P.PDI_Flag,							-- V1.8
		ParentAuditItemID = I.ParentAuditItemID,		-- V1.9
		LostLead_MarketingPermission = I.LostLead_MarketingPermission,							-- V1.10
		LostLead_CompleteSuppressionJLR	= I.LostLead_CompleteSuppressionJLR,					-- V1.10
		LostLead_CompleteSuppressionRetailer = I.LostLead_CompleteSuppressionRetailer,			-- V1.10
		LostLead_PermissionToEmailJLR = I.LostLead_PermissionToEmailJLR,						-- V1.10	
		LostLead_PermissionToEmailRetailer = I.LostLead_PermissionToEmailRetailer,				-- V1.10
		LostLead_PermissionToPhoneJLR = I.LostLead_PermissionToPhoneJLR,						-- V1.10
		LostLead_PermissionToPhoneRetailer = I.LostLead_PermissionToPhoneRetailer,				-- V1.10
		LostLead_PermissionToPostJLR = I.LostLead_PermissionToPostJLR,							-- V1.10
		LostLead_PermissionToPostRetailer = I.LostLead_PermissionToPostRetailer,				-- V1.10
		LostLead_PermissionToSMSJLR	= I.LostLead_PermissionToSMSJLR,							-- V1.10
		LostLead_PermissionToSMSRetailer = I.LostLead_PermissionToSMSRetailer,					-- V1.10
		LostLead_PermissionToSocialMediaJLR	= I.LostLead_PermissionToSocialMediaJLR,			-- V1.10
		LostLead_PermissionToSocialMediaRetailer = I.LostLead_PermissionToSocialMediaRetailer,	-- V1.10
		LostLead_DateOfLastContact = I.LostLead_DateOfLastContact,								-- V1.10
		LostLead_ConvertedDateOfLastContact = I.LostLead_ConvertedDateOfLastContact,			-- V1.10
		JLRSuppliedEventType = I.JLRSuppliedEventType,											-- V1.10
		IAssistanceHelpdeskAdvisorName = I.IAssistanceHelpdeskAdvisorName,		-- V1.11
		IAssistanceHelpdeskAdvisorID = I.IAssistanceHelpdeskAdvisorID,			-- V1.11
		RONumber = I.RONumber,													-- V1.12
		LandRoverExperienceID = I.LandRoverExperienceID,						-- V1.13
		CommonSaleType = I.CommonSaleType,										-- V1.14
		TypeOfSaleID = I.TypeOfSaleID											-- V1.14
	FROM INSERTED I
		INNER JOIN #DistinctEventRow E ON I.AuditItemID = E.AuditItemID
		LEFT JOIN #Distinct_PDI_Flag P ON P.EventID = I.EventID					-- V1.8
		INNER JOIN Event.AdditionalInfoSales AI ON E.EventID = AI.EventID;


	-- WRITE NEW EVENT ROWS
	INSERT INTO Event.AdditionalInfoSales 
	(
		EventID,
		SalesOrderNumber,
		SalesCustomerType,
		SalesPaymentType,
		Salesman,
		ContractRelationship,
		ContractCustomer,
		SalesmanCode,
		InvoiceNumber,
		InvoiceValue,
		PrivateOwner,
		OwningCompany,
		UserChooserDriver,
		EmployerCompany,
		AdditionalCountry,				-- V1.2
		State,							-- V1.2
		VehiclePurchaseDate,			-- V1.1
		VehicleDeliveryDate,			-- V1.1
		TypeOfSaleOrig,
		Approved,						-- V1.3
		LostLead_DateOfLeadCreation,	-- V1.4
		ServiceAdvisorID,				-- V1.5
		ServiceAdvisorName,				-- V1.5
		TechnicianID,					-- V1.5
		TechnicianName,					-- V1.5
		VehicleSalePrice,				-- V1.6
		SalesAdvisorID,					-- V1.6
		SalesAdvisorName,				-- V1.6
		PDI_Flag,						-- V1.8
		ParentAuditItemID,				-- V1.9
		LostLead_MarketingPermission,				-- V1.10
		LostLead_CompleteSuppressionJLR,			-- V1.10
		LostLead_CompleteSuppressionRetailer,		-- V1.10
		LostLead_PermissionToEmailJLR,				-- V1.10
		LostLead_PermissionToEmailRetailer,			-- V1.10
		LostLead_PermissionToPhoneJLR,				-- V1.10
		LostLead_PermissionToPhoneRetailer,			-- V1.10
		LostLead_PermissionToPostJLR,				-- V1.10
		LostLead_PermissionToPostRetailer,			-- V1.10
		LostLead_PermissionToSMSJLR,				-- V1.10
		LostLead_PermissionToSMSRetailer,			-- V1.10
		LostLead_PermissionToSocialMediaJLR,		-- V1.10
		LostLead_PermissionToSocialMediaRetailer,	-- V1.10
		LostLead_DateOfLastContact,					-- V1.10
		LostLead_ConvertedDateOfLastContact,		-- V1.10
		JLRSuppliedEventType,						-- V1.10
		IAssistanceHelpdeskAdvisorName,			-- V1.11
		IAssistanceHelpdeskAdvisorID,			-- V1.11
		RONumber,								-- V1.12
		LandRoverExperienceID,					-- V1.13
		CommonSaleType,						    -- V1.14
		TypeOfSaleID							-- V1.14
	)
	SELECT DISTINCT
		I.EventID,
		I.SalesOrderNumber,
		I.SalesCustomerType,
		I.SalesPaymentType,
		I.Salesman,
		I.ContractRelationship,
		I.ContractCustomer,
		I.SalesmanCode,
		I.InvoiceNumber,
		I.InvoiceValue,
		I.PrivateOwner,
		I.OwningCompany,
		I.UserChooserDriver,
		I.EmployerCompany,
		I.AdditionalCountry,			-- V1.2
		I.State,						-- V1.2
		I.VehiclePurchaseDate,			-- V1.1
		I.VehicleDeliveryDate,			-- V1.1
		I.TypeOfSaleOrig,	
		I.Approved,						-- V1.3
		I.LostLead_DateOfLeadCreation,  -- V1.4
		I.ServiceAdvisorID,				-- V1.5
		I.ServiceAdvisorName,			-- V1.5
		I.TechnicianID,					-- V1.5
		I.TechnicianName,				-- V1.5
		I.VehicleSalePrice,				-- V1.6
		I.SalesAdvisorID,				-- V1.6
		I.SalesAdvisorName,				-- V1.6
		P.PDI_Flag,						-- V1.8
		I.ParentAuditItemID,			-- V1.9
		I.LostLead_MarketingPermission,				-- V1.10
		I.LostLead_CompleteSuppressionJLR,			-- V1.10
		I.LostLead_CompleteSuppressionRetailer,		-- V1.10
		I.LostLead_PermissionToEmailJLR,			-- V1.10
		I.LostLead_PermissionToEmailRetailer,		-- V1.10
		I.LostLead_PermissionToPhoneJLR,			-- V1.10
		I.LostLead_PermissionToPhoneRetailer,		-- V1.10
		I.LostLead_PermissionToPostJLR,				-- V1.10
		I.LostLead_PermissionToPostRetailer,		-- V1.10
		I.LostLead_PermissionToSMSJLR,				-- V1.10
		I.LostLead_PermissionToSMSRetailer,			-- V1.10
		I.LostLead_PermissionToSocialMediaJLR,		-- V1.10
		I.LostLead_PermissionToSocialMediaRetailer,	-- V1.10
		I.LostLead_DateOfLastContact,				-- V1.10
		I.LostLead_ConvertedDateOfLastContact,		-- V1.10
		I.JLRSuppliedEventType,						-- V1.10
		I.IAssistanceHelpdeskAdvisorName,			-- V1.11
		I.IAssistanceHelpdeskAdvisorID,				-- V1.11
		I.RONumber,									-- V1.12	
		I.LandRoverExperienceID,					-- V1.13
		I.CommonSaleType,							-- V1.14
		I.TypeOfSaleID								-- V1.14
	FROM INSERTED I
		INNER JOIN #DistinctEventRow E ON I.AuditItemID = E.AuditItemID
		LEFT JOIN #Distinct_PDI_Flag P ON P.EventID = I.EventID					-- V1.8
		LEFT JOIN Event.AdditionalInfoSales AI ON I.EventID = AI.EventID
	WHERE AI.EventID IS NULL


	-- WRITE ALL ROWS RECEIVED TO AUDIT
	INSERT INTO [$(AuditDB)].Audit.AdditionalInfoSales 
	(
		AuditItemID,
		EventID,
		SalesOrderNumber,
		SalesCustomerType,
		SalesPaymentType,
		Salesman,
		ContractRelationship,
		ContractCustomer,
		SalesmanCode,
		InvoiceNumber,
		InvoiceValue,
		PrivateOwner,
		OwningCompany,
		UserChooserDriver,
		EmployerCompany,
		AdditionalCountry,				-- V1.2
		State,							-- V1.2
		VehiclePurchaseDate,			-- V1.1
		VehicleDeliveryDate,			-- V1.1
		TypeOfSaleOrig,
		Approved,						-- V1.3
		LostLead_DateOfLeadCreation,	-- V1.4
		ServiceAdvisorID,				-- V1.5
		ServiceAdvisorName,				-- V1.5
		TechnicianID,					-- V1.5
		TechnicianName,					-- V1.5
		VehicleSalePrice,				-- V1.6
		SalesAdvisorID,					-- V1.6
		SalesAdvisorName,				-- V1.6
		PDI_FLag,						-- V1.8
		ParentAuditItemID,				-- V1.9
		LostLead_MarketingPermission,				-- V1.10
		LostLead_CompleteSuppressionJLR,			-- V1.10
		LostLead_CompleteSuppressionRetailer,		-- V1.10
		LostLead_PermissionToEmailJLR,				-- V1.10
		LostLead_PermissionToEmailRetailer,			-- V1.10
		LostLead_PermissionToPhoneJLR,				-- V1.10
		LostLead_PermissionToPhoneRetailer,			-- V1.10
		LostLead_PermissionToPostJLR,				-- V1.10
		LostLead_PermissionToPostRetailer,			-- V1.10
		LostLead_PermissionToSMSJLR,				-- V1.10
		LostLead_PermissionToSMSRetailer,			-- V1.10
		LostLead_PermissionToSocialMediaJLR,		-- V1.10
		LostLead_PermissionToSocialMediaRetailer,	-- V1.10
		LostLead_DateOfLastContact,					-- V1.10
		LostLead_ConvertedDateOfLastContact,		-- V1.10
		JLRSuppliedEventType,						-- V1.10
		IAssistanceHelpdeskAdvisorName,				-- V1.11
		IAssistanceHelpdeskAdvisorID,				-- V1.11
		RONumber,									-- V1.12
		LandRoverExperienceID,                      -- V1.13
		CommonSaleType,							    -- V1.14
		TypeOfSaleID                                -- V1.14
	)
	SELECT
		I.AuditItemID,
		I.EventID,
		I.SalesOrderNumber,
		I.SalesCustomerType,
		I.SalesPaymentType,
		I.Salesman,
		I.ContractRelationship,
		I.ContractCustomer,
		I.SalesmanCode,
		I.InvoiceNumber,
		I.InvoiceValue,
		I.PrivateOwner,
		I.OwningCompany,
		I.UserChooserDriver,
		I.EmployerCompany,
		I.AdditionalCountry,				-- V1.2
		I.State,							-- V1.2
		I.VehiclePurchaseDate,				-- V1.1
		I.VehicleDeliveryDate,				-- V1.1
		I.TypeOfSaleOrig,
		I.Approved,							-- V1.3
		I.LostLead_DateOfLeadCreationOrig,	--V1.7
		I.ServiceAdvisorID,					-- V1.5
		I.ServiceAdvisorName,				-- V1.5
		I.TechnicianID,						-- V1.5
		I.TechnicianName,					-- V1.5
		I.VehicleSalePrice,					-- V1.6
		I.SalesAdvisorID,					-- V1.6
		I.SalesAdvisorName,					-- V1.6
		I.PDI_Flag,							-- V1.8
		I.ParentAuditItemID,				-- V1.9
		I.LostLead_MarketingPermission,					-- V1.10
		I.LostLead_CompleteSuppressionJLR,				-- V1.10
		I.LostLead_CompleteSuppressionRetailer,			-- V1.10
		I.LostLead_PermissionToEmailJLR,				-- V1.10
		I.LostLead_PermissionToEmailRetailer,			-- V1.10
		I.LostLead_PermissionToPhoneJLR,				-- V1.10
		I.LostLead_PermissionToPhoneRetailer,			-- V1.10
		I.LostLead_PermissionToPostJLR,					-- V1.10
		I.LostLead_PermissionToPostRetailer,			-- V1.10
		I.LostLead_PermissionToSMSJLR,					-- V1.10
		I.LostLead_PermissionToSMSRetailer,				-- V1.10
		I.LostLead_PermissionToSocialMediaJLR,			-- V1.10
		I.LostLead_PermissionToSocialMediaRetailer,		-- V1.10
		I.LostLead_DateOfLastContact,					-- V1.10
		I.LostLead_ConvertedDateOfLastContact,			-- V1.10
		I.JLRSuppliedEventType,							-- V1.10
		I.IAssistanceHelpdeskAdvisorName,				-- V1.11
		I.IAssistanceHelpdeskAdvisorID,					-- V1.11		
		I.RONumber,										-- V1.12
		I.LandRoverExperienceID,						-- V1.13
		I.CommonSaleType,                   			-- V1.14
		I.TypeOfSaleID								    -- V1.14

	FROM INSERTED I
		LEFT JOIN [$(AuditDB)].Audit.AdditionalInfoSales AI ON I.AuditItemID = AI.AuditItemID
	WHERE AI.AuditItemID IS NULL;
			
			
END TRY
BEGIN CATCH

	IF @@TRANCOUNT > 0
	BEGIN
		ROLLBACK TRAN
	END

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


