CREATE VIEW [Load].[vwVehiclePartyRoleEvents]

AS

/*
		Purpose:	View of VehiclePartyRoleEvents
	
		Version		Date			Developer			Comment
		1.0			$(ReleaseDate)	Simon Peacock		Created
LIVE	1.1			20-06-2022		Chris Ledger		TASK 917 - Add in CQI 1MIS Events
LIVE	1.2			07-07-2022		Ben King     		TASK 879 - Land Rover Experience - SSIS Loader
*/

SELECT	
	AuditItemID, 
	MatchedODSEventID, 
	CASE
		WHEN ODSEventTypeID IN (SELECT EventTypeID FROM [$(SampleDB)].Event.vwEventTypes WHERE EventCategory IN ('Sales', 'PreOwned', 'CQI 1MIS', 'CQI 3MIS', 'CQI 24MIS', 'MCQI 1MIS')) THEN SaleDate			-- V1.1
		WHEN ODSEventTypeID IN (SELECT EventTypeID FROM [$(SampleDB)].Event.vwEventTypes WHERE EventCategory IN ('LostLeads', 'PreOwned LostLeads')) THEN LostLeadDate
		WHEN ODSEventTypeID IN (SELECT EventTypeID FROM [$(SampleDB)].Event.vwEventTypes WHERE EventCategory = 'Service') THEN ServiceDate
		WHEN ODSEventTypeID IN (SELECT EventTypeID FROM [$(SampleDB)].Event.vwEventTypes WHERE EventCategory = 'Roadside') THEN RoadsideDate
		WHEN ODSEventTypeID IN (SELECT EventTypeID FROM [$(SampleDB)].Event.vwEventTypes WHERE EventCategory = 'CRC') THEN CRCDate
		WHEN ODSEventTypeID IN (SELECT EventTypeID FROM [$(SampleDB)].Event.vwEventTypes WHERE EventCategory = 'Bodyshop') THEN BodyShopEventDate
		WHEN ODSEventTypeID IN (SELECT EventTypeID FROM [$(SampleDB)].Event.vwEventTypes WHERE EventCategory = 'I-Assistance') THEN IAssistanceDate
		WHEN ODSEventTypeID IN (SELECT EventTypeID FROM [$(SampleDB)].Event.vwEventTypes WHERE EventCategory = 'CRC General Enquiry') THEN GeneralEnquiryDate
		WHEN ODSEventTypeID IN (SELECT EventTypeID FROM [$(SampleDB)].Event.vwEventTypes WHERE EventCategory = 'Land Rover Experience') THEN LandRoverExperienceDate -- V1.2
		ELSE NULL
	END AS EventDate, 
	CASE
		WHEN ODSEventTypeID IN (SELECT EventTypeID FROM [$(SampleDB)].Event.vwEventTypes WHERE EventCategory IN ('Sales', 'PreOwned', 'CQI 1MIS', 'CQI 3MIS', 'CQI 24MIS', 'MCQI 1MIS')) THEN SaleDateOrig		-- V1.1
		WHEN ODSEventTypeID IN (SELECT EventTypeID FROM [$(SampleDB)].Event.vwEventTypes WHERE EventCategory IN ('LostLeads', 'PreOwned LostLeads')) THEN LostLeadDateOrig
		WHEN ODSEventTypeID IN (SELECT EventTypeID FROM [$(SampleDB)].Event.vwEventTypes WHERE EventCategory = 'Service') THEN ServiceDateOrig
		WHEN ODSEventTypeID IN (SELECT EventTypeID FROM [$(SampleDB)].Event.vwEventTypes WHERE EventCategory = 'Roadside') THEN RoadsideDateOrig
		WHEN ODSEventTypeID IN (SELECT EventTypeID FROM [$(SampleDB)].Event.vwEventTypes WHERE EventCategory = 'CRC') THEN CRCDateOrig
		WHEN ODSEventTypeID IN (SELECT EventTypeID FROM [$(SampleDB)].Event.vwEventTypes WHERE EventCategory = 'Bodyshop') THEN BodyShopEventDateOrig
		WHEN ODSEventTypeID IN (SELECT EventTypeID FROM [$(SampleDB)].Event.vwEventTypes WHERE EventCategory = 'I-Assistance') THEN IAssistanceDateOrig
		WHEN ODSEventTypeID IN (SELECT EventTypeID FROM [$(SampleDB)].Event.vwEventTypes WHERE EventCategory = 'CRC General Enquiry') THEN GeneralEnquiryDateOrig
		WHEN ODSEventTypeID IN (SELECT EventTypeID FROM [$(SampleDB)].Event.vwEventTypes WHERE EventCategory = 'Land Rover Experience') THEN LandRoverExperienceDateOrig -- V1.2
		ELSE NULL
	END AS EventDateOrig,
	ODSEventTypeID AS EventTypeID, 
	RegistrationDate,
	RegistrationDateOrig,
	TypeOfSaleOrig,
	InvoiceDate,
	COALESCE(NULLIF(MatchedODSPersonID, 0), NULLIF(MatchedODSPartyID, 0), 0) AS PartyID,
	MatchedODSVehicleID AS VehicleID,
	(SELECT VehicleRoleTypeID FROM [$(SampleDB)].Vehicle.VehicleRoleTypes WHERE VehicleRoleType = 'Principle Driver') AS VehicleRoleTypeID,
	OwnershipCycle,
	COALESCE(NULLIF(SalesDealerID, 0), NULLIF(ServiceDealerID, 0), NULLIF(RoadsideNetworkPartyID, 0), NULLIF(CRCCentrePartyID, 0), NULLIF(IAssistanceCentrePartyID, 0), NULLIF(ExperienceDealerID, 0), 0) AS DealerID, -- V1.2
	AFRLCode,
	LandRoverExperienceID -- -- V1.2
