CREATE VIEW [Meta].[vwVehicleEvents]
AS
WITH Registrations AS 
(
	SELECT VRE.VehicleID, 
		VRE.EventID, 
		R.RegistrationID, 
		R.RegistrationNumber, 
		R.RegistrationDate
	FROM (	SELECT EventID, 
				VehicleID, 
				MAX(RegistrationID) AS RegistrationID
			FROM Vehicle.VehicleRegistrationEvents
			GROUP BY EventID, 
				VehicleID) VRE
		INNER JOIN Vehicle.Registrations R ON R.RegistrationID = VRE.RegistrationID 
											AND COALESCE(R.ThroughDate, '31 December 2999') > CURRENT_TIMESTAMP
)
SELECT DISTINCT 
	E.EventID, 
	V.VehicleID, 
	V.ModelID,
	COALESCE (VPRE.PrincipleDriver, VPRE.RegisteredOwner, VPRE.Purchaser, VPRE.OtherDriver, VPRE.FleetManager) AS PartyID,
	CASE
		WHEN VPRE.PrincipleDriver IS NOT NULL THEN (SELECT VehicleRoleTypeID FROM Vehicle.VehicleRoleTypes WHERE VehicleRoleType = 'Principle Driver')
		WHEN VPRE.RegisteredOwner IS NOT NULL THEN (SELECT VehicleRoleTypeID FROM Vehicle.VehicleRoleTypes WHERE VehicleRoleType = 'Registered Owner')
		WHEN VPRE.Purchaser IS NOT NULL THEN (SELECT VehicleRoleTypeID FROM Vehicle.VehicleRoleTypes WHERE VehicleRoleType = 'Purchaser')
		WHEN VPRE.OtherDriver IS NOT NULL THEN (SELECT VehicleRoleTypeID FROM Vehicle.VehicleRoleTypes WHERE VehicleRoleType = 'Other Driver')
		WHEN VPRE.FleetManager IS NOT NULL THEN (SELECT VehicleRoleTypeID FROM Vehicle.VehicleRoleTypes WHERE VehicleRoleType = 'Fleet Manager')
	END AS VehicleRoleTypeID,
	CASE 
		WHEN LEN(V.VIN) = 20 AND SUBSTRING(V.VIN,18,1) = '_' THEN SUBSTRING(V.VIN,1,17) 
		ELSE V.VIN 
	END AS VIN,			-- BUG 14469: Remove postfix for duplicate VINs 
	R.RegistrationNumber, 
	R.RegistrationDate, 
	CASE
		WHEN ET.EventCategory = 'Sales' THEN COALESCE (E.EventDate, R.RegistrationDate) 
		ELSE E.EventDate
	END AS EventDate, 
	ET.EventType, 
	ET.EventTypeID,
	ET.EventCategory,
	ET.EventCategoryID,
	OC.OwnershipCycle,
	CASE ET.EventType WHEN 'Roadside'				THEN RN.PartyIDFrom 
					  WHEN 'CRC'					THEN CRC.PartyIDFrom					-- BUG 6061 - 06-10-2014
					  WHEN 'CRC General Enquiry'	THEN CRC.PartyIDFrom					-- TASK 389 - 07-05-2021
					  WHEN 'I-Assistance'			THEN IA.PartyIDFrom						-- BUG 15056 - 15-10-2018
													ELSE D.OutletPartyID END DealerPartyID,  
	CASE ET.EventType WHEN 'Roadside'				THEN RN.RoadsideNetworkCode 
					  WHEN 'CRC'					THEN CRC.CRCCentreCode					-- BUG 6061 - 06-10-2014
					  WHEN 'CRC General Enquiry'	THEN CRC.CRCCentreCode					-- TASK 389 - 07-05-2021
					  WHEN 'I-Assistance'			THEN IA.IAssistanceCentreCode			-- BUG 15056 - 15-10-2018
													ELSE D.OutletCode END DealerCode, 
	CASE ET.EventType WHEN 'Roadside'				THEN RN.PartyIDTo 
					  WHEN 'CRC'					THEN CRC.PartyIDTo						-- BUG 6061 - 06-10-2014
					  WHEN 'CRC General Enquiry'	THEN CRC.PartyIDTo						-- TASK 389 - 07-05-2021
					  WHEN 'I-Assistance'			THEN IA.PartyIDTo						-- BUG 15056 - 15-10-2018
													ELSE D.ManufacturerPartyID END ManufacturerPartyID
