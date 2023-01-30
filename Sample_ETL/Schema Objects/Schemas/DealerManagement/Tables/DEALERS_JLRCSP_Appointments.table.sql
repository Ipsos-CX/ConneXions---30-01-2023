﻿CREATE TABLE [DealerManagement].[DEALERS_JLRCSP_Appointments]
	(
		IP_DealerAppointmentID INT IDENTITY(1,1) NOT NULL,
		Functions NVARCHAR(25) NOT NULL,
		ManufacturerPartyID INT NOT NULL,
		Manufacturer dbo.OrganisationName NULL,	
		SuperNationalRegion dbo.SuperNationalRegion NULL,
		BusinessRegion		dbo.BusinessRegion NULL,
		Market dbo.Market NOT NULL,
		SubNationalTerritory dbo.SubNationalRegion NULL,
		SubNationalRegion dbo.SubNationalRegion NULL,
		CombinedDealer dbo.SubNationalRegion NULL,
		IP_OutletPartyID dbo.PartyID NULL,
		OutletName dbo.OrganisationName NOT NULL,
		OutletName_Short dbo.OrganisationName NOT NULL,
		OutletName_NativeLanguage dbo.OrganisationName NULL,
		OutletCode dbo.DealerCode NOT NULL,
		ImporterPartyID dbo.PartyID NULL,
		OutletCode_Importer dbo.DealerCode NULL,
		OutletCode_Manufacturer dbo.DealerCode NULL,
		OutletCode_Warranty dbo.DealerCode NULL,
		LanguageID dbo.LanguageID NULL,
		FromDate SMALLDATETIME NOT NULL,
		ContactMechanismID dbo.ContactMechanismID NULL,
		AddressPrefix dbo.AddressText NULL,
		BuildingName dbo.AddressText NULL,
		SubStreetNumber dbo.AddressText NULL,
		SubStreet dbo.AddressText NULL,
		StreetNumber dbo.AddressText NULL,
		Street dbo.AddressText NULL,
		SubLocality dbo.AddressText NULL,
		Locality dbo.AddressText NULL,
		Town dbo.AddressText NULL,
		Region dbo.AddressText NULL,
		PostCode dbo.Postcode NULL,
		CountryID dbo.CountryID NULL,
		IP_AuditItemID dbo.AuditItemID NULL,
		IP_OrganisationParentAuditItemID dbo.AuditItemID NULL,
		IP_AddressParentAuditItemID dbo.AuditItemID NULL,
		IP_SystemUser VARCHAR(50) NOT NULL,
		IP_ProcessedDate DATETIME NULL,
		IP_DataValidated BIT NOT NULL,
		IP_ValidationFailureReasons VARCHAR(1000) NULL,
		OutletCode_GDD dbo.DealerCode NULL,
		PAGCode dbo.PAGCode NULL,
		PAGName dbo.PAGName NULL,
		SVODealer BIT NOT NULL,		-- 2017-11-11 Bug 14365
		FleetDealer BIT NOT NULL,	-- 2017-11-11 Bug 14365
		Dealer10DigitCode dbo.Dealer10DigitCode NULL	-- 2020-01-17 Bug 16793
	)
