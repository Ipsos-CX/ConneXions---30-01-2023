CREATE VIEW [Load].[vwEventPartyRoles]

AS

/*
		Purpose:	View of EventPartyRoles
		Version		Date			Developer			Comment
		1.0			$(ReleaseDate)	Simon Peacock		Created
LIVE	1.1			20-06-2022		Chris Ledger		TASK 917 - Add in CQI 1MIS Events
*/

SELECT	
	AuditItemID, 
	ISNULL(SalesDealerID, 0) AS PartyID, 
	(SELECT RoleTypeID FROM [$(SampleDB)].dbo.vwSalesDealerRoleTypes) AS RoleTypeID, 
	MatchedODSEventID AS EventID,
	SalesDealerCode AS DealerCode,
	SalesDealerCodeOriginatorPartyID AS DealerCodeOriginatorPartyID
FROM dbo.VWT VWT
WHERE ODSEventTypeID IN (SELECT EventTypeID FROM [$(SampleDB)].Event.vwEventTypes WHERE EventCategory IN ('Sales', 'LostLeads', 'CQI 1MIS', 'CQI 3MIS', 'CQI 24MIS', 'MCQI 1MIS'))		-- V1.1
AND MatchedODSEventID > 0
	
UNION ALL 

-- PREOWNED DEALERS
SELECT	
	AuditItemID, 
	ISNULL(SalesDealerID, 0) AS PartyID, 
	(SELECT RoleTypeID FROM [$(SampleDB)].dbo.vwPreOwnedDealerRoleTypes) AS RoleTypeID, 
	MatchedODSEventID AS EventID,
	SalesDealerCode AS DealerCode,
	SalesDealerCodeOriginatorPartyID AS DealerCodeOriginatorPartyID
FROM dbo.VWT VWT
WHERE ODSEventTypeID IN (SELECT EventTypeID FROM [$(SampleDB)].Event.vwEventTypes WHERE EventCategory IN ('PreOwned', 'PreOwned LostLeads'))
AND MatchedODSEventID > 0
	
UNION ALL 

-- SERVICE DEALERS
SELECT	
	AuditItemID, 
	ISNULL(ServiceDealerID, 0), 
	(SELECT RoleTypeID FROM [$(SampleDB)].dbo.vwServiceDealerRoleTypes), 
	MatchedODSEventID,
	ServiceDealerCode,
	ServiceDealerCodeOriginatorPartyID
FROM dbo.VWT
WHERE ODSEventTypeID IN (SELECT EventTypeID FROM [$(SampleDB)].Event.vwEventTypes WHERE EventCategory = 'Service')
AND MatchedODSEventID > 0
	
UNION ALL 

-- ROADSIDE NETWORKS
SELECT	
	AuditItemID, 
	ISNULL(RoadsideNetworkPartyID, 0), 
	(SELECT RoleTypeID FROM [$(SampleDB)].dbo.vwRoadsideNetworkRoleTypes), 
	MatchedODSEventID,
	RoadsideNetworkCode,
	RoadsideNetworkOriginatorPartyID
FROM dbo.VWT
WHERE ODSEventTypeID IN (SELECT EventTypeID FROM [$(SampleDB)].Event.vwEventTypes WHERE EventCategory = 'Roadside')
AND MatchedODSEventID > 0

UNION ALL

-- CRC NETWORKS
SELECT	
	AuditItemID, 
	ISNULL(CRCCentrePartyID, 0), 
	(SELECT RoleTypeID FROM [$(SampleDB)].dbo.vwCRCNetworkRoleTypes), 
	MatchedODSEventID,
	CRCCentreCode,
	CRCCentreOriginatorPartyID
FROM dbo.VWT
WHERE ODSEventTypeID IN (SELECT EventTypeID FROM [$(SampleDB)].Event.vwEventTypes WHERE EventCategory IN ('CRC','CRC General Enquiry'))
AND MatchedODSEventID > 0

UNION ALL 

-- BODYSHOP DEALERS
SELECT	
	AuditItemID, 
	ISNULL(BodyshopDealerID, 0) AS PartyID, 
	(SELECT RoleTypeID FROM [$(SampleDB)].dbo.vwBodyShopDealerRoleTypes) AS RoleTypeID, 
	MatchedODSEventID AS EventID,
	BodyshopDealerCode AS DealerCode,
	BodyshopDealerCodeOriginatorPartyID AS DealerCodeOriginatorPartyID
FROM dbo.VWT VWT
WHERE ODSEventTypeID IN (SELECT EventTypeID FROM [$(SampleDB)].Event.vwEventTypes WHERE EventCategory = 'Bodyshop')
AND MatchedODSEventID > 0

UNION ALL

-- IASSISTANCE NETWORKS
SELECT	
	AuditItemID, 
	ISNULL(IAssistanceCentrePartyID, 0), 
	(SELECT RoleTypeID FROM [$(SampleDB)].dbo.vwIAssistanceNetworkRoleTypes), 
	MatchedODSEventID,
	IAssistanceCentreCode,
	IAssistanceCentreOriginatorPartyID
FROM dbo.VWT
WHERE ODSEventTypeID IN (SELECT EventTypeID FROM [$(SampleDB)].Event.vwEventTypes WHERE EventCategory = 'I-Assistance')
AND MatchedODSEventID > 0

UNION ALL 

-- LAND ROVER EXPERIENCE DEALERS
SELECT 
AuditItemID, 
	ISNULL(ExperienceDealerID, 0) AS PartyID, 
	(SELECT RoleTypeID FROM [$(SampleDB)].dbo.vwExperienceDealerRoleTypes) AS RoleTypeID, 
	MatchedODSEventID AS EventID,
	ExperienceDealerCode AS DealerCode,
	ExperienceDealerCodeOriginatorPartyID AS DealerCodeOriginatorPartyID
FROM dbo.VWT VWT
WHERE ODSEventTypeID IN (SELECT EventTypeID FROM [$(SampleDB)].Event.vwEventTypes WHERE EventCategory = 'Land Rover Experience')
AND MatchedODSEventID > 0
GO