FROM Meta.VehiclePartyRoleEvents VPRE
	INNER JOIN Vehicle.Vehicles V ON V.VehicleID = VPRE.VehicleID
	INNER JOIN Vehicle.Models M ON M.ModelID = V.ModelID 
	--								AND M.ModelDescription <> 'Unknown Vehicle'  <-- Bug 8766 : CGR - Removed as shouldn't be pre-filtering out 'unknown vehicles'.  Filtering is done in selection so that the logging flag is set correctly.
	INNER JOIN Event.Events E ON VPRE.EventID = E.EventID
	INNER JOIN Event.vwEventTypes ET ON ET.EventTypeID = E.EventTypeID
	LEFT JOIN Event.OwnershipCycle OC ON E.EventID = OC.EventID
	LEFT JOIN Registrations R ON V.VehicleID = R.VehicleID 
								AND E.EventID = R.EventID
	INNER JOIN Event.EventPartyRoles EPR ON E.EventID = EPR.EventID
	LEFT JOIN dbo.DW_JLRCSPDealers D ON D.OutletPartyID = EPR.PartyID 
										AND D.OutletFunctionID = EPR.RoleTypeID 
										AND D.ManufacturerPartyID = M.ManufacturerPartyID
	LEFT JOIN Party.RoadsideNetworks RN ON RN.PartyIDFrom = EPR.PartyID						-- Added in to ensure Roadside works but needs to be replaced and coded in a better/more explicit way for clarity 
											AND RN.RoleTypeIDFrom = EPR.RoleTypeID  
											AND RN.PartyIDTo  = M.ManufacturerPartyID 
	LEFT JOIN Party.CRCNetworks CRC ON CRC.PartyIDFrom = EPR.PartyID						-- BUG 6061 - 06-10-2014 - Added in to ensure CRC works but needs to be replaced and coded in a better/more explicit way for clarity 
										AND CRC.RoleTypeIDFrom = EPR.RoleTypeID  
										AND CRC.PartyIDTo = M.ManufacturerPartyID 
	LEFT JOIN Party.IAssistanceNetworks IA ON IA.PartyIDFrom = EPR.PartyID					-- BUG 15056 - 15-10-2018 - Added in to ensure I-Assistance works but needs to be replaced and coded in a better/more explicit way for clarity 
											AND IA.RoleTypeIDFrom = EPR.RoleTypeID  
											AND IA.PartyIDTo = M.ManufacturerPartyID 			
WHERE COALESCE (VPRE.PrincipleDriver, VPRE.RegisteredOwner, VPRE.Purchaser, VPRE.OtherDriver, VPRE.FleetManager, 0) > 0		-- WHERE WE HAVE PARTY INFORMATION
	AND (   (ET.EventType = 'Roadside' AND RN.PartyIDFrom IS NOT NULL)														-- Added in to ensure Roadside (and CRC now!) works but needs to be replaced and coded in a better/more explicit way
		 OR (ET.EventType IN ('CRC','CRC General Enquiry') AND CRC.PartyIDFrom IS NOT NULL)									-- BUG 6061 - 06-10-2014	-- TASK 389 07-05-2021
		 OR (ET.EventType = 'I-Assistance' AND IA.PartyIDFrom IS NOT NULL)													-- BUG 15056 - 15-10-2018
		 OR (ET.EventType NOT IN ('CRC','Roadside','I-Assistance','CRC General Enquiry') AND D.OutletPartyID IS NOT NULL)	-- TASK 389 07-05-2021
		);
