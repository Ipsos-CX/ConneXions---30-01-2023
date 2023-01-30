CREATE VIEW [LostLeads].[vwTransferToVWT_CXP]
AS 

/*
	
	Release		Version		Developer			Date			Comment
	LIVE		1.0		    Ben King    		20/07/2022		TASK 956 - 19540 - Lost Leads CXP Loader
	LIVE		1.1			Chris Ledger		22/08/2022		TASK 956 - undo forcing of suppressions/permissions

*/



	SELECT 
		ID, 
		AuditID, 
		PhysicalRowID, 
		Manufacturer, 
		CountryCode, 
		EventType, 
		DateOfLeadCreation, 
		DateMarkedAsLostLead, 
		DealerCode, 
		CustomerUniqueID, 
		CompanyName, 
		Title, 
		FirstName, 
		SurnameField1, 
		SurnameField2, 
		Salutation, 
		Address1, 
		Address2, 
		Address3, 
		Address4, 
		Address5, 
		Address6, 
		Address7, 
		Address8, 
		HomeTelephoneNumber, 
		BusinessTelephoneNumber, 
		MobileTelephoneNumber, 
		ModelOfInterest, 
		ModelYear, 
		EmailAddress1, 
		EmailAddress2, 
		PreferredLanguage, 
		MarketingPermission, 
		--CompleteSuppression, 
		SuppressionEmail, 
		SuppressionPhone, 
		SuppressionMail, 
		NameOfSalesExecutive, 
		Gender, 
		ConvertedDateMarkedAsLostLead, 
		ManufacturerPartyID, 
		SampleSupplierPartyID, 
		CountryID, 
		EventTypeID, 
		LanguageID, 
		DealerCodeOriginatorPartyID, 
		SetNameCapitalisation, 
		SampleTriggeredSelectionReqID, 
		CustomerIdentifier, 
		CustomerIdentifierUsable,
		CASE CountryCode 
			WHEN 'GB' THEN 
				CASE WHEN ISNUMERIC(Address1) = 1 THEN Address1 ELSE NULL END
			ELSE NULL END AS StreetNumber,
		CASE CountryCode 
			WHEN 'GB' THEN 
				CASE WHEN ISNUMERIC(Address1) = 0 THEN Address1 ELSE NULL END
			ELSE NULL END AS SubStreet,
		CASE CountryCode WHEN 'GB' THEN Address2 ELSE Address1 END AS Street,
		CASE CountryCode WHEN 'GB' THEN Address3 ELSE Address2 END AS Locality,
		Address5 as Town,
		CASE CountryCode WHEN 'GB' THEN Address4 ELSE Address6 END AS Region,
		Address7 AS Postcode,
		Address8 AS Country,
		CompleteSuppressionJLR,				-- V1.1	
		CompleteSuppressionRetailer,		-- V1.1
		PermissionToEmailJLR,				-- V1.1
		PermissionToEmailRetailer,			-- V1.1
		PermissionToPhoneJLR,				-- V1.1
		PermissionToPhoneRetailer,			-- V1.1
		PermissionToPostJLR,				-- V1.1
		PermissionToPostRetailer,			-- V1.1
		PermissionToSMSJLR,					-- V1.1
		PermissionToSMSRetailer,			-- V1.1
		PermissionToSocialMediaJLR,			-- V1.1
		PermissionToSocialMediaRetailer,	-- V1.1
		DateOfLastContact,					
		ConvertedDateOfLastContact,			
		EventType AS JLRSuppliedEventType	
	
	FROM Stage.CXP_LostLeads
