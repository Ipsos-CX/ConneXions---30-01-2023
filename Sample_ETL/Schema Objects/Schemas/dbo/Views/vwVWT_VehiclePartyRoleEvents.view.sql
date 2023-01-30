CREATE VIEW dbo.vwVWT_VehiclePartyRoleEvents

AS

	SELECT DISTINCT
		MatchedODSEventID,
		CASE
			WHEN ODSEventTypeID IN (SELECT EventTypeID FROM [$(SampleDB)].Event.vwEventTypes WHERE EventCategory = 'Service') THEN ServiceDate
			WHEN ODSEventTypeID IN (SELECT EventTypeID FROM [$(SampleDB)].Event.vwEventTypes WHERE EventCategory = 'Sales') THEN COALESCE(SaleDate, RegistrationDate)
			ELSE NULL
		END AS EventDate, 
		ODSEventTypeID AS EventTypeID, 
		MatchedODSVehicleID AS VehicleID,
		COALESCE(NULLIF(SalesDealerID, 0), NULLIF(ServiceDealerID, 0)) AS DealerID
	FROM dbo.VWT