FROM dbo.VWT
WHERE ISNULL(MatchedODSPersonID, 0) <> 0
AND ISNULL(MatchedODSOrganisationID, 0) = 0
AND MatchedODSVehicleID > 0
AND ISNULL(DriverIndicator, 0) = 0 -- EXCLUDE CUPID DATA
AND ISNULL(OwnerIndicator, 0) = 0 -- EXCLUDE CUPID DATA
AND ISNULL(ManagerIndicator, 0) = 0 -- EXCLUDE CUPID DATA

UNION

SELECT	
	AuditItemID, 
	MatchedODSEventID, 
	CASE
		WHEN ODSEventTypeID IN (SELECT EventTypeID FROM [$(SampleDB)].Event.vwEventTypes WHERE EventCategory IN ('Sales', 'PreOwned', 'CQI 1MIS', 'CQI 3MIS', 'CQI 24MIS', 'MCQI 1MIS')) THEN SaleDate			-- V1.1
		WHEN ODSEventTypeID IN (SELECT EventTypeID FROM [$(SampleDB)].Event.vwEventTypes WHERE EventCategory IN ('LostLeads', 'PreOwned LostLeads')) THEN LostLeadDate
		WHEN ODSEventTypeID IN (SELECT EventTypeID FROM [$(SampleDB)].Event.vwEventTypes WHERE EventCategory = 'Service') THEN ServiceDate
		WHEN ODSEventTypeID IN (SELECT EventTypeID FROM [$(SampleDB)].Event.vwEventTypes WHERE EventCategory = 'Roadside') THEN RoadsideDate
		WHEN ODSEventTypeID IN (SELECT EventTypeID FROM [$(SampleDB)].Event.vwEventTypes WHERE EventCategory = 'CRC') THEN CRCDate
		WHEN ODSEventTypeID IN (SELECT EventTypeID FROM [$(SampleDB)].Event.vwEventTypes WHERE EventCategory = 'Bodyshop') THEN BodyShopEventDate
		WHEN ODSEventTypeID IN (SELECT EventTypeID FROM [$(SampleDB)].Event.vwEventTypes WHERE EventCategory = 'I-Assistance') THEN IAssistanceDate
		WHEN ODSEventTypeID IN (SELECT EventTypeID FROM [$(SampleDB)].Event.vwEventTypes WHERE EventCategory = 'CRC General Enquiry') THEN GeneralEnquiryDate
		WHEN ODSEventTypeID IN (SELECT EventTypeID FROM [$(SampleDB)].Event.vwEventTypes WHERE EventCategory = 'Land Rover Experience') THEN LandRoverExperienceDate -- V1.2
		ELSE NULL
	END AS EventDate, 
	CASE
		WHEN ODSEventTypeID IN (SELECT EventTypeID FROM [$(SampleDB)].Event.vwEventTypes WHERE EventCategory IN ('Sales', 'PreOwned', 'CQI 1MIS', 'CQI 3MIS', 'CQI 24MIS', 'MCQI 1MIS')) THEN SaleDateOrig		-- V1.1
		WHEN ODSEventTypeID IN (SELECT EventTypeID FROM [$(SampleDB)].Event.vwEventTypes WHERE EventCategory IN ('LostLeads', 'PreOwned LostLeads')) THEN LostLeadDateOrig
		WHEN ODSEventTypeID IN (SELECT EventTypeID FROM [$(SampleDB)].Event.vwEventTypes WHERE EventCategory = 'Service') THEN ServiceDateOrig
		WHEN ODSEventTypeID IN (SELECT EventTypeID FROM [$(SampleDB)].Event.vwEventTypes WHERE EventCategory = 'Roadside') THEN RoadsideDateOrig
		WHEN ODSEventTypeID IN (SELECT EventTypeID FROM [$(SampleDB)].Event.vwEventTypes WHERE EventCategory = 'CRC') THEN CRCDateOrig
		WHEN ODSEventTypeID IN (SELECT EventTypeID FROM [$(SampleDB)].Event.vwEventTypes WHERE EventCategory = 'Bodyshop') THEN BodyShopEventDateOrig
		WHEN ODSEventTypeID IN (SELECT EventTypeID FROM [$(SampleDB)].Event.vwEventTypes WHERE EventCategory = 'I-Assistance') THEN IAssistanceDateOrig
		WHEN ODSEventTypeID IN (SELECT EventTypeID FROM [$(SampleDB)].Event.vwEventTypes WHERE EventCategory = 'CRC General Enquiry') THEN GeneralEnquiryDateOrig
		WHEN ODSEventTypeID IN (SELECT EventTypeID FROM [$(SampleDB)].Event.vwEventTypes WHERE EventCategory = 'Land Rover Experience') THEN LandRoverExperienceDateOrig -- V1.2
		ELSE NULL
	END AS EventDateOrig,
	ODSEventTypeID AS EventTypeID, 
	RegistrationDate,
	RegistrationDateOrig,
	TypeOfSaleOrig,
	InvoiceDate,
	COALESCE(NULLIF(MatchedODSPersonID, 0), NULLIF(MatchedODSPartyID, 0), 0) AS PartyID,
	MatchedODSVehicleID AS VehicleID,
	CASE
		WHEN ISNULL(MatchedODSPersonID, 0) <> 0 AND ISNULL(MatchedODSOrganisationID, 0) = 0 THEN (SELECT VehicleRoleTypeID FROM [$(SampleDB)].Vehicle.VehicleRoleTypes WHERE VehicleRoleType = 'Registered Owner')
		WHEN ISNULL(MatchedODSPersonID, 0) <> 0 AND ISNULL(MatchedODSOrganisationID, 0) <> 0 THEN (SELECT VehicleRoleTypeID FROM [$(SampleDB)].Vehicle.VehicleRoleTypes WHERE VehicleRoleType = 'Principle Driver')
		ELSE (SELECT VehicleRoleTypeID FROM [$(SampleDB)].Vehicle.VehicleRoleTypes WHERE VehicleRoleType = 'Other Driver')
	END AS VehicleRoleTypeID,
	OwnershipCycle,
	COALESCE(NULLIF(SalesDealerID, 0), NULLIF(ServiceDealerID, 0), NULLIF(RoadsideNetworkPartyID, 0), NULLIF(CRCCentrePartyID, 0), NULLIF(IAssistanceCentrePartyID, 0), NULLIF(ExperienceDealerID, 0), 0) AS DealerID, -- V1.2
	AFRLCode,
	LandRoverExperienceID -- -- V1.2
