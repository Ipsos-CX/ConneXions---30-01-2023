CREATE PROCEDURE [Migration].[uspCalculateModelIDs]
AS
	


update Vehicle.Vehicles set ModelID = null


-- DO A VIN MATCH
UPDATE V
SET V.ModelID = MM.ModelID
FROM Vehicle.Vehicles V
INNER JOIN Vehicle.VehicleMatchingStrings MS ON V.VIN LIKE MS.VehicleMatchingString
INNER JOIN Vehicle.ModelMatching MM ON MM.VehicleMatchingStringID = MS.VehicleMatchingStringID
WHERE V.ModelID IS NULL



-- USE THE PRODUCT VALUE FOR UNKNOWN VEHICLES
UPDATE V
SET V.ModelID = (SELECT ModelID FROM Vehicle.Models WHERE ModelDescription = 'Unknown Vehicle' AND ManufacturerPartyID = 2)
FROM Vehicle.Vehicles V
INNER JOIN OrderItems OI ON OI.OrderItemID = V.VehicleID
INNER JOIN Products P ON P.ProductID = OI.ProductID
WHERE V.ModelID IS NULL
AND P.ManufacturerPartyID = 2
AND P.Name = 'Unknown Vehicle'

UPDATE V
SET V.ModelID = (SELECT ModelID FROM Vehicle.Models WHERE ModelDescription = 'Unknown Vehicle' AND ManufacturerPartyID = 3)
FROM Vehicle.Vehicles V
INNER JOIN OrderItems OI ON OI.OrderItemID = V.VehicleID
INNER JOIN Products P ON P.ProductID = OI.ProductID
WHERE V.ModelID IS NULL
AND P.ManufacturerPartyID = 3
AND P.Name = 'Unknown Vehicle'

UPDATE Vehicle.Vehicles
SET ModelID = (SELECT ModelID FROM Vehicle.Models WHERE ModelDescription = 'Unknown Vehicle' AND ManufacturerPartyID = 2)
WHERE ModelID IS NULL
AND VIN LIKE 'SAJ%'

UPDATE Vehicle.Vehicles
SET ModelID = (SELECT ModelID FROM Vehicle.Models WHERE ModelDescription = 'Unknown Vehicle' AND ManufacturerPartyID = 3)
WHERE ModelID IS NULL
AND VIN LIKE 'SAL%'


-- TRY AND GET THE MANUFACTURER FOR ALL THE REST
UPDATE Vehicle.Vehicles
SET ModelID = (SELECT ModelID FROM Vehicle.Models WHERE ModelDescription = 'Unknown Vehicle' AND ManufacturerPartyID = 2)
FROM Vehicle.Vehicles V
INNER JOIN Vehicle.VehiclePartyRoleEvents VPRE ON VPRE.VehicleID = V.VehicleID
INNER JOIN Event.EventPartyRoles EPR ON EPR.EventID = VPRE.EventID
INNER JOIN dbo.DW_JLRCSPDealers D ON D.OutletPartyID = EPR.PartyID AND D.OutletFunctionID = EPR.RoleTypeID
WHERE V.ModelID IS NULL
AND D.ManufacturerPartyID = 2

UPDATE Vehicle.Vehicles
SET ModelID = (SELECT ModelID FROM Vehicle.Models WHERE ModelDescription = 'Unknown Vehicle' AND ManufacturerPartyID = 3)
FROM Vehicle.Vehicles V
INNER JOIN Vehicle.VehiclePartyRoleEvents VPRE ON VPRE.VehicleID = V.VehicleID
INNER JOIN Event.EventPartyRoles EPR ON EPR.EventID = VPRE.EventID
INNER JOIN dbo.DW_JLRCSPDealers D ON D.OutletPartyID = EPR.PartyID AND D.OutletFunctionID = EPR.RoleTypeID
WHERE V.ModelID IS NULL
AND D.ManufacturerPartyID = 3


