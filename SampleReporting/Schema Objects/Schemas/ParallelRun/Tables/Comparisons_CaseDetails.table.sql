CREATE TABLE [ParallelRun].[Comparisons_CaseDetails](
	CaseID										 INT NOT NULL,
	PartyID										 BIGINT NOT NULL,
	OrganisationPartyID							 BIGINT NOT NULL,
	Mismatch_CreationDate						 INT NOT NULL,
	Mismatch_CaseStatusTypeID					 INT NOT NULL,
	Mismatch_CaseRejection						 INT NOT NULL,
	Mismatch_Questionnaire						 INT NOT NULL,
	Mismatch_QuestionnaireRequirementID			 INT NOT NULL,
	Mismatch_QuestionnaireVersion				 INT NOT NULL,
	Mismatch_SelectionTypeID					 INT NOT NULL,
	Mismatch_Selection							 INT NOT NULL,
	Mismatch_ModelDerivative					 INT NOT NULL,
	Mismatch_Title								 INT NOT NULL,
	Mismatch_FirstName							 INT NOT NULL,
	Mismatch_Initials							 INT NOT NULL,
	Mismatch_MiddleName							 INT NOT NULL,
	Mismatch_LastName							 INT NOT NULL,
	Mismatch_SecondLastName						 INT NOT NULL,
	Mismatch_GenderID							 INT NOT NULL,
	Mismatch_LanguageID							 INT NOT NULL,
	Mismatch_OrganisationName					 INT NOT NULL,
	Mismatch_OrganisationPartyID				 INT NOT NULL,
	Mismatch_PostalAddressContactMechanismID	 INT NOT NULL,
	Mismatch_EmailAddressContactMechanismID		 INT NOT NULL,
	Mismatch_CountryID							 INT NOT NULL,
	Mismatch_Country							 INT NOT NULL,
	Mismatch_CountryISOAlpha3					 INT NOT NULL,
	Mismatch_CountryISOAlpha2					 INT NOT NULL,
	Mismatch_EventTypeID						 INT NOT NULL,
	Mismatch_EventType							 INT NOT NULL,
	Mismatch_EventDate							 INT NOT NULL,
	Mismatch_PartyID							 INT NOT NULL,
	Mismatch_VehicleRoleTypeID					 INT NOT NULL,
	Mismatch_VehicleID							 INT NOT NULL,
	Mismatch_EventID							 INT NOT NULL,
	Mismatch_OwnershipCycle						 INT NOT NULL,
	Mismatch_SelectionRequirementID				 INT NOT NULL,
	Mismatch_ModelRequirementID					 INT NOT NULL,
	Mismatch_RegistrationNumber					 INT NOT NULL,
	Mismatch_RegistrationDate					 INT NOT NULL,
	Mismatch_ModelDescription					 INT NOT NULL,
	Mismatch_VIN								 INT NOT NULL,
	Mismatch_VinPrefix							 INT NOT NULL,
	Mismatch_ChassisNumber						 INT NOT NULL,
	Mismatch_ManufacturerPartyID				 INT NOT NULL,
	Mismatch_DealerPartyID						 INT NOT NULL,
	Mismatch_DealerCode							 INT NOT NULL,
	Mismatch_DealerName							 INT NOT NULL,
	Mismatch_RoadsideNetworkPartyID				 INT NOT NULL,
	Mismatch_RoadsideNetworkCode				 INT NOT NULL,
	Mismatch_RoadsideNetworkName				 INT NOT NULL,
	Mismatch_SaleType							 INT NOT NULL,
	Mismatch_VariantID							 INT NOT NULL,
	Mismatch_ModelVariant						 INT NOT NULL
) 