FROM dbo.VWT
WHERE COALESCE(NULLIF(MatchedODSPersonID, 0), NULLIF(MatchedODSPartyID, 0), 0) <> 0 -- EXCLUDE EVENTS WITH NO ASSOCIATED PARTIES
AND MatchedODSVehicleID > 0
AND ISNULL(DriverIndicator, 0) = 0 -- EXCLUDE CUPID DATA
AND ISNULL(OwnerIndicator, 0) = 0 -- EXCLUDE CUPID DATA
AND ISNULL(ManagerIndicator, 0) = 0 -- EXCLUDE CUPID DATA
	
UNION

SELECT	
	AuditItemID, 
	MatchedODSEventID, 
	CASE
		WHEN ODSEventTypeID IN (SELECT EventTypeID FROM [$(SampleDB)].Event.vwEventTypes WHERE EventCategory IN ('Sales', 'PreOwned', 'CQI 1MIS', 'CQI 3MIS', 'CQI 24MIS', 'MCQI 1MIS')) THEN SaleDate			-- V1.1
		WHEN ODSEventTypeID IN (SELECT EventTypeID FROM [$(SampleDB)].Event.vwEventTypes WHERE EventCategory IN ('LostLeads', 'PreOwned LostLeads')) THEN LostLeadDate
		WHEN ODSEventTypeID IN (SELECT EventTypeID FROM [$(SampleDB)].Event.vwEventTypes WHERE EventCategory = 'Service') THEN ServiceDate
		WHEN ODSEventTypeID IN (SELECT EventTypeID FROM [$(SampleDB)].Event.vwEventTypes WHERE EventCategory = 'Roadside') THEN RoadsideDate
		WHEN ODSEventTypeID IN (SELECT EventTypeID FROM [$(SampleDB)].Event.vwEventTypes WHERE EventCategory = 'CRC') THEN CRCDate
		WHEN ODSEventTypeID IN (SELECT EventTypeID FROM [$(SampleDB)].Event.vwEventTypes WHERE EventCategory = 'Bodyshop') THEN BodyShopEventDate
		WHEN ODSEventTypeID IN (SELECT EventTypeID FROM [$(SampleDB)].Event.vwEventTypes WHERE EventCategory = 'I-Assistance') THEN IAssistanceDate
		WHEN ODSEventTypeID IN (SELECT EventTypeID FROM [$(SampleDB)].Event.vwEventTypes WHERE EventCategory = 'CRC General Enquiry') THEN GeneralEnquiryDate
		WHEN ODSEventTypeID IN (SELECT EventTypeID FROM [$(SampleDB)].Event.vwEventTypes WHERE EventCategory = 'Land Rover Experience') THEN LandRoverExperienceDate -- V1.2
		ELSE NULL
	END AS EventDate, 
	CASE
		WHEN ODSEventTypeID IN (SELECT EventTypeID FROM [$(SampleDB)].Event.vwEventTypes WHERE EventCategory IN ('Sales', 'PreOwned', 'CQI 1MIS', 'CQI 3MIS', 'CQI 24MIS', 'MCQI 1MIS')) THEN SaleDateOrig		-- V1.1
		WHEN ODSEventTypeID IN (SELECT EventTypeID FROM [$(SampleDB)].Event.vwEventTypes WHERE EventCategory IN ('LostLeads', 'PreOwned LostLeads')) THEN LostLeadDateOrig
		WHEN ODSEventTypeID IN (SELECT EventTypeID FROM [$(SampleDB)].Event.vwEventTypes WHERE EventCategory = 'Service') THEN ServiceDateOrig
		WHEN ODSEventTypeID IN (SELECT EventTypeID FROM [$(SampleDB)].Event.vwEventTypes WHERE EventCategory = 'Roadside') THEN RoadsideDateOrig
		WHEN ODSEventTypeID IN (SELECT EventTypeID FROM [$(SampleDB)].Event.vwEventTypes WHERE EventCategory = 'CRC') THEN CRCDateOrig
		WHEN ODSEventTypeID IN (SELECT EventTypeID FROM [$(SampleDB)].Event.vwEventTypes WHERE EventCategory = 'Bodyshop') THEN BodyShopEventDateOrig
		WHEN ODSEventTypeID IN (SELECT EventTypeID FROM [$(SampleDB)].Event.vwEventTypes WHERE EventCategory = 'I-Assistance') THEN IAssistanceDateOrig
		WHEN ODSEventTypeID IN (SELECT EventTypeID FROM [$(SampleDB)].Event.vwEventTypes WHERE EventCategory = 'CRC General Enquiry') THEN GeneralEnquiryDateOrig
		WHEN ODSEventTypeID IN (SELECT EventTypeID FROM [$(SampleDB)].Event.vwEventTypes WHERE EventCategory = 'Land Rover Experience') THEN LandRoverExperienceDateOrig -- V1.2
		ELSE NULL
	END AS EventDateOrig,
	ODSEventTypeID AS EventTypeID, 
	RegistrationDate,
	RegistrationDateOrig,
	TypeOfSaleOrig,
	InvoiceDate,
	ISNULL(MatchedODSOrganisationID, 0) AS PartyID,
	MatchedODSVehicleID AS VehicleID,
	(SELECT VehicleRoleTypeID FROM [$(SampleDB)].Vehicle.VehicleRoleTypes WHERE VehicleRoleType = 'Registered Owner') AS VehicleRoleTypeID,
	OwnershipCycle,
	COALESCE(NULLIF(SalesDealerID, 0), NULLIF(ServiceDealerID, 0), NULLIF(RoadsideNetworkPartyID, 0), NULLIF(CRCCentrePartyID, 0), NULLIF(IAssistanceCentrePartyID, 0), NULLIF(ExperienceDealerID, 0), 0) AS DealerID, -- V1.2
	AFRLCode,
	LandRoverExperienceID -- V1.2
