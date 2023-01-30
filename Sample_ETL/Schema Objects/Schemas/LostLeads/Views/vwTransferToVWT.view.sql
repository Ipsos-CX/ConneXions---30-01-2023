CREATE VIEW [LostLeads].[vwTransferToVWT]
AS 

/*
	Purpose:	Identify which CRM sourced VISTA Sales events have yet to be transferred to VWT
	
	Version		Developer			Date			Comment
	1.0			Chris Ledger		2017-04-20		Created
	1.1			Eddie Thomas		2018-07-31		BUG 14820 - Lost Leads -  Global loader change

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
		CompleteSuppressionJLR,				--V1.1	
		CompleteSuppressionRetailer,		--V1.1
		PermissionToEmailJLR,				--V1.1
		PermissionToEmailRetailer,			--V1.1
		PermissionToPhoneJLR,				--V1.1
		PermissionToPhoneRetailer,			--V1.1
		PermissionToPostJLR,				--V1.1
		PermissionToPostRetailer,			--V1.1
		PermissionToSMSJLR,					--V1.1
		PermissionToSMSRetailer,			--V1.1
		PermissionToSocialMediaJLR,			--V1.1
		PermissionToSocialMediaRetailer,	--V1.1
		DateOfLastContact,					--V1.1
		ConvertedDateOfLastContact,			--V1.1
		EventType AS JLRSuppliedEventType	--V1.1
	
	FROM Stage.Global_LostLeads