CREATE TABLE [Selection].[Base] (
		 ID								INT IDENTITY(1,1)
		,EventID						dbo.EventID
		,VehicleID						dbo.VehicleID
		,VehicleRoleTypeID				dbo.RoleTypeID
		,VIN							dbo.VIN
		,EventCategory					VARCHAR(50)					-- BUG 15056 --TASK 877
		,EventCategoryID				dbo.EventCategoryID
		,EventType						NVARCHAR(200)
		,EventTypeID					dbo.EventTypeID
		,EventDate						DATETIME2
		,ManufacturerPartyID			dbo.PartyID
		,ModelID						dbo.ModelID NULL
		,PartyID						dbo.PartyID
		,RegistrationNumber				dbo.RegistrationNumber NULL
		,RegistrationDate				DATETIME2
		,OwnershipCycle					dbo.OwnershipCycle NULL
		,DealerPartyID					dbo.PartyID NULL
		,DealerCode						dbo.DealerCode NULL
		,OrganisationPartyID			dbo.PartyID NULL
		,CountryID						dbo.CountryID NULL
		,PostalContactMechanismID		dbo.ContactMechanismID NULL
		,Street							dbo.AddressText NULL
		,Postcode						dbo.Postcode NULL
		,EmailContactMechanismID		dbo.ContactMechanismID NULL
		,PhoneContactMechanismID		dbo.ContactMechanismID NULL
		,LandlineContactMechanismID		dbo.ContactMechanismID NULL
		,MobileContactMechanismID		dbo.ContactMechanismID NULL
		,DeleteEventType				BIT NOT NULL DEFAULT(0)
		,DeletePersonRequired			BIT NOT NULL DEFAULT(0)
		,DeleteOrganisationRequired		BIT NOT NULL DEFAULT(0)
		,DeleteStreet					BIT NOT NULL DEFAULT(0)
		,DeletePostcode					BIT NOT NULL DEFAULT(0)
		,DeleteEmail					BIT NOT NULL DEFAULT(0)
		,DeleteTelephone				BIT NOT NULL DEFAULT(0)
		,DeleteStreetOrEmail			BIT NOT NULL DEFAULT(0)
		,DeleteTelephoneOrEmail			BIT NOT NULL DEFAULT(0)
		,DeleteMobilePhone				BIT NOT NULL DEFAULT(0)
		,DeleteMobilePhoneOrEmail		BIT NOT NULL DEFAULT(0)
		,DeleteLanguage  				BIT NOT NULL DEFAULT(0)
		,DeleteRecontactPeriod			BIT NOT NULL DEFAULT(0)
		,DeleteSelected					BIT NOT NULL DEFAULT(0)
		,DeletePartyTypes				BIT NOT NULL DEFAULT(0)
		,DeleteEventNonSolicitation		BIT NOT NULL DEFAULT(0)
		,DeleteBarredEmail				BIT NOT NULL DEFAULT(0)
		,DeleteInvalidModel				BIT NOT NULL DEFAULT(0)
		,DeleteInvalidVariant			BIT NOT NULL DEFAULT(0)					-- 15-04-2019 BUG 15321
		,DeletePartyName				BIT NOT NULL DEFAULT(0)
		,DeleteRelativeRecontactPeriod 	BIT NOT NULL DEFAULT(0)
		,CaseIDPrevious					INT NOT NULL DEFAULT(0)
		,DeleteInternalDealer			BIT NOT NULL DEFAULT(0)
		,DeleteInvalidOwnershipCycle	BIT NOT NULL DEFAULT(0)
		,DeleteInvalidRoleType			BIT NOT NULL DEFAULT(0)
		,DeleteInvalidSaleType			BIT NOT NULL DEFAULT(0)
		,DeleteAFRLCode					BIT NOT NULL DEFAULT(0)
		,AFRLCode						VARCHAR(10)	NULL
		,DeleteDealerExclusion			BIT NOT NULL DEFAULT(0)
		,DeleteNotInQuota				BIT NOT NULL DEFAULT(0)
		,DeleteContactPreferences		BIT NOT NULL DEFAULT(0)
		,ContactPreferencesPartySuppress	BIT	NULL
		,ContactPreferencesEmailSuppress	BIT	NULL
		,ContactPreferencesPhoneSuppress	BIT	NULL
		,ContactPreferencesPostalSuppress	BIT	NULL
		,DeleteFilterOnDealerPilotOutputCodes	BIT NOT NULL DEFAULT(0)
		,DeleteCRMSaleType				BIT NOT NULL DEFAULT(0)
		,DeleteCQIMissingExtraVehicleFeed	BIT NOT NULL DEFAULT(0)
		,DeleteMissingLostLeadAgency		BIT NOT NULL DEFAULT(0)
		,DeletePDIFlag					BIT NOT NULL DEFAULT(0)					-- 05-09-2017 - BUG 14122
		,DeleteWarranty					BIT NOT NULL DEFAULT(0)
		,DeleteInvalidDateOfLastContact	BIT NOT NULL DEFAULT(0)					-- 13-09-2018 - BUG 14820 - Lost Leads -  Global loader change
		
		,ContactPreferencesUnsubscribed  BIT NOT NULL DEFAULT(0)				-- 29-12-2017 - BUG 14200
		,SelectionOrganisationID		INT NULL								-- 22-01-2018 - BUG 14399 - new reference column
		,SelectionPostalID				INT NULL								-- 22-01-2018 - BUG 14399 - new reference column
		,SelectionEmailID				INT NULL								-- 22-01-2018 - BUG 14399 - new reference column
		,SelectionPhoneID				INT NULL								-- 22-01-2018 - BUG 14399 - new reference column
		,SelectionLandlineID			INT NULL								-- 22-01-2018 - BUG 14399 - new reference column
		,SelectionMobileID				INT NULL								-- 22-01-2018 - BUG 14399 - new reference column
		,QuestionnaireRequirementid		[dbo].[RequirementID] NULL				-- 08-08-2018 - BUG 14820 - Lost Leads -  Global loader change
		,LLCompleteSuppressionJLR		BIT NOT NULL DEFAULT(0)	
		,LLCompleteSuppressionRetailer  BIT NOT NULL DEFAULT(0)	
		,LLMarketingPermission			BIT NOT NULL DEFAULT(0)					-- 08-08-2018 - BUG 14820 - Lost Leads -  Global loader change
		,LLPermissionToEmailJLR			BIT NOT NULL DEFAULT(0)					-- 08-08-2018 - BUG 14820 - Lost Leads -  Global loader change
		,LLPermissionToEmailRetailer	BIT NOT NULL DEFAULT(0)					-- 08-08-2018 - BUG 14820 - Lost Leads -  Global loader change
		,LLPermissionToPhoneJLR			BIT NOT NULL DEFAULT(0)					-- 08-08-2018 - BUG 14820 - Lost Leads -  Global loader change
		,LLPermissionToPhoneRetailer	BIT NOT NULL DEFAULT(0)					-- 08-08-2018 - BUG 14820 - Lost Leads -  Global loader change
		,LLPermissionToPostJLR			BIT NOT NULL DEFAULT(0)					-- 08-08-2018 - BUG 14820 - Lost Leads -  Global loader change
		,LLPermissionToPostRetailer		BIT NOT NULL DEFAULT(0)					-- 08-08-2018 - BUG 14820 - Lost Leads -  Global loader change
		,LLPermissionToSMSJLR			BIT NOT NULL DEFAULT(0)					-- 08-08-2018 - BUG 14820 - Lost Leads -  Global loader change
		,LLPermissionToSMSRetailer		BIT NOT NULL DEFAULT(0)					-- 08-08-2018 - BUG 14820 - Lost Leads -  Global loader change
		,LLPermissionToSocialMediaJLR	BIT NOT NULL DEFAULT(0)					-- 08-08-2018 - BUG 14820 - Lost Leads -  Global loader change
		,LLPermissionToSocialMediaRetailer	BIT NOT NULL DEFAULT(0)				-- 08-08-2018 - BUG 14820 - Lost Leads -  Global loader change
		,LLDateOfLastContact			BIT NOT NULL DEFAULT(0)					-- 13-09-2018 - BUG 14820 - Lost Leads -  Global loader change
		,LLConvertedDateOfLastContact	DATETIME2 NULL		 					-- 13-09-2018 - BUG 14820 - Lost Leads -  Global loader change
		,DeleteNonLatestEvent			BIT NOT NULL DEFAULT(0)					-- 21-06-2022 - TASK 900 Business & Fleet Vehicle CHANGES


	
		
);