FROM VWT
WHERE ISNULL(MatchedODSOrganisationID, 0) <> 0 -- COMPANY RECORDS.  
AND MatchedODSVehicleID > 0
AND ISNULL(DriverIndicator, 0) = 0 -- EXCLUDE CUPID DATA
AND ISNULL(OwnerIndicator, 0) = 0 -- EXCLUDE CUPID DATA
AND ISNULL(ManagerIndicator, 0) = 0 -- EXCLUDE CUPID DATA

UNION

SELECT  
	AuditItemID, 
	MatchedODSEventID, 
	CASE
		WHEN ODSEventTypeID IN (SELECT EventTypeID FROM [$(SampleDB)].Event.vwEventTypes WHERE EventCategory IN ('Sales', 'PreOwned', 'CQI 1MIS', 'CQI 3MIS', 'CQI 24MIS', 'MCQI 1MIS')) THEN SaleDate			-- V1.1
		WHEN ODSEventTypeID IN (SELECT EventTypeID FROM [$(SampleDB)].Event.vwEventTypes WHERE EventCategory = 'Service') THEN ServiceDate
		ELSE NULL
	END AS EventDate, 
	CASE
		WHEN ODSEventTypeID IN (SELECT EventTypeID FROM [$(SampleDB)].Event.vwEventTypes WHERE EventCategory IN ('Sales', 'PreOwned', 'CQI 1MIS', 'CQI 3MIS', 'CQI 24MIS', 'MCQI 1MIS')) THEN SaleDateOrig		-- V1.1
		WHEN ODSEventTypeID IN (SELECT EventTypeID FROM [$(SampleDB)].Event.vwEventTypes WHERE EventCategory = 'Service') THEN ServiceDateOrig
		ELSE NULL
	END AS EventDateOrig,
	ODSEventTypeID AS EventTypeID, 
	RegistrationDate,
	RegistrationDateOrig,
	TypeOfSaleOrig,
	InvoiceDate,
	COALESCE(NULLIF(MatchedODSPersonID, 0), NULLIF(MatchedODSOrganisationID, 0), NULLIF(MatchedODSPartyID, 0), 0) AS PartyID,	
	MatchedODSVehicleID AS VehicleID,
	(SELECT VehicleRoleTypeID FROM [$(SampleDB)].Vehicle.VehicleRoleTypes WHERE VehicleRoleType = 'Principle Driver') AS VehicleRoleType,
	OwnershipCycle,
	COALESCE(NULLIF(SalesDealerID, 0), NULLIF(ServiceDealerID, 0), 0) AS DealerID,
	AFRLCode,
	LandRoverExperienceID -- V1.2
FROM VWT
WHERE DriverIndicator = 1
AND MatchedODSVehicleID > 0

UNION

SELECT  
	AuditItemID, 
	MatchedODSEventID, 
	CASE
		WHEN ODSEventTypeID IN (SELECT EventTypeID FROM [$(SampleDB)].Event.vwEventTypes WHERE EventCategory IN ('Sales', 'PreOwned', 'CQI 1MIS', 'CQI 3MIS', 'CQI 24MIS', 'MCQI 1MIS')) THEN SaleDate			-- V1.1
		WHEN ODSEventTypeID IN (SELECT EventTypeID FROM [$(SampleDB)].Event.vwEventTypes WHERE EventCategory = 'Service') THEN ServiceDate
		ELSE NULL
	END AS EventDate, 
	CASE
		WHEN ODSEventTypeID IN (SELECT EventTypeID FROM [$(SampleDB)].Event.vwEventTypes WHERE EventCategory IN ('Sales', 'PreOwned', 'CQI 1MIS', 'CQI 3MIS', 'CQI 24MIS', 'MCQI 1MIS')) THEN SaleDateOrig		-- V1.1
		WHEN ODSEventTypeID IN (SELECT EventTypeID FROM [$(SampleDB)].Event.vwEventTypes WHERE EventCategory = 'Service') THEN ServiceDateOrig
		ELSE NULL
	END AS EventDateOrig,
	ODSEventTypeID AS EventTypeID, 
	RegistrationDate,
	RegistrationDateOrig,
	TypeOfSaleOrig,
	InvoiceDate,
	COALESCE(NULLIF(MatchedODSOrganisationID, 0), NULLIF(MatchedODSPersonID, 0), NULLIF(MatchedODSPartyID, 0), 0) AS PartyID,	
	MatchedODSVehicleID as VehicleID,
	(SELECT VehicleRoleTypeID FROM [$(SampleDB)].Vehicle.VehicleRoleTypes WHERE VehicleRoleType = 'Registered Owner') AS VehicleRoleTypeID,
	OwnershipCycle,
	COALESCE(NULLIF(SalesDealerID, 0), NULLIF(ServiceDealerID, 0), 0) AS DealerID,
	AFRLCode,
	LandRoverExperienceID -- V1.2
FROM VWT
WHERE OwnerIndicator = 1
AND MatchedODSVehicleID > 0

UNION

SELECT  
	AuditItemID, 
	MatchedODSEventID, 
	CASE
		WHEN ODSEventTypeID IN (SELECT EventTypeID FROM [$(SampleDB)].Event.vwEventTypes WHERE EventCategory IN ('Sales', 'PreOwned', 'CQI 1MIS', 'CQI 3MIS', 'CQI 24MIS', 'MCQI 1MIS')) THEN SaleDate			-- V1.1
		WHEN ODSEventTypeID IN (SELECT EventTypeID FROM [$(SampleDB)].Event.vwEventTypes WHERE EventCategory = 'Service') THEN ServiceDate
		ELSE NULL
	END AS EventDate, 
	CASE
		WHEN ODSEventTypeID IN (SELECT EventTypeID FROM [$(SampleDB)].Event.vwEventTypes WHERE EventCategory IN ('Sales', 'PreOwned', 'CQI 1MIS', 'CQI 3MIS', 'CQI 24MIS', 'MCQI 1MIS')) THEN SaleDateOrig		-- V1.1
		WHEN ODSEventTypeID IN (SELECT EventTypeID FROM [$(SampleDB)].Event.vwEventTypes WHERE EventCategory = 'Service') THEN ServiceDateOrig
		ELSE NULL
	END AS EventDateOrig,
	ODSEventTypeID AS EventTypeID, 
	RegistrationDate,
	RegistrationDateOrig,
	TypeOfSaleOrig,
	InvoiceDate,
	COALESCE(NULLIF(MatchedODSPersonID, 0), NULLIF(MatchedODSOrganisationID, 0), NULLIF(MatchedODSPartyID, 0), 0) AS PartyID,	
	MatchedODSVehicleID as VehicleID,
	(SELECT VehicleRoleTypeID FROM [$(SampleDB)].Vehicle.VehicleRoleTypes WHERE VehicleRoleType = 'Fleet Manager') AS VehicleRoleTypeID,
	OwnershipCycle,
	COALESCE(NULLIF(SalesDealerID, 0), NULLIF(ServiceDealerID, 0), 0) AS DealerID,
	AFRLCode,
	LandRoverExperienceID -- V1.2
FROM VWT
WHERE ManagerIndicator = 1
AND MatchedODSVehicleID > 0